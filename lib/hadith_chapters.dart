import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'Hadith_detail.dart';
import 'controller/HadithChaptersController.dart';

class HidthChaptersScreen extends StatelessWidget {
  final String bookSlug;
  final String bookNameInArabic;

  HidthChaptersScreen({required this.bookSlug, required this.bookNameInArabic});

  final HadithChaptersController _controller = Get.put(HadithChaptersController());

  @override
  Widget build(BuildContext context) {
    // Fetch chapters when the screen is initialized
    _controller.fetchChapters(bookSlug, bookNameInArabic);

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
                            Icon(Icons.more_vert, size: 24.w, color: Colors.white),
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
                          child: Text(
                            _controller.errorMessage.value,
                            style: TextStyle(fontSize: 16.sp, color: Colors.red),
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
