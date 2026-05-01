import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/core/utils/bounded_lru_cache.dart';
import 'package:fluxer_app/features/chat/domain/gif_selection.dart';
import 'package:fluxer_dart/export.dart' as sdk;
import 'package:riverpod/misc.dart';

typedef GifSearchRequest = ({String query, sdk.Locale locale});

const _kFeaturedCacheCapacity = 8;
const _kTrendingCacheCapacity = 8;
const _kSearchCacheCapacity = 40;
const _kSuggestionCacheCapacity = 40;

final Provider<GifRepository> gifRepositoryProvider = Provider<GifRepository>((
  ref,
) {
  final client = ref.watch(fluxerClientProvider);
  return GifRepository(client);
});

final FutureProvider<GifProviderKind> activeGifProviderProvider =
    FutureProvider<GifProviderKind>((ref) {
      return ref.watch(gifRepositoryProvider).getActiveProvider();
    });

final FutureProviderFamily<GifPickerFeatured, sdk.Locale> gifFeaturedProvider =
    FutureProvider.autoDispose.family<GifPickerFeatured, sdk.Locale>((
      ref,
      locale,
    ) {
      return ref.watch(gifRepositoryProvider).getFeatured(locale: locale);
    });

final FutureProviderFamily<List<GifPickerGif>, sdk.Locale> gifTrendingProvider =
    FutureProvider.autoDispose.family<List<GifPickerGif>, sdk.Locale>((
      ref,
      locale,
    ) {
      return ref.watch(gifRepositoryProvider).getTrending(locale: locale);
    });

final FutureProviderFamily<List<GifPickerGif>, GifSearchRequest>
gifSearchProvider = FutureProvider.autoDispose
    .family<List<GifPickerGif>, GifSearchRequest>((ref, request) {
      return ref
          .watch(gifRepositoryProvider)
          .search(query: request.query, locale: request.locale);
    });

final FutureProviderFamily<List<String>, GifSearchRequest>
gifSuggestionsProvider = FutureProvider.autoDispose
    .family<List<String>, GifSearchRequest>((ref, request) {
      return ref
          .watch(gifRepositoryProvider)
          .suggest(query: request.query, locale: request.locale);
    });

class GifRepository {
  GifRepository(this._client);

  final sdk.FluxerClient _client;
  final BoundedLruCache<String, GifPickerFeatured> _featuredCache =
      BoundedLruCache<String, GifPickerFeatured>(
        capacity: _kFeaturedCacheCapacity,
      );
  final BoundedLruCache<String, List<GifPickerGif>> _searchCache =
      BoundedLruCache<String, List<GifPickerGif>>(
        capacity: _kSearchCacheCapacity,
      );
  final BoundedLruCache<String, List<GifPickerGif>> _trendingCache =
      BoundedLruCache<String, List<GifPickerGif>>(
        capacity: _kTrendingCacheCapacity,
      );
  final BoundedLruCache<String, List<String>> _suggestionCache =
      BoundedLruCache<String, List<String>>(
        capacity: _kSuggestionCacheCapacity,
      );
  GifProviderKind? _activeProvider;

  Future<GifProviderKind> getActiveProvider() async {
    final cached = _activeProvider;
    if (cached != null) {
      return cached;
    }

    try {
      final wellKnown = await _client.instance.getWellKnownFluxer();
      final provider = _providerFromWellKnown(wellKnown.gif.provider);
      _activeProvider = provider;
      return provider;
    } on Object catch (error) {
      talker.warning('[GifRepository] Failed to load GIF provider: $error');
      _activeProvider = GifProviderKind.klipy;
      return _activeProvider!;
    }
  }

  Future<GifPickerFeatured> getFeatured({required sdk.Locale locale}) async {
    final provider = await getActiveProvider();
    final key = _cacheKey(provider, locale);
    final cached = _featuredCache.get(key);
    if (cached != null) {
      return cached;
    }

    final featured = switch (provider) {
      GifProviderKind.klipy => await _getKlipyFeatured(locale),
      GifProviderKind.tenor => await _getTenorFeatured(locale),
    };
    _featuredCache.set(key, featured);
    return featured;
  }

  Future<List<GifPickerGif>> getTrending({required sdk.Locale locale}) async {
    final provider = await getActiveProvider();
    final key = _cacheKey(provider, locale);
    final cached = _trendingCache.get(key);
    if (cached != null) {
      return cached;
    }

    final gifs = switch (provider) {
      GifProviderKind.klipy => _mapKlipyGifs(
        await _client.klipy.getKlipyTrendingGifs(locale: locale),
      ),
      GifProviderKind.tenor => _mapTenorGifs(
        await _client.tenor.getTenorTrendingGifs(locale: locale),
      ),
    };
    _trendingCache.set(key, gifs);
    return gifs;
  }

  Future<List<GifPickerGif>> search({
    required String query,
    required sdk.Locale locale,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <GifPickerGif>[];
    }

    final provider = await getActiveProvider();
    final key = _cacheKey(provider, locale, trimmed);
    final cached = _searchCache.get(key);
    if (cached != null) {
      return cached;
    }

    final gifs = switch (provider) {
      GifProviderKind.klipy => _mapKlipyGifs(
        await _client.klipy.searchKlipyGifs(q: trimmed, locale: locale),
      ),
      GifProviderKind.tenor => _mapTenorGifs(
        await _client.tenor.searchTenorGifs(q: trimmed, locale: locale),
      ),
    };
    _searchCache.set(key, gifs);
    return gifs;
  }

  Future<List<String>> suggest({
    required String query,
    required sdk.Locale locale,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }

    final provider = await getActiveProvider();
    final key = _cacheKey(provider, locale, trimmed);
    final cached = _suggestionCache.get(key);
    if (cached != null) {
      return cached;
    }

    final suggestions = switch (provider) {
      GifProviderKind.klipy => await _client.klipy.getKlipySearchSuggestions(
        q: trimmed,
        locale: locale,
      ),
      GifProviderKind.tenor => await _client.tenor.getTenorSearchSuggestions(
        q: trimmed,
        locale: locale,
      ),
    };
    _suggestionCache.set(key, suggestions);
    return suggestions;
  }

  Future<void> registerShare({
    required GifProviderKind provider,
    required String id,
    required String query,
    required sdk.Locale locale,
  }) async {
    try {
      final normalizedQuery = query.trim();
      switch (provider) {
        case GifProviderKind.klipy:
          await _client.klipy.registerKlipyGifShare(
            body: sdk.KlipyRegisterShareRequest(
              id: id,
              q: normalizedQuery.isEmpty ? null : normalizedQuery,
              locale: locale,
            ),
          );
        case GifProviderKind.tenor:
          await _client.tenor.registerTenorGifShare(
            body: sdk.TenorRegisterShareRequest(
              id: id,
              q: normalizedQuery.isEmpty ? null : normalizedQuery,
              locale: locale,
            ),
          );
      }
    } on Object catch (error) {
      talker.warning('[GifRepository] Failed to register share: $error');
    }
  }

  Future<GifPickerFeatured> _getKlipyFeatured(sdk.Locale locale) async {
    final featured = await _client.klipy.getKlipyFeatured(locale: locale);
    return GifPickerFeatured(
      gifs: _mapKlipyGifs(featured.gifs),
      categories: featured.categories
          .map(
            (category) => GifPickerCategory(
              name: category.name,
              src: category.src,
              proxySrc: category.proxySrc,
            ),
          )
          .toList(),
    );
  }

  Future<GifPickerFeatured> _getTenorFeatured(sdk.Locale locale) async {
    final featured = await _client.tenor.getTenorFeatured(locale: locale);
    return GifPickerFeatured(
      gifs: _mapTenorGifs(featured.gifs),
      categories: featured.categories
          .map(
            (category) => GifPickerCategory(
              name: category.name,
              src: category.src,
              proxySrc: category.proxySrc,
            ),
          )
          .toList(),
    );
  }

  List<GifPickerGif> _mapKlipyGifs(List<sdk.KlipyGifResponse> gifs) => gifs
      .map(
        (gif) => GifPickerGif(
          provider: GifProviderKind.klipy,
          id: gif.id,
          title: gif.title,
          url: gif.url,
          src: gif.src,
          proxySrc: gif.proxySrc,
          width: gif.width,
          height: gif.height,
        ),
      )
      .toList();

  List<GifPickerGif> _mapTenorGifs(List<sdk.TenorGifResponse> gifs) => gifs
      .map(
        (gif) => GifPickerGif(
          provider: GifProviderKind.tenor,
          id: gif.id,
          title: gif.title,
          url: gif.url,
          src: gif.src,
          proxySrc: gif.proxySrc,
          width: gif.width,
          height: gif.height,
        ),
      )
      .toList();

  GifProviderKind _providerFromWellKnown(
    sdk.WellKnownFluxerResponseGifProviderProvider provider,
  ) => switch (provider) {
    sdk.WellKnownFluxerResponseGifProviderProvider.tenor =>
      GifProviderKind.tenor,
    sdk.WellKnownFluxerResponseGifProviderProvider.klipy =>
      GifProviderKind.klipy,
    sdk.WellKnownFluxerResponseGifProviderProvider.$unknown =>
      GifProviderKind.klipy,
  };

  String _cacheKey(
    GifProviderKind provider,
    sdk.Locale locale, [
    String value = '',
  ]) => '${provider.name}::${locale.json ?? locale.name}::$value';
}

sdk.Locale gifLocaleFromFlutterLocale(ui.Locale locale) {
  final languageCode = locale.languageCode.toLowerCase();
  final countryCode = locale.countryCode?.toUpperCase();
  final exactTag = countryCode == null || countryCode.isEmpty
      ? languageCode
      : '$languageCode-$countryCode';
  final exact = _localeByWireValue[exactTag];
  if (exact != null) {
    return exact;
  }

  final languageOnly = _localeByWireValue[languageCode];
  if (languageOnly != null) {
    return languageOnly;
  }

  return switch (languageCode) {
    'en' => sdk.Locale.enUs,
    'es' => countryCode == 'ES' ? sdk.Locale.esEs : sdk.Locale.es419,
    'pt' => sdk.Locale.ptBr,
    'sv' => sdk.Locale.svSe,
    'zh' => countryCode == 'CN' ? sdk.Locale.zhCn : sdk.Locale.zhTw,
    _ => sdk.Locale.enUs,
  };
}

final Map<String, sdk.Locale> _localeByWireValue = <String, sdk.Locale>{
  for (final locale in sdk.Locale.$valuesDefined)
    if (locale.json != null) locale.json!: locale,
};
