import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/services/bookmark_service.dart';
import 'Hadith_detail.dart';
import 'controller/HadithChaptersController.dart';

class HidthChaptersScreen extends StatefulWidget {
  final String bookSlug;
  final String bookNameInArabic;

  const HidthChaptersScreen({Key? key, required this.bookSlug, required this.bookNameInArabic})
      : super(key: key);

  @override
  State<HidthChaptersScreen> createState() => _HidthChaptersScreenState();
}

class _HidthChaptersScreenState extends State<HidthChaptersScreen> {
  final HadithChaptersController _controller = Get.put(HadithChaptersController());
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
    final bookmarked = await _bookmarkService.isBookmarked(BookmarkType.hadith, _refId);
    if (mounted) setState(() => _isBookmarked = bookmarked);
  }

  Future<void> _toggleBookmark() async {
    await _bookmarkService.toggle(
      BookmarkType.hadith,
      _refId,
      widget.bookNameInArabic,
      'Hadith book',
    );
    if (mounted) setState(() => _isBookmarked = !_isBookmarked);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Background image
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(VoidImages.details_background),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
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
                            Obx(() {
                              return Text(
                                _controller.bookNameArabic.value,
                                style: TextStyle(
                                  fontSize: 23.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }),
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
                    child: Obx(() {
                      // Show loading spinner while data is loading
                      if (_controller.isLoading.value) {
                        return Center(child: CircularProgressIndicator());
                      }

                      // Show error message if any
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

                      // If chapters data is available, display them
                      return ListView.builder(
                        itemCount: _controller.chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _controller.chapters[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: GestureDetector(
                                  onTap: () {
                                    // On tap, navigate to the HadithDetail screen, passing the chapter ID dynamically
                                    Get.to(() => HadithDetail(chapterId: chapter['id'].toString()));
                                  },
                                  child: Text(
                                    '${chapter['chapterNumber']}. ${chapter['chapterEnglish']} (${chapter['chapterUrdu']})',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: VoidColors.black,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'NotoNaskhArabic',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
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
