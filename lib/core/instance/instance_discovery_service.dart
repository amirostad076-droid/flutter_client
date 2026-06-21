import 'package:dio/dio.dart';
import 'package:fluxer_app/core/instance/instance_config_snapshot.dart';
import 'package:fluxer_app/core/instance/instance_constants.dart';
import 'package:fluxer_app/core/instance/instance_endpoint_normalizer.dart';
import 'package:fluxer_dart/export.dart';

class InstanceDiscoveryException implements Exception {
  const InstanceDiscoveryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InstanceDiscoveryService {
  InstanceDiscoveryService({
    InstanceEndpointNormalizer? normalizer,
    Dio? dio,
  })  : _normalizer = normalizer ?? const InstanceEndpointNormalizer(),
        _dio =
            dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 10),
                headers: const <String, dynamic>{
                  'Accept': 'application/json',
                },
              ),
            );

  final InstanceEndpointNormalizer _normalizer;
  final Dio _dio;

  Future<InstanceConfigSnapshot> connectToEndpoint(String input) async {
    final String apiEndpoint = _normalizer.normalizeEndpoint(input);
    final String wellKnownUrl = _normalizer.buildWellKnownUrl(apiEndpoint);
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(wellKnownUrl);
      if (response.statusCode != 200 || response.data == null) {
        throw InstanceDiscoveryException(
          'Failed to reach $wellKnownUrl (${response.statusCode ?? 'unknown'})',
        );
      }
      final Object? data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const InstanceDiscoveryException(
          'Invalid instance discovery response',
        );
      }
      final WellKnownFluxerResponse wellKnown =
          WellKnownFluxerResponse.fromJson(data);
      _assertCodeVersion(wellKnown.apiCodeVersion);
      final InstanceConfigSnapshot snapshot =
          InstanceConfigSnapshot.fromWellKnown(
        wellKnown: wellKnown,
        normalizer: _normalizer,
      );
      return snapshot;
    } on DioException catch (error) {
      final int? statusCode = error.response?.statusCode;
      throw InstanceDiscoveryException(
        'Failed to reach $wellKnownUrl (${statusCode ?? 'unknown'})',
      );
    }
  }

  void _assertCodeVersion(int instanceVersion) {
    if (instanceVersion < InstanceConstants.apiCodeVersion) {
      throw InstanceDiscoveryException(
        'Incompatible server (code version $instanceVersion); '
        'this client requires ${InstanceConstants.apiCodeVersion}.',
      );
    }
  }
}
