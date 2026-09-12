import 'package:audio_service/audio_service.dart';
import 'quran_audio_handler.dart';

/// Holds the single, app-wide QuranAudioHandler instance created by
/// `AudioService.init` in main.dart. UI code reads `QuranAudioService.handler`
/// rather than creating its own player, so playback state (and the
/// background service it runs under) is shared across every screen.
class QuranAudioService {
  static QuranAudioHandler? _handler;

  static Future<void> init() async {
    if (_handler != null) return;
    _handler = await AudioService.init(
      builder: () => QuranAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.allaheverywhere.app.audio',
        androidNotificationChannelName: 'Quran Recitation',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }

  static QuranAudioHandler get handler {
    final h = _handler;
    if (h == null) {
      throw StateError('QuranAudioService.init() must be awaited before use (see main.dart).');
    }
    return h;
  }
}
