import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/audio/enums/fluxer_sfx_clip.dart';
import 'package:fluxer_app/core/audio/message_notification_sfx_scheduler.dart';

void main() {
  group('MessageNotificationSfxScheduler.schedule', () {
    test('plays after debounce on first schedule', () {
      fakeAsync((FakeAsync async) {
        final List<FluxerSfxClip> played = <FluxerSfxClip>[];
        final MessageNotificationSfxScheduler scheduler =
            MessageNotificationSfxScheduler();
        scheduler.schedule(clip: FluxerSfxClip.message, play: played.add);
        async.flushMicrotasks();
        expect(played, isEmpty);

        async.elapse(const Duration(milliseconds: 120));
        expect(played, <FluxerSfxClip>[FluxerSfxClip.message]);
      });
    });

    test('enforces default cooldown between different clips', () {
      fakeAsync((FakeAsync async) {
        final List<FluxerSfxClip> played = <FluxerSfxClip>[];
        final MessageNotificationSfxScheduler scheduler =
            MessageNotificationSfxScheduler();
        scheduler.schedule(clip: FluxerSfxClip.message, play: played.add);
        async.elapse(const Duration(milliseconds: 120));
        expect(played, <FluxerSfxClip>[FluxerSfxClip.message]);

        scheduler.schedule(clip: FluxerSfxClip.directMessage, play: played.add);
        async.flushMicrotasks();
        expect(played, <FluxerSfxClip>[FluxerSfxClip.message]);

        async.elapse(const Duration(milliseconds: 900));
        expect(played, <FluxerSfxClip>[
          FluxerSfxClip.message,
          FluxerSfxClip.directMessage,
        ]);
      });
    });

    test('uses longer cooldown for sameChannelMessage when configured', () {
      fakeAsync((FakeAsync async) {
        final List<FluxerSfxClip> played = <FluxerSfxClip>[];
        final MessageNotificationSfxScheduler scheduler =
            MessageNotificationSfxScheduler(
              cooldownMsForClip: (FluxerSfxClip clip) {
                if (clip == FluxerSfxClip.sameChannelMessage) {
                  return 2000;
                }
                return null;
              },
            );
        scheduler.schedule(
          clip: FluxerSfxClip.sameChannelMessage,
          play: played.add,
        );
        async.elapse(const Duration(milliseconds: 120));
        expect(played, <FluxerSfxClip>[FluxerSfxClip.sameChannelMessage]);

        scheduler.schedule(
          clip: FluxerSfxClip.sameChannelMessage,
          play: played.add,
        );
        async.elapse(const Duration(milliseconds: 900));
        expect(played, <FluxerSfxClip>[FluxerSfxClip.sameChannelMessage]);

        async.elapse(const Duration(milliseconds: 1100));
        expect(played, <FluxerSfxClip>[
          FluxerSfxClip.sameChannelMessage,
          FluxerSfxClip.sameChannelMessage,
        ]);
      });
    });

    test('uses default cooldown for clips without custom cooldown', () {
      fakeAsync((FakeAsync async) {
        final List<FluxerSfxClip> played = <FluxerSfxClip>[];
        final MessageNotificationSfxScheduler scheduler =
            MessageNotificationSfxScheduler(
              cooldownMsForClip: (FluxerSfxClip clip) {
                if (clip == FluxerSfxClip.sameChannelMessage) {
                  return 2000;
                }
                return null;
              },
            );
        scheduler.schedule(clip: FluxerSfxClip.message, play: played.add);
        async.elapse(const Duration(milliseconds: 120));
        expect(played, <FluxerSfxClip>[FluxerSfxClip.message]);

        scheduler.schedule(clip: FluxerSfxClip.message, play: played.add);
        async.elapse(const Duration(milliseconds: 900));
        expect(played, <FluxerSfxClip>[
          FluxerSfxClip.message,
          FluxerSfxClip.message,
        ]);
      });
    });

    test('replaces pending clip with the latest scheduled clip', () {
      fakeAsync((FakeAsync async) {
        final List<FluxerSfxClip> played = <FluxerSfxClip>[];
        final MessageNotificationSfxScheduler scheduler =
            MessageNotificationSfxScheduler();
        scheduler.schedule(clip: FluxerSfxClip.message, play: played.add);
        scheduler.schedule(clip: FluxerSfxClip.directMessage, play: played.add);
        async.elapse(const Duration(milliseconds: 120));

        expect(played, <FluxerSfxClip>[FluxerSfxClip.directMessage]);
      });
    });
  });

  group('MessageNotificationSfxScheduler.dispose', () {
    test('cancels pending timer without playing', () {
      fakeAsync((FakeAsync async) {
        final List<FluxerSfxClip> played = <FluxerSfxClip>[];
        final MessageNotificationSfxScheduler scheduler =
            MessageNotificationSfxScheduler();
        scheduler.schedule(clip: FluxerSfxClip.message, play: played.add);
        scheduler.schedule(clip: FluxerSfxClip.directMessage, play: played.add);
        scheduler.dispose();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));

        expect(played, isEmpty);
      });
    });
  });
}
