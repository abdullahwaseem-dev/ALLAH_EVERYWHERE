import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/data/reciters_data.dart';
import 'package:allah_everywhere/services/hifz_plan.dart';

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

  /// Surah data already fetched this session, by "surah|reciter".
  final Map<String, List<AyahAudio>> _fetched = {};

  /// The queue of a Hifz session (one entry per queued item), or null when
  /// the reader's normal surah playback is loaded.
  List<HifzStep>? _hifzSteps;
  int? _hifzSurahId;

  static const _silenceAsset = 'assets/audio/silence_10s.m4a';

  QuranAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState, onError: (Object e, StackTrace st) {
      VoidLogger.error('Quran audio playback error', e);
    });
    _player.currentIndexStream.listen((index) {
      final steps = _hifzSteps;
      if (steps != null) {
        if (index != null && index < steps.length) mediaItem.add(queue.value[index]);
        return;
      }
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
  // Read synchronously by the Surah reader to resync its highlight right
  // away (e.g. after the screen was locked), before the next stream event.
  int? get currentIndex => _player.currentIndex;
  ProcessingState get processingState => _player.processingState;
  Stream<bool> get playingStream => _player.playingStream;
  bool get isPlaying => _player.playing;

  /// Fetches every ayah of [surahId] (Arabic text + [reciterId]'s audio +
  /// an English translation) in a single call to the free, keyless
  /// api.alquran.cloud, then loads them as a gapless background playlist.
  Future<void> loadSurah(int surahId, {int startAtAyah = 1, String reciterId = 'ar.alafasy'}) async {
    _ayahs = await fetchSurahAyahs(surahId, reciterId);
    _hifzSteps = null;
    _hifzSurahId = null;
    final reciterName = reciterFor(reciterId).name;
    queue.add(_ayahs.map((a) => _mediaItemFor(a, reciterName)).toList());
    final source = ConcatenatingAudioSource(
      children: _ayahs.map((a) => AudioSource.uri(Uri.parse(a.audioUrl))).toList(),
    );
    final startIndex = (startAtAyah - 1).clamp(0, _ayahs.length - 1);
    await _player.setSpeed(1.0); // a Hifz session may have changed it
    await _player.setAudioSource(source, initialIndex: startIndex);
    _loadedSurahId = surahId;
    _loadedReciterId = reciterId;
  }

  /// Loads only ayat [fromAyah]-[toAyah] of [surahId], e.g. the passage
  /// quoted in a Prophets' Story. As with a Hifz session, [loadedSurahId]
  /// becomes null so the Surah reader doesn't take this for its own playback.
  Future<void> loadAyahRange(int surahId, int fromAyah, int toAyah, {String reciterId = 'ar.alafasy'}) async {
    final all = await fetchSurahAyahs(surahId, reciterId);
    final start = (fromAyah - 1).clamp(0, all.length - 1);
    final end = toAyah.clamp(start + 1, all.length);
    _ayahs = all.sublist(start, end);
    _hifzSteps = null;
    _hifzSurahId = null;
    final reciterName = reciterFor(reciterId).name;
    queue.add(_ayahs.map((a) => _mediaItemFor(a, reciterName)).toList());
    await _player.setSpeed(1.0);
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: _ayahs.map((a) => AudioSource.uri(Uri.parse(a.audioUrl))).toList()),
    );
    _loadedSurahId = null;
    _loadedReciterId = reciterId;
  }

  /// Every ayah of [surahId] with [reciterId]'s audio URL, fetched once per
  /// app session (one request to api.alquran.cloud).
  Future<List<AyahAudio>> fetchSurahAyahs(int surahId, String reciterId) async {
    final key = '$surahId|$reciterId';
    final cached = _fetched[key];
    if (cached != null) return cached;
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
    final ayahs = List.generate(arabicAyahs.length, (i) {
      final a = arabicAyahs[i] as Map<String, dynamic>;
      final t = translationAyahs[i] as Map<String, dynamic>;
      return AyahAudio(
        numberInSurah: a['numberInSurah'] as int,
        arabicText: a['text'] as String,
        translation: t['text'] as String,
        audioUrl: a['audio'] as String,
      );
    });
    _fetched[key] = ayahs;
    return ayahs;
  }

  /// Queues a whole Hifz session: [steps] (see buildHifzPlan) with each
  /// recitation played from its downloaded file in [ayahFiles] and each pause
  /// clipped from a bundled silent track. Because the entire session is in
  /// the native player's queue, repeats and pauses carry on with the screen
  /// locked. [loadedSurahId] becomes null, so the reader doesn't mistake the
  /// session for its own playback.
  Future<void> loadHifzSession({
    required int surahId,
    required String surahName,
    required String reciterId,
    required Map<int, String> ayahFiles,
    required List<HifzStep> steps,
    required HifzSettings settings,
  }) async {
    final s = settings.clamped();
    final reciterName = reciterFor(reciterId).name;
    final pause = pauseClipLength(s.gapSeconds, s.speed);
    final children = <AudioSource>[
      for (final step in steps)
        step.isPause
            ? ClippingAudioSource(child: AudioSource.asset(_silenceAsset), start: Duration.zero, end: pause)
            : AudioSource.file(ayahFiles[step.ayah]!),
    ];
    queue.add([
      for (int i = 0; i < steps.length; i++)
        MediaItem(
          id: 'hifz-$surahId-$i',
          title: '$surahName ${steps[i].highlightedAyah}',
          album: 'Hifz',
          artist: reciterName,
        ),
    ]);
    _hifzSteps = steps;
    _hifzSurahId = surahId;
    _ayahs = [];
    _loadedSurahId = null;
    _loadedReciterId = reciterId;
    await _player.setSpeed(s.speed);
    await _player.setAudioSource(ConcatenatingAudioSource(useLazyPreparation: true, children: children));
  }

  bool get hasHifzSession => _hifzSteps != null;
  int? get hifzSurahId => _hifzSurahId;

  /// The Hifz step now playing, for highlighting the ayah.
  Stream<HifzStep?> get hifzStepStream => _player.currentIndexStream.map(_stepAt);
  HifzStep? get currentHifzStep => _stepAt(_player.currentIndex);

  HifzStep? _stepAt(int? index) {
    final steps = _hifzSteps;
    if (steps == null || index == null || index >= steps.length) return null;
    return steps[index];
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
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  Future<void> seekToAyahIndex(int index) => _player.seek(Duration.zero, index: index);

  Future<void> dispose() => _player.dispose();
}
