// Plays a real Hifz session through the app's audio_service handler on a
// device or simulator: downloads Al-Ikhlas 1-2 (Alafasy), queues 2 repeats
// of each with 1 s pauses at 1.25x, and checks every recitation and pause
// plays in order, that pauses last about 1 s despite the speed, and that the
// session ends by itself. Needs network.
//
//   flutter test integration_test/hifz_audio_test.dart \
//     -d <simulator-id> --dart-define-from-file=dart_defines.json

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:integration_test/integration_test.dart';

import 'package:allah_everywhere/services/hifz_audio_cache.dart';
import 'package:allah_everywhere/services/hifz_plan.dart';
import 'package:allah_everywhere/services/quran_audio_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a Hifz session plays every step in order and ends', (tester) async {
    await tester.runAsync(() async {
      await GetStorage.init();
      await QuranAudioService.init();
      final handler = QuranAudioService.handler;

      final files = await HifzAudioCache.ensure(surahId: 112, from: 1, to: 2, reciterId: 'ar.alafasy');
      expect(files.keys, [1, 2]);

      const settings = HifzSettings(repeatEachAyah: 2, rounds: 1, gapSeconds: 1, speed: 1.25);
      final steps = buildHifzPlan(from: 1, to: 2, settings: settings);
      expect(steps.length, 7); // 4 recitations, 3 pauses

      final seen = <int>[];
      final startedAt = <int, DateTime>{};
      final sub = handler.currentIndexStream.listen((i) {
        if (i != null && (seen.isEmpty || seen.last != i)) {
          seen.add(i);
          startedAt[i] = DateTime.now();
        }
      });

      await handler.loadHifzSession(
        surahId: 112,
        surahName: 'Al-Ikhlas',
        reciterId: 'ar.alafasy',
        ayahFiles: files,
        steps: steps,
        settings: settings,
      );
      expect(handler.hasHifzSession, isTrue);
      expect(handler.loadedSurahId, isNull); // the reader won't treat it as its own
      await handler.play();

      final done = Completer<void>();
      final stateSub = handler.playbackState.listen((s) {
        if (seen.length == steps.length && !s.playing && s.processingState != AudioProcessingState.loading) {
          if (!done.isCompleted) done.complete();
        }
      });
      await done.future.timeout(const Duration(seconds: 120));
      final endedAt = DateTime.now();
      await sub.cancel();
      await stateSub.cancel();

      // ignore: avoid_print
      print('HIFZ_STEPS_SEEN $seen');
      expect(seen, List.generate(steps.length, (i) => i));

      for (int i = 0; i < steps.length; i++) {
        if (!steps[i].isPause) continue;
        final next = i + 1 < steps.length ? startedAt[i + 1]! : endedAt;
        final ms = next.difference(startedAt[i]!).inMilliseconds;
        // ignore: avoid_print
        print('HIFZ_PAUSE step $i: $ms ms');
        expect(ms, inInclusiveRange(600, 1700), reason: 'pause $i should sound like ~1 s at 1.25x');
      }
    });
  });
}
