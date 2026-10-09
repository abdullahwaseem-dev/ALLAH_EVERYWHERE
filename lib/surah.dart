import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart' as Quran;
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/services/bookmark_service.dart';
import 'package:allah_everywhere/services/quran_audio_service.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/data/reciters_data.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:allah_everywhere/widgets/ask_ai_fab.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:audio_service/audio_service.dart' show PlaybackState;
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:allah_everywhere/controller/QuranController.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/hifz_practice.dart';

/// Maps the app's UI language to one of the offline translations bundled in
/// the `quran` package. Not every app language has a dedicated translation
/// there (no Hindi or German edition exists), so those fall back to English
/// rather than showing nothing.
Quran.Translation _translationForLanguage(String code) {
  switch (code) {
    case 'ur':
      return Quran.Translation.urdu;
    case 'zh':
      return Quran.Translation.chinese;
    case 'fr':
      return Quran.Translation.frHamidullah;
    case 'tr':
      return Quran.Translation.trSaheeh;
    default:
      return Quran.Translation.enSaheeh;
  }
}

class SurahScreen extends StatefulWidget {
  final String surahName;
  final int surahId;

  /// Ayah to open at (1-based), e.g. the last recited one for Continue Reading.
  final int initialAyah;

  SurahScreen({required this.surahName, required this.surahId, this.initialAyah = 1});

  @override
  _SurahScreenState createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> with WidgetsBindingObserver {
  static const _ayahsPerPage = 3;
  int currentPage = 0;

  List<String> surahText = [];
  List<String> surahTranslationEn = [];
  String? _errorMessage;

  final BookmarkService _bookmarkService = BookmarkService();
  bool _isBookmarked = false;

  bool _audioLoading = false;
  bool _audioPlaying = false;
  StreamSubscription<bool>? _playingSub;

  final LanguageController _languageController = Get.find<LanguageController>();
  Worker? _localeWorker;

  // Recitation highlight. _recitingIndex is the 0-based ayah index the Qari
  // is on in THIS surah (kept while paused), or null when this surah isn't
  // loaded or playback is stopped/finished.
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<PlaybackState>? _stateSub;
  int? _recitingIndex;
  // Off once the user turns pages by hand during playback, until they tap
  // "Follow recitation".
  bool _followRecitation = true;
  final Map<int, GlobalKey> _ayahKeys = {};

  String get _refId => '${widget.surahId}';

  /// The play/pause icon and toggle logic must only reflect the audio
  /// engine's playing state when *this* Surah is the one actually loaded -
  /// otherwise leaving one Surah playing in the background and opening a
  /// different one shows a misleading "pause" icon here, and tapping it
  /// pauses the wrong Surah instead of loading this one.
  bool get _isThisSurahPlaying =>
      _audioPlaying && QuranAudioService.handler.loadedSurahId == widget.surahId;

  @override
  void initState() {
    super.initState();
    loadSurahData();
    _loadBookmarkState();
    _audioPlaying = QuranAudioService.handler.isPlaying;
    _playingSub = QuranAudioService.handler.playingStream.listen((playing) {
      if (mounted) setState(() => _audioPlaying = playing);
    });
    final verseCount = Quran.getVerseCount(widget.surahId);
    currentPage = (widget.initialAyah - 1).clamp(0, verseCount - 1) ~/ _ayahsPerPage;
    _indexSub = QuranAudioService.handler.currentIndexStream.listen((index) => _syncRecitation(index: index));
    // Catches stop/finish (the index stream keeps its last value then) and
    // the moment loadSurah() makes this the loaded surah.
    _stateSub = QuranAudioService.handler.playbackState.listen((_) => _syncRecitation());
    WidgetsBinding.instance.addObserver(this);
    // If this surah is already playing, jump straight to the current ayah.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRecitation(forceShow: true));
    // Re-translate in place if the user switches language while this
    // Surah is open, instead of only picking up the new language the next
    // time the screen is opened.
    _localeWorker = ever(_languageController.locale, (_) => loadSurahData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _indexSub?.cancel();
    _stateSub?.cancel();
    _playingSub?.cancel();
    _localeWorker?.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarkState() async {
    final bookmarked = await _bookmarkService.isBookmarked(BookmarkType.surah, _refId);
    if (mounted) setState(() => _isBookmarked = bookmarked);
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    try {
      final bookmarked = await _bookmarkService.toggle(
          BookmarkType.surah, _refId, widget.surahName, 'Surah ${widget.surahId}');
      if (mounted) setState(() => _isBookmarked = bookmarked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update the bookmark. Please try again.')));
      }
    }
  }

  Future<void> _toggleAudio() async {
    HapticFeedback.lightImpact();
    final handler = QuranAudioService.handler;
    final reciterId = QuranAudioService.selectedReciterId;
    if (_isThisSurahPlaying) {
      await handler.pause();
      return;
    }
    if (handler.loadedSurahId == widget.surahId && handler.loadedReciterId == reciterId) {
      await handler.play();
      return;
    }
    setState(() => _audioLoading = true);
    try {
      await handler.loadSurah(widget.surahId, reciterId: reciterId);
      await handler.play();
    } catch (e) {
      VoidLogger.error('Failed to load Surah audio', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load recitation audio. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _audioLoading = false);
    }
  }

  Future<void> _stopAudio() async {
    await QuranAudioService.handler.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the lock screen / another app: show the ayah the Qari is on
    // now, even if stream events were missed while in the background.
    if (state == AppLifecycleState.resumed) _syncRecitation(forceShow: true);
  }

  /// Recomputes which ayah of this surah is being recited from the audio
  /// handler's live state. [index] is the queue index from the stream.
  void _syncRecitation({int? index, bool forceShow = false}) {
    if (!mounted) return;
    final handler = QuranAudioService.handler;
    final state = handler.processingState;
    final active = handler.loadedSurahId == widget.surahId &&
        state != ProcessingState.idle &&
        state != ProcessingState.completed;
    final queueIndex = index ?? handler.currentIndex;
    final ayahs = handler.currentAyahs;
    int? verseIndex;
    if (active && queueIndex != null && queueIndex >= 0 && queueIndex < ayahs.length) {
      // The queue is the whole surah, so this is normally just queueIndex;
      // mapping via numberInSurah keeps it right whatever the queue holds.
      verseIndex = ayahs[queueIndex].numberInSurah - 1;
    }

    final changed = verseIndex != _recitingIndex;
    if (changed) setState(() => _recitingIndex = verseIndex);
    if (verseIndex == null) return;
    if (changed) _saveLastRead(verseIndex + 1);
    if ((changed || forceShow) && _followRecitation) _showAyah(verseIndex);
  }

  void _saveLastRead(int ayah) {
    if (Get.isRegistered<QuranController>()) {
      Get.find<QuranController>().updateLastReadSurah(widget.surahName, widget.surahId, ayah);
    } else {
      QuranController.saveLastRead(widget.surahName, widget.surahId, ayah);
    }
  }

  /// Turns to [verseIndex]'s page and scrolls its card into view.
  void _showAyah(int verseIndex) {
    final page = verseIndex ~/ _ayahsPerPage;
    if (page != currentPage) setState(() => currentPage = page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cardContext = _ayahKeys[verseIndex]?.currentContext;
      if (cardContext == null || !mounted) return;
      Scrollable.ensureVisible(
        cardContext,
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    });
  }

  void _changePage(int delta) {
    setState(() {
      currentPage += delta;
      // Reading ahead/behind on purpose: stop dragging them back to the Qari.
      if (_recitingIndex != null) _followRecitation = false;
    });
  }

  void _resumeFollowing() {
    setState(() => _followRecitation = true);
    final index = _recitingIndex;
    if (index != null) _showAyah(index);
  }

  /// Tap on an ayah: recite from there.
  Future<void> _playFromAyah(int verseIndex) async {
    if (_audioLoading) return;
    HapticFeedback.selectionClick();
    final handler = QuranAudioService.handler;
    final reciterId = QuranAudioService.selectedReciterId;
    setState(() => _followRecitation = true);

    final loaded = handler.loadedSurahId == widget.surahId &&
        handler.loadedReciterId == reciterId &&
        handler.processingState != ProcessingState.idle;
    if (loaded) {
      final queueIndex = handler.currentAyahs.indexWhere((a) => a.numberInSurah == verseIndex + 1);
      // Highlight jumps immediately; the index stream confirms it.
      setState(() => _recitingIndex = verseIndex);
      await handler.seekToAyahIndex(queueIndex < 0 ? verseIndex : queueIndex);
      if (!handler.isPlaying) await handler.play();
      return;
    }

    setState(() => _audioLoading = true);
    try {
      await handler.loadSurah(widget.surahId, startAtAyah: verseIndex + 1, reciterId: reciterId);
      await handler.play();
    } catch (e) {
      VoidLogger.error('Failed to load Surah audio', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load recitation audio. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _audioLoading = false);
    }
  }

  void loadSurahData() {
    try {
      surahText.clear();
      surahTranslationEn.clear();
      final translation = _translationForLanguage(_languageController.locale.value.languageCode);

      for (int i = 1; i <= Quran.getVerseCount(widget.surahId); i++) {
        surahText.add(Quran.getVerse(widget.surahId, i));
        surahTranslationEn.add(Quran.getVerseTranslation(widget.surahId, i, translation: translation));
      }
      setState(() => _errorMessage = null);
    } catch (e) {
      VoidLogger.error('Error fetching Surah data', e);
      setState(() => _errorMessage = 'Could not load this Surah. Please try again.');
    }
  }

  /// "Explain Surah Al-Mulk, ayahs 4–6": the ayahs on the current page, in
  /// the user's language (Arabic surah names for Arabic and Urdu).
  String? _askAiQuestion() {
    if (surahText.isEmpty) return null;
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final name = (lang == 'ar' || lang == 'ur')
        ? Quran.getSurahNameArabic(widget.surahId)
        : Quran.getSurahName(widget.surahId);
    final from = currentPage * 3 + 1;
    final to = (from + 2).clamp(from, surahText.length);
    return from == to ? t.askAiExplainAyah(name, from) : t.askAiExplainAyahs(name, from, to);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;
    final reciterName = reciterFor(QuranAudioService.selectedReciterId).name;
    final t = AppLocalizations.of(context)!;

    return AskAiFabHost(
      category: 'Quran',
      questionBuilder: _askAiQuestion,
      child: Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: ReadableWidth(child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Row(
                children: [
                  VoidBackButton(onPressed: () => Navigator.pop(context)),
                  Expanded(
                    child: Text(
                      widget.surahName,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18.sp, color: textColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Hifz mode, starting at the first ayah on this page.
                  IconButton(
                    tooltip: AppLocalizations.of(context)!.hifzMode,
                    onPressed: () => Get.to(() => HifzPracticeScreen(
                          surahId: widget.surahId,
                          from: currentPage * _ayahsPerPage + 1,
                        )),
                    icon: Icon(Icons.repeat_rounded, size: 22.sp, color: accent),
                  ),
                  IconButton(
                    onPressed: _toggleBookmark,
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                      size: 22.sp,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [VoidColors.cardDark, VoidColors.oliveDeep]
                        : [VoidColors.oliveDeep, VoidColors.dustyRose],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  children: [
                    Image.asset(VoidImages.bismillah, height: 26.h, color: Colors.white),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Reciting: $reciterName',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5.sp, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _audioLoading
                            ? SizedBox(
                                width: 40.w,
                                height: 40.w,
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : GestureDetector(
                                onTap: _toggleAudio,
                                child: Container(
                                  width: 48.w,
                                  height: 48.w,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                  child: Icon(
                                    _isThisSurahPlaying ? Icons.pause : Icons.play_arrow,
                                    color: VoidColors.oliveDeep,
                                    size: 26.sp,
                                  ),
                                ),
                              ),
                        SizedBox(width: 18.w),
                        GestureDetector(
                          onTap: (_audioPlaying || QuranAudioService.handler.isPlaying) ? _stopAudio : null,
                          child: Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
                            ),
                            child: Icon(
                              Icons.stop_rounded,
                              color: Colors.white.withOpacity((_audioPlaying || QuranAudioService.handler.isPlaying) ? 1 : 0.4),
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.sp, color: textColor),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: _ayahsPerPage,
                      itemBuilder: (context, index) {
                        int verseIndex = currentPage * _ayahsPerPage + index;
                        if (verseIndex >= surahText.length) return const SizedBox.shrink();
                        final highlighted = verseIndex == _recitingIndex;
                        final recitingNow = highlighted && _audioPlaying;
                        const highlightDuration = Duration(milliseconds: 300);

                        return Padding(
                          key: _ayahKeys.putIfAbsent(verseIndex, () => GlobalKey()),
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: AnimatedContainer(
                          duration: highlightDuration,
                          curve: Curves.easeOut,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: highlighted
                                ? Color.alphaBlend(accent.withValues(alpha: isDark ? 0.16 : 0.10), cardColor)
                                : cardColor,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: highlighted
                                    ? accent.withValues(alpha: isDark ? 0.30 : 0.25)
                                    : Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                                blurRadius: highlighted ? 12 : 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: PressableTile(
                          onTap: () => _playFromAyah(verseIndex),
                          semanticLabel: t.playFromAyah(verseIndex + 1),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Stack(
                          children: [
                          Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AnimatedSize(
                                duration: highlightDuration,
                                curve: Curves.easeOut,
                                child: highlighted
                                    ? Padding(
                                        padding: EdgeInsets.only(bottom: 10.h),
                                        child: Row(
                                          children: [
                                            Icon(
                                              recitingNow ? Icons.graphic_eq_rounded : Icons.pause_rounded,
                                              size: 18.sp,
                                              color: accent,
                                            ),
                                            SizedBox(width: 6.w),
                                            Flexible(
                                              child: Text(
                                                recitingNow
                                                    ? t.nowPlayingAyah(verseIndex + 1)
                                                    : t.pausedAtAyah(verseIndex + 1),
                                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: accent),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(width: double.infinity),
                              ),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  surahText[verseIndex],
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoNaskhArabic',
                                    height: 1.8,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Container(height: 1, width: double.infinity, color: textColor.withOpacity(0.08)),
                              SizedBox(height: 12.h),
                              // The Urdu translation is RTL; every other
                              // bundled translation is LTR.
                              Directionality(
                                textDirection: _languageController.locale.value.languageCode == 'ur'
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                child: Text(
                                  surahTranslationEn[verseIndex],
                                  textAlign: TextAlign.start,
                                  style: TextStyle(fontSize: 14.5.sp, color: subColor, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                          ),
                          // Accent bar on the leading edge (left in LTR,
                          // right in RTL), clipped to the card's corners.
                          PositionedDirectional(
                            start: 0,
                            top: 0,
                            bottom: 0,
                            child: AnimatedContainer(
                              duration: highlightDuration,
                              curve: Curves.easeOut,
                              width: highlighted ? 4 : 0,
                              color: accent,
                            ),
                          ),
                          ],
                          ),
                          ),
                          ),
                        );
                      },
                    ),
            ),
            if (_recitingIndex != null && !_followRecitation)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: ElevatedButton.icon(
                  onPressed: _resumeFollowing,
                  icon: const Icon(Icons.graphic_eq_rounded, size: 18),
                  label: Text(t.followRecitation),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: isDark ? VoidColors.oliveDeep : Colors.white,
                    elevation: 2,
                    minimumSize: const Size(0, 44),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                    onPressed: currentPage > 0 ? () => _changePage(-1) : null,
                    child: Text('Previous', style: TextStyle(color: textColor)),
                  ),
                  Text(
                    'Page ${currentPage + 1}',
                    style: TextStyle(fontSize: 14.sp, color: subColor, fontWeight: FontWeight.w600),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                    onPressed: currentPage < (surahText.length / _ayahsPerPage).ceil() - 1
                        ? () => _changePage(1)
                        : null,
                    child: const Text('Next', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 100.h),
          ],
        ),
      )),
    ));
  }
}
