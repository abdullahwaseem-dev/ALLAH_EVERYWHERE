import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/services/reading_stats_service.dart';


import 'controller/HadithDetailController.dart';

class HadithDetail extends StatefulWidget {
  final String chapterId;
  const HadithDetail({Key? key, required this.chapterId}) : super(key: key);

  @override
  State<HadithDetail> createState() => _HadithDetailState();
}

class _HadithDetailState extends State<HadithDetail> {
  final HadithDetailController _controller = Get.put(HadithDetailController());

  @override
  void initState() {
    super.initState();
    _controller.fetchHadiths(widget.chapterId);
    ReadingStatsService().incrementHadithRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(VoidImages.details_background),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 30.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                      Obx(() {
                        return Column(
                          children: [
                            Text(
                              _controller.chapterName.value,  // Dynamically show chapter name
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Image.asset(
                              VoidImages.bismillah,
                              height: 40.h,
                              fit: BoxFit.contain,
                            ),
                          ],
                        );
                      }),
                      SizedBox(width: 48.w),
                    ],
                  ),
                ),
                // Scrollable Body
                Expanded(
                  child: Obx(() {
                    if (_controller.isLoading.value) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (_controller.errorMessage.isNotEmpty) {
                      return Center(
                        child: Text(
                          _controller.errorMessage.value,
                          style: TextStyle(fontSize: 16.sp, color: Colors.red),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(_controller.hadithData.length, (index) {
                          final hadith = _controller.hadithData[index];
                          return HadithCard(
                            arabicText: hadith['hadithArabic'] ?? '',
                            urduText: hadith['hadithUrdu'] ?? '',
                            englishText: hadith['hadithEnglish'] ?? '',
                            hadithNumber: hadith['hadithNumber'].toString(),
                            bookName: hadith['book']['bookName'] ?? 'Unknown Book',
                            narrationSource: hadith['urduNarrator'] ?? 'Unknown Narrator',
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class HadithCard extends StatelessWidget {
  final String arabicText;
  final String urduText;
  final String englishText;
  final String hadithNumber;
  final String bookName;
  final String narrationSource;

  const HadithCard({
    required this.arabicText,
    required this.urduText,
    required this.englishText,
    required this.hadithNumber,
    required this.bookName,
    required this.narrationSource,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: VoidColors.secondary.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hadith #$hadithNumber',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    bookName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              // Arabic Text
              Text(
                arabicText,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 8.h),
              // Urdu Text
              Text(
                urduText,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 8.h),
              // English Text
              Text(
                englishText,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 8.h),
              // Narration Source
              Text(
                narrationSource,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }
}