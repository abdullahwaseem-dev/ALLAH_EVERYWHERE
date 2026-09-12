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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: Obx(() {
                      return Column(
                        children: [
                          Text(
                            _controller.chapterName.value,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Image.asset(
                            VoidImages.bismillah,
                            height: 30.h,
                            fit: BoxFit.contain,
                            color: Colors.white,
                          ),
                        ],
                      );
                    }),
                  ),
                  SizedBox(width: 48.w),
                ],
              ),
            ),
            // Scrollable Body
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
                          onPressed: () => _controller.fetchHadiths(widget.chapterId),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 110.h),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade700;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.08), blurRadius: 8, offset: const Offset(0, 3)),
        ],
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
                    color: subColor,
                  ),
                ),
                Text(
                  bookName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontStyle: FontStyle.italic,
                    color: subColor,
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
                color: textColor,
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(height: 8.h),
            // Urdu Text
            Text(
              urduText,
              style: TextStyle(
                fontSize: 16.sp,
                color: textColor,
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
                color: subColor,
              ),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 8.h),
            // Narration Source
            Text(
              narrationSource,
              style: TextStyle(
                fontSize: 12.sp,
                color: subColor,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}
