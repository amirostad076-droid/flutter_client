import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/build/app_build_config.dart';
import 'package:measure_flutter/measure_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'measure_reporting_provider.g.dart';

const String _kMeasureReportingEnabledKey = 'measure_reporting_enabled';

bool measureReportingIsAvailable() {
  if (kIsWeb) {
    return false;
  }
  if (!Platform.isAndroid && !Platform.isIOS) {
    return false;
  }
  return AppBuildConfig.hasMeasureConfig;
}

@Riverpod(keepAlive: true)
class MeasureReporting extends _$MeasureReporting {
  @override
  bool build() => false;

  Future<void> load() async {
    if (!measureReportingIsAvailable()) {
      return;
    }
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool isEnabled =
        preferences.getBool(_kMeasureReportingEnabledKey) ?? false;
    state = isEnabled;
    if (!isEnabled) {
      return;
    }
    await Measure.instance.start();
  }

  Future<void> setEnabled({required bool value}) async {
    if (!measureReportingIsAvailable()) {
      return;
    }
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_kMeasureReportingEnabledKey, value);
    if (value) {
      await Measure.instance.start();
    } else {
      await Measure.instance.stop();
    }
    state = value;
  }
}
