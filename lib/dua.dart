import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:get/get.dart';
import 'ask_ai.dart';
import 'data/dua_data.dart';
import 'dua_2.dart';

class DuaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidColors.secondary,
      appBar: AppBar(
        backgroundColor: VoidColors.brown,
        title: Text("Dua", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19.sp)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: VoidColors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Stack(
            children: [
              Image.asset(VoidImages.hands_dua, width: double.infinity, fit: BoxFit.cover, height: 180.h),
              Container(
                width: double.infinity,
                height: 180.h,
                child: Image.asset(VoidImages.overlay, width: double.infinity, fit: BoxFit.cover, height: 180.h),
              ),
              Positioned(
                bottom: 10.h,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 95.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    children: [
                      buildCard("Guidance and Righteousness",
                          "O Allah, guide me, make me steadfast, and set my affairs right."),
                      buildCard("Forgiveness", "O Allah, You are the Most Forgiving, so forgive me."),
                      buildCard("Gratitude", "O Allah, I thank You for Your countless blessings."),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Icon Menu Section
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: Container(
              padding: EdgeInsets.all(11.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8.r, offset: Offset(0, 2)),
                ],
              ),
              child: Center(
                child: GestureDetector(
                  onTap: () => Get.to(() => AskAiScreen(initialCategory: 'Dua')),
                  child: buildIconMenuItem(VoidImages.Question, "Ask AI about a Dua"),
                ),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("All Duas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final category in duaCategories)
                          GestureDetector(
                            onTap: () => Get.to(() => Dua2Screen(category: category)),
                            child: buildDuaCard(title: category.title, duaCount: category.duas.length),
                          ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard(String title, String subtitle) {
    return Container(
      width: 300.w,
      margin: EdgeInsets.only(right: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8.r, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[700], fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget buildIconMenuItem(String iconPath, String title) {
    return Column(
      children: [
        Image.asset(iconPath, height: 25.h, width: 35.w),
        SizedBox(height: 8.h),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
      ],
    );
  }

  Widget buildDuaCard({required String title, required int duaCount}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6.r, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp)),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("$duaCount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
                    Text("Duas", style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
                  ],
                ),
                SizedBox(width: 8.w),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
