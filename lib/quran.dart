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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Quran',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              VoidImages.quran_background,
              fit: BoxFit.fill,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 48.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Last Read Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(VoidImages.quran_banner),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            children: [
                              Text(
                                'Last Read',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: VoidColors.white,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Obx(() {
                                if (controller.isLoading.value) {
                                  return Text('Loading...');
                                }
                                return Text(
                                  controller.lastReadSurahName.value.isNotEmpty
                                      ? controller.lastReadSurahName.value
                                      : 'الفاتحة',
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: VoidColors.white,
                                  ),
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
                                  backgroundColor: VoidColors.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 14.sp,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Image.asset(
                          VoidImages.quran_majeed,
                          height: 150.h,
                          width: 150.w,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: Color(0XFF9B9A99),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: TextField(
                                  onChanged: (query) {
                                    controller.searchSurah(query); // Call search on change
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Search For Quran',
                                    hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return Colors.black12;
                                  }
                                  return VoidColors.white;
                                }),
                                elevation: MaterialStateProperty.all(2),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(

                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 12.h),
                                  child: Text(
                                    'SURAH',
                                    style: TextStyle(fontSize: 14.sp, color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black12,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 12.h),
                                    child: Text(
                                      'Play',
                                      style: TextStyle(fontSize: 14.sp, color: Colors.black),
                                    ),
                                  ),
                                )

                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Surah List
                  Obx(() {
                    if (controller.isLoading.value) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: controller.filteredSurahList.length,
                      itemBuilder: (context, index) {
                        final surah = controller.filteredSurahList[index];

                        return GestureDetector(
                          onTap: () {
                            // Update the last read Surah
                            controller.updateLastReadSurah(surah['surahName'], index + 1, 1);

                            // Navigate to the selected Surah page
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
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSurahTile(String surahName, String arabicName, String translation, String totalAyah, int serialNumber) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: Color(0XFF9B9A99),
                child: Text(
                  '$serialNumber',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surahName,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    Text(
                      translation + ' (' + totalAyah + ')',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
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
                    color: Colors.black,
                    fontFamily: 'NotoNaskhArabic',
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          thickness: 1.h,
          color: Colors.grey[400],
          height: 16.h,
        ),
      ],
    );
  }
}

