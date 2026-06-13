import 'package:fluxer_app/features/profile/domain/time_window_presets.dart';
import 'package:test/test.dart';

void main() {
  group('getTimeWindowPresets', () {
    test('includes never first when requested', () {
      final List<TimeWindowPreset> presets = getTimeWindowPresets(
        includeDeveloperOptions: false,
      );
      expect(presets.first.key, TimeWindowKey.never);
      expect(
        presets.map((TimeWindowPreset preset) => preset.key),
        containsAll(<TimeWindowKey>[
          TimeWindowKey.fifteenM,
          TimeWindowKey.thirtyM,
          TimeWindowKey.oneH,
          TimeWindowKey.threeH,
          TimeWindowKey.fourH,
          TimeWindowKey.eightH,
          TimeWindowKey.twentyFourH,
          TimeWindowKey.threeD,
        ]),
      );
    });

    test('includes developer preset only when enabled', () {
      final List<TimeWindowPreset> withoutDeveloper = getTimeWindowPresets(
        includeDeveloperOptions: false,
      );
      final List<TimeWindowPreset> withDeveloper = getTimeWindowPresets(
        includeDeveloperOptions: true,
      );
      expect(
        withoutDeveloper.any(
          (TimeWindowPreset preset) => preset.key == TimeWindowKey.tenS,
        ),
        isFalse,
      );
      expect(
        withDeveloper.any(
          (TimeWindowPreset preset) => preset.key == TimeWindowKey.tenS,
        ),
        isTrue,
      );
    });
  });

  group('minutesToDuration', () {
    test('returns null for permanent presets', () {
      expect(minutesToDuration(null), isNull);
    });

    test('converts minutes to duration', () {
      expect(minutesToDuration(15), const Duration(minutes: 15));
      expect(minutesToDuration(10 / 60), const Duration(seconds: 10));
    });
  });

  group('getTimeWindowKeyForExpiresAt', () {
    test('returns never when expiry is null', () {
      expect(
        getTimeWindowKeyForExpiresAt(null, includeDeveloperOptions: false),
        TimeWindowKey.never,
      );
    });

    test('matches nearest finite preset', () {
      final DateTime reference = DateTime.utc(2026, 6, 13, 12);
      final DateTime expiresAt = reference.add(const Duration(minutes: 20));
      expect(
        getTimeWindowKeyForExpiresAt(
          expiresAt,
          includeDeveloperOptions: false,
          referenceTime: reference,
        ),
        TimeWindowKey.thirtyM,
      );
    });
  });
}
