import 'dart:async';
import 'package:flutter/material.dart';
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

  SurahScreen({required this.surahName, required this.surahId});

  @override
  _SurahScreenState createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
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

  String get _refId => '${widget.surahId}';

  @override
  void initState() {
    super.initState();
    loadSurahData();
    _loadBookmarkState();
    _playingSub = QuranAudioService.handler.playingStream.listen((playing) {
      if (mounted) setState(() => _audioPlaying = playing);
    });
    // Re-translate in place if the user switches language while this
    // Surah is open, instead of only picking up the new language the next
    // time the screen is opened.
    _localeWorker = ever(_languageController.locale, (_) => loadSurahData());
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _localeWorker?.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarkState() async {
    final bookmarked = await _bookmarkService.isBookmarked(BookmarkType.surah, _refId);
    if (mounted) setState(() => _isBookmarked = bookmarked);
  }

  Future<void> _toggleBookmark() async {
    await _bookmarkService.toggle(BookmarkType.surah, _refId, widget.surahName, 'Surah ${widget.surahId}');
    if (mounted) setState(() => _isBookmarked = !_isBookmarked);
  }

  Future<void> _toggleAudio() async {
    final handler = QuranAudioService.handler;
    final reciterId = QuranAudioService.selectedReciterId;
    if (_audioPlaying) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load recitation audio. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _audioLoading = false);
    }
  }

  Future<void> _stopAudio() async {
    await QuranAudioService.handler.stop();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;
    final reciterName = reciterFor(QuranAudioService.selectedReciterId).name;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: SafeArea(
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
                                    _audioPlaying ? Icons.pause : Icons.play_arrow,
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
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        int verseIndex = currentPage * 3 + index;
                        if (verseIndex >= surahText.length) return const SizedBox.shrink();

                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
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
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  surahTranslationEn[verseIndex],
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontSize: 14.5.sp, color: subColor, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
                    onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
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
                    onPressed: currentPage < (surahText.length / 3).ceil() - 1
                        ? () => setState(() => currentPage++)
                        : null,
                    child: const Text('Next', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }
}
