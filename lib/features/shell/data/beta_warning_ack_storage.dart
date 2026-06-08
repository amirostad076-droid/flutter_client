import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _kBetaWarningAcknowledgedBuildNumberKey =
    'beta_warning_acknowledged_build_number';

abstract interface class BetaWarningAckStorage {
  Future<String?> readAcknowledgedBuildNumber();

  Future<void> writeAcknowledgedBuildNumber(String buildNumber);
}

class SecureBetaWarningAckStorage implements BetaWarningAckStorage {
  SecureBetaWarningAckStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
            mOptions: MacOsOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAcknowledgedBuildNumber() {
    return _storage.read(key: _kBetaWarningAcknowledgedBuildNumberKey);
  }

  @override
  Future<void> writeAcknowledgedBuildNumber(String buildNumber) {
    return _storage.write(
      key: _kBetaWarningAcknowledgedBuildNumberKey,
      value: buildNumber,
    );
  }
}

class MapBetaWarningAckStorage implements BetaWarningAckStorage {
  String? acknowledgedBuildNumber;

  @override
  Future<String?> readAcknowledgedBuildNumber() async {
    return acknowledgedBuildNumber;
  }

  @override
  Future<void> writeAcknowledgedBuildNumber(String buildNumber) async {
    acknowledgedBuildNumber = buildNumber;
  }
}
