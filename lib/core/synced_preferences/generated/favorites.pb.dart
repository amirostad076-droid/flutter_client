// This is a generated file - do not edit.
//
// Generated from favorites.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SyncedPreferences extends $pb.GeneratedMessage {
  factory SyncedPreferences({
    FavoritesState? favorites,
  }) {
    final result = create();
    if (favorites != null) result.favorites = favorites;
    return result;
  }

  SyncedPreferences._();

  factory SyncedPreferences.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SyncedPreferences.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncedPreferences',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fluxer.user.preferences.v1'),
      createEmptyInstance: create)
    ..aOM<FavoritesState>(40, _omitFieldNames ? '' : 'favorites',
        subBuilder: FavoritesState.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncedPreferences clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncedPreferences copyWith(void Function(SyncedPreferences) updates) =>
      super.copyWith((message) => updates(message as SyncedPreferences))
          as SyncedPreferences;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncedPreferences create() => SyncedPreferences._();
  @$core.override
  SyncedPreferences createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SyncedPreferences getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncedPreferences>(create);
  static SyncedPreferences? _defaultInstance;

  @$pb.TagNumber(40)
  FavoritesState get favorites => $_getN(0);
  @$pb.TagNumber(40)
  set favorites(FavoritesState value) => $_setField(40, value);
  @$pb.TagNumber(40)
  $core.bool hasFavorites() => $_has(0);
  @$pb.TagNumber(40)
  void clearFavorites() => $_clearField(40);
  @$pb.TagNumber(40)
  FavoritesState ensureFavorites() => $_ensure(0);
}

class FavoritesState extends $pb.GeneratedMessage {
  factory FavoritesState({
    $core.Iterable<FavoriteChannel>? channels,
    $core.Iterable<FavoriteCategory>? categories,
    $core.Iterable<$core.String>? collapsedCategoryIds,
    $core.bool? hideMutedChannels,
    $core.bool? muted,
  }) {
    final result = create();
    if (channels != null) result.channels.addAll(channels);
    if (categories != null) result.categories.addAll(categories);
    if (collapsedCategoryIds != null)
      result.collapsedCategoryIds.addAll(collapsedCategoryIds);
    if (hideMutedChannels != null) result.hideMutedChannels = hideMutedChannels;
    if (muted != null) result.muted = muted;
    return result;
  }

  FavoritesState._();

  factory FavoritesState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FavoritesState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FavoritesState',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fluxer.user.preferences.v1'),
      createEmptyInstance: create)
    ..pPM<FavoriteChannel>(1, _omitFieldNames ? '' : 'channels',
        subBuilder: FavoriteChannel.create)
    ..pPM<FavoriteCategory>(2, _omitFieldNames ? '' : 'categories',
        subBuilder: FavoriteCategory.create)
    ..pPS(3, _omitFieldNames ? '' : 'collapsedCategoryIds')
    ..aOB(4, _omitFieldNames ? '' : 'hideMutedChannels')
    ..aOB(5, _omitFieldNames ? '' : 'muted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FavoritesState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FavoritesState copyWith(void Function(FavoritesState) updates) =>
      super.copyWith((message) => updates(message as FavoritesState))
          as FavoritesState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FavoritesState create() => FavoritesState._();
  @$core.override
  FavoritesState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FavoritesState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FavoritesState>(create);
  static FavoritesState? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<FavoriteChannel> get channels => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<FavoriteCategory> get categories => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get collapsedCategoryIds => $_getList(2);

  @$pb.TagNumber(4)
  $core.bool get hideMutedChannels => $_getBF(3);
  @$pb.TagNumber(4)
  set hideMutedChannels($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHideMutedChannels() => $_has(3);
  @$pb.TagNumber(4)
  void clearHideMutedChannels() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get muted => $_getBF(4);
  @$pb.TagNumber(5)
  set muted($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMuted() => $_has(4);
  @$pb.TagNumber(5)
  void clearMuted() => $_clearField(5);
}

class FavoriteChannel extends $pb.GeneratedMessage {
  factory FavoriteChannel({
    $core.String? channelId,
    $core.String? guildId,
    $core.String? parentId,
    $core.int? position,
    $core.String? nickname,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (guildId != null) result.guildId = guildId;
    if (parentId != null) result.parentId = parentId;
    if (position != null) result.position = position;
    if (nickname != null) result.nickname = nickname;
    return result;
  }

  FavoriteChannel._();

  factory FavoriteChannel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FavoriteChannel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FavoriteChannel',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fluxer.user.preferences.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'guildId')
    ..aOS(3, _omitFieldNames ? '' : 'parentId')
    ..aI(4, _omitFieldNames ? '' : 'position')
    ..aOS(5, _omitFieldNames ? '' : 'nickname')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FavoriteChannel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FavoriteChannel copyWith(void Function(FavoriteChannel) updates) =>
      super.copyWith((message) => updates(message as FavoriteChannel))
          as FavoriteChannel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FavoriteChannel create() => FavoriteChannel._();
  @$core.override
  FavoriteChannel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FavoriteChannel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FavoriteChannel>(create);
  static FavoriteChannel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get guildId => $_getSZ(1);
  @$pb.TagNumber(2)
  set guildId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGuildId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGuildId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get parentId => $_getSZ(2);
  @$pb.TagNumber(3)
  set parentId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasParentId() => $_has(2);
  @$pb.TagNumber(3)
  void clearParentId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get position => $_getIZ(3);
  @$pb.TagNumber(4)
  set position($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearPosition() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get nickname => $_getSZ(4);
  @$pb.TagNumber(5)
  set nickname($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNickname() => $_has(4);
  @$pb.TagNumber(5)
  void clearNickname() => $_clearField(5);
}

class FavoriteCategory extends $pb.GeneratedMessage {
  factory FavoriteCategory({
    $core.String? id,
    $core.String? name,
    $core.int? position,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (position != null) result.position = position;
    return result;
  }

  FavoriteCategory._();

  factory FavoriteCategory.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FavoriteCategory.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FavoriteCategory',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fluxer.user.preferences.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aI(3, _omitFieldNames ? '' : 'position')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FavoriteCategory clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FavoriteCategory copyWith(void Function(FavoriteCategory) updates) =>
      super.copyWith((message) => updates(message as FavoriteCategory))
          as FavoriteCategory;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FavoriteCategory create() => FavoriteCategory._();
  @$core.override
  FavoriteCategory createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FavoriteCategory getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FavoriteCategory>(create);
  static FavoriteCategory? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get position => $_getIZ(2);
  @$pb.TagNumber(3)
  set position($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPosition() => $_has(2);
  @$pb.TagNumber(3)
  void clearPosition() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
