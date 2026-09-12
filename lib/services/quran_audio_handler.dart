import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/data/reciters_data.dart';

/// A single ayah's audio + text, used both to drive playback and to show
/// the currently-playing verse's translation in the UI.
class AyahAudio {
  final int numberInSurah;
  final String arabicText;
  final String translation;
  final String audioUrl;

  AyahAudio({
    required this.numberInSurah,
    required this.arabicText,
    required this.translation,
    required this.audioUrl,
  });
}

/// Background-capable Quran audio player. Built on `audio_service` so
/// playback keeps running (with lock-screen/notification controls) when the
/// user switches to another app - it only stops when the user stops it or
/// the app process is killed, not just backgrounded.
class QuranAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  List<AyahAudio> _ayahs = [];
  int? _loadedSurahId;
  String _loadedReciterId = 'ar.alafasy';

  QuranAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState, onError: (Object e, StackTrace st) {
      VoidLogger.error('Quran audio playback error', e);
    });
    _player.currentIndexStream.listen((index) {
      if (index == null || _ayahs.isEmpty || index >= _ayahs.length) return;
      mediaItem.add(_mediaItemFor(_ayahs[index], reciterFor(_loadedReciterId).name));
    });
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) stop();
    });
  }

  List<AyahAudio> get currentAyahs => _ayahs;
  int? get loadedSurahId => _loadedSurahId;
  String get loadedReciterId => _loadedReciterId;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<bool> get playingStream => _player.playingStream;
  bool get isPlaying => _player.playing;

  /// Fetches every ayah of [surahId] (Arabic text + [reciterId]'s audio +
  /// an English translation) in a single call to the free, keyless
  /// api.alquran.cloud, then loads them as a gapless background playlist.
  Future<void> loadSurah(int surahId, {int startAtAyah = 1, String reciterId = 'ar.alafasy'}) async {
    final url = Uri.parse(
      'https://api.alquran.cloud/v1/surah/$surahId/editions/$reciterId,en.sahih',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Failed to load Surah audio: HTTP ${response.statusCode}');
    }
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final editions = decoded['data'] as List<dynamic>;
    final arabicEdition = editions.firstWhere((e) => e['edition']['identifier'] == reciterId);
    final translationEdition = editions.firstWhere((e) => e['edition']['identifier'] == 'en.sahih');
    final arabicAyahs = arabicEdition['ayahs'] as List<dynamic>;
    final translationAyahs = translationEdition['ayahs'] as List<dynamic>;
    final reciterName = reciterFor(reciterId).name;

    _ayahs = List.generate(arabicAyahs.length, (i) {
      final a = arabicAyahs[i] as Map<String, dynamic>;
      final t = translationAyahs[i] as Map<String, dynamic>;
      return AyahAudio(
        numberInSurah: a['numberInSurah'] as int,
        arabicText: a['text'] as String,
        translation: t['text'] as String,
        audioUrl: a['audio'] as String,
      );
    });

    queue.add(_ayahs.map((a) => _mediaItemFor(a, reciterName)).toList());
    final source = ConcatenatingAudioSource(
      children: _ayahs.map((a) => AudioSource.uri(Uri.parse(a.audioUrl))).toList(),
    );
    final startIndex = (startAtAyah - 1).clamp(0, _ayahs.length - 1);
    await _player.setAudioSource(source, initialIndex: startIndex);
    _loadedSurahId = surahId;
    _loadedReciterId = reciterId;
  }

  MediaItem _mediaItemFor(AyahAudio a, String reciterName) => MediaItem(
        id: a.audioUrl,
        title: 'Ayah ${a.numberInSurah}',
        artist: reciterName,
        extras: {'translation': a.translation, 'arabic': a.arabicText},
      );

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  Future<void> seekToAyahIndex(int index) => _player.seek(Duration.zero, index: index);

  Future<void> dispose() => _player.dispose();
}
