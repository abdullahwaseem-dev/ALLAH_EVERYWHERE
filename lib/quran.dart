import 'package:allah_everywhere/surah.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'controller/QuranController.dart';

class QuranScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final QuranController controller = Get.put(QuranController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: textColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Quran',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Last Read Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last Read',
                            style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                          ),
                          SizedBox(height: 4.h),
                          Obx(() {
                            if (controller.isLoading.value) {
                              return Text('Loading...', style: TextStyle(color: Colors.white));
                            }
                            return Text(
                              controller.lastReadSurahName.value.isNotEmpty
                                  ? controller.lastReadSurahName.value
                                  : 'الفاتحة',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }),
                          SizedBox(height: 8.h),
                          ElevatedButton(
                            onPressed: () {
                              Get.to(() => SurahScreen(
                                    surahName: controller.lastReadSurahName.value,
                                    surahId: controller.lastReadSurahId.value,
                                  ));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Continue', style: TextStyle(fontSize: 12.sp, color: Colors.white)),
                                Icon(Icons.arrow_forward, size: 14.sp, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(VoidImages.quran_majeed, height: 100.h, width: 100.w, fit: BoxFit.contain),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: TextField(
                  onChanged: (query) => controller.searchSurah(query),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: subColor),
                    hintText: 'Search For Quran',
                    hintStyle: TextStyle(fontSize: 14.sp, color: subColor),
                  ),
                ),
              ),
              SizedBox(height: 8.h),

              // Surah List
              Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: CircularProgressIndicator(color: accent));
                }

                if (controller.errorMessage.isNotEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Column(
                      children: [
                        Text(
                          controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.sp, color: Colors.red),
                        ),
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: controller.fetchSurahs,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: controller.filteredSurahList.length,
                  itemBuilder: (context, index) {
                    final surah = controller.filteredSurahList[index];

                    return GestureDetector(
                      onTap: () {
                        controller.updateLastReadSurah(surah['surahName'], index + 1, 1);
                        Get.to(() => SurahScreen(
                              surahName: surah['surahName'],
                              surahId: index + 1,
                            ));
                      },
                      child: buildSurahTile(
                        surah['surahName']!,
                        surah['surahNameArabic']!,
                        surah['surahNameTranslation']!,
                        surah['totalAyah'].toString(),
                        index + 1,
                        isDark,
                        accent,
                        textColor,
                        subColor,
                      ),
                    );
                  },
                );
              }),
              SizedBox(height: 110.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSurahTile(
    String surahName,
    String arabicName,
    String translation,
    String totalAyah,
    int serialNumber,
    bool isDark,
    Color accent,
    Color textColor,
    Color subColor,
  ) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: accent.withOpacity(isDark ? 0.25 : 0.14),
                child: Text(
                  '$serialNumber',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: accent),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surahName,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Text(
                      '$translation ($totalAyah)',
                      style: TextStyle(fontSize: 12.sp, color: subColor),
                    ),
                  ],
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  arabicName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'NotoNaskhArabic',
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          thickness: 1.h,
          color: textColor.withOpacity(0.08),
          height: 16.h,
        ),
      ],
    );
  }
}
