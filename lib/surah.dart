import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/quran.dart' as Quran;
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/widgets/themed_background.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/services/bookmark_service.dart';
import 'package:allah_everywhere/services/quran_audio_service.dart';

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

  String get _refId => '${widget.surahId}';

  @override
  void initState() {
    super.initState();
    loadSurahData();
    _loadBookmarkState();
    _playingSub = QuranAudioService.handler.playingStream.listen((playing) {
      if (mounted) setState(() => _audioPlaying = playing);
    });
  }

  @override
  void dispose() {
    _playingSub?.cancel();
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
    if (_audioPlaying) {
      await handler.pause();
      return;
    }
    if (handler.loadedSurahId == widget.surahId) {
      await handler.play();
      return;
    }
    setState(() => _audioLoading = true);
    try {
      await handler.loadSurah(widget.surahId);
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

      for (int i = 1; i <= Quran.getVerseCount(widget.surahId); i++) {
        surahText.add(Quran.getVerse(widget.surahId, i));
        surahTranslationEn.add(Quran.getVerseTranslation(widget.surahId, i));
      }
      setState(() => _errorMessage = null);
    } catch (e) {
      VoidLogger.error('Error fetching Surah data', e);
      setState(() => _errorMessage = 'Could not load this Surah. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Background Image
              ThemedBackground(lightImagePath: VoidImages.details_background, fit: BoxFit.fill),
              Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.only(top: 40.h, left: 16.w, right: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(Icons.arrow_back, size: 24.w, color: Colors.white),
                            ),
                            Row(
                              children: [
                                Text(
                                  widget.surahName,
                                  style: TextStyle(
                                    fontSize: 23.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _audioLoading ? null : _toggleAudio,
                                  child: _audioLoading
                                      ? SizedBox(
                                          width: 22.w,
                                          height: 22.w,
                                          child: const CircularProgressIndicator(
                                              strokeWidth: 2, color: Colors.white),
                                        )
                                      : Icon(
                                          _audioPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                          size: 26.w,
                                          color: Colors.white,
                                        ),
                                ),
                                SizedBox(width: 12.w),
                                GestureDetector(
                                  onTap: _toggleBookmark,
                                  child: Icon(
                                    _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                                    size: 24.w,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Container(
                          width: 190.w,
                          height: 1.h,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        SizedBox(height: 10.h),
                        Image.asset(
                          VoidImages.bismillah,
                          height: 30.h,
                          width: 150.w,
                        ),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  Expanded(
                    child: _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14.sp, color: Colors.white),
                              ),
                            ),
                          )
                        : ListView.builder(
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        int verseIndex = currentPage * 3 + index;

                        if (verseIndex < surahText.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    surahText[verseIndex],
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      color: VoidColors.black,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'NotoNaskhArabic',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 35.h),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    surahTranslationEn[verseIndex],
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: VoidColors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                              ],
                            ),
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                  ),


                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: VoidColors.secondary),
                          onPressed: currentPage > 0
                              ? () {
                            setState(() {
                              currentPage--;
                            });
                          }
                              : null,
                          child: Text('Previous',style: TextStyle(color: VoidColors.black),),
                        ),
                        Text(
                          "Page ${currentPage + 1}",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: VoidColors.black,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: VoidColors.secondary),
                          onPressed: currentPage < (surahText.length / 3).ceil() - 1
                              ? () {
                            setState(() {
                              currentPage++;
                            });
                          }
                              : null,
                          child: Text('Next',style: TextStyle(color: VoidColors.black),),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
