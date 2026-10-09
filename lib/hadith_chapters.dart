import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/services/bookmark_service.dart';
import 'Hadith_detail.dart';
import 'controller/HadithChaptersController.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:allah_everywhere/widgets/ask_ai_fab.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class HidthChaptersScreen extends StatefulWidget {
  final String bookSlug;
  final String bookNameInArabic;

  const HidthChaptersScreen(
      {Key? key, required this.bookSlug, required this.bookNameInArabic})
      : super(key: key);

  @override
  State<HidthChaptersScreen> createState() => _HidthChaptersScreenState();
}

class _HidthChaptersScreenState extends State<HidthChaptersScreen> {
  final HadithChaptersController _controller =
      Get.put(HadithChaptersController());
  final BookmarkService _bookmarkService = BookmarkService();
  bool _isBookmarked = false;

  String get _refId => '${widget.bookSlug}|${widget.bookNameInArabic}';

  @override
  void initState() {
    super.initState();
    _controller.fetchChapters(widget.bookSlug, widget.bookNameInArabic);
    _loadBookmarkState();
  }

  Future<void> _loadBookmarkState() async {
    final bookmarked =
        await _bookmarkService.isBookmarked(BookmarkType.hadith, _refId);
    if (mounted) setState(() => _isBookmarked = bookmarked);
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    try {
      final bookmarked = await _bookmarkService.toggle(
        BookmarkType.hadith,
        _refId,
        widget.bookNameInArabic,
        'Hadith book',
      );
      if (mounted) setState(() => _isBookmarked = bookmarked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not update the bookmark. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor =
        isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    return AskAiFabHost(
      category: 'Hadith',
      child: Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: ReadableWidth(child: Column(
        children: [
          // Header
          Container(
            margin: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 0),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VoidBackButton(
                        onPressed: () => Navigator.pop(context),
                        color: Colors.white),
                    Expanded(
                      child: Obx(() {
                        return Text(
                          _controller.bookNameArabic.value,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }),
                    ),
                    GestureDetector(
                      onTap: _toggleBookmark,
                      child: Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                        size: 22.w,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Image.asset(
                  VoidImages.bismillah,
                  height: 26.h,
                  width: 140.w,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return Center(child: CircularProgressIndicator(color: accent));
              }

              if (_controller.errorMessage.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.sp, color: Colors.red),
                      ),
                      SizedBox(height: 8.h),
                      TextButton(
                        onPressed: () => _controller.fetchChapters(
                          widget.bookSlug,
                          widget.bookNameInArabic,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: _controller.chapters.length,
                itemBuilder: (context, index) {
                  final chapter = _controller.chapters[index];
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: PressableTile(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12.r),
                        semanticLabel: '${chapter['chapterNumber']}. ${chapter['chapterEnglish'] ?? ''}',
                        onTap: () {
                          Get.to(() => HadithDetail(
                              bookSlug: widget.bookSlug,
                              chapterNumber: chapter['chapterNumber'] as int));
                        },
                        child: Padding(
                          padding: EdgeInsets.all(14.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${chapter['chapterNumber']}. ${chapter['chapterEnglish'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if ((chapter['chapterUrdu'] as String?)?.trim().isNotEmpty ?? false)
                                Text(
                                  (chapter['chapterUrdu'] as String).trim(),
                                  textDirection: TextDirection.rtl,
                                  style: ScriptureText.urdu(fontSize: 13.sp, color: textColor.withValues(alpha: 0.85)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          SizedBox(height: 100.h),
        ],
      )),
    ));
  }
}
