import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DuaDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidColors.secondary,
      appBar: AppBar(
        toolbarHeight: 60.h,
        backgroundColor: VoidColors.brown,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: VoidColors.black,
            size: 20.sp,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Clothes',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       // Placeholder for additional action, like sharing or saving
        //     },
        //     icon: Icon(
        //       Icons.more_vert,
        //       color: VoidColors.black,
        //       size: 20.sp,
        //     ),
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "2/4",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: Colors.black12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Dua Title
            Text(
              "When wearing new clothes",
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20.h),

            // Arabic Text
            Text(
              "اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ كَسَوْتَنِيهِ، أَسْأَلُكَ مِنْ خَيْرِهِ وَخَيْرِ مَا صُنِعَ لَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّهِ وَشَرِّ مَا صُنِعَ لَهُ",
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            SizedBox(height: 20.h),

            // Transliteration
            Text(
              "Allahumma laka-l-hamdu Anta kasawtanh, as’aluka min khayrihi wa khayri ma suni’a lah, wa a’udhu bika min sharrihi wa sharri ma suni’a lah.",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            SizedBox(height: 20.h),

            // Translation
            Text(
              "O Allah, all praise is for You alone – You have clothed me with it. I ask You for its good and the good of that for which it was made; and I seek Your protection from its evil and the evil of that for which it was made.",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            SizedBox(height: 30.h),

            // Reference Section
            Container(
              padding: EdgeInsets.all(16.0), // Increased padding for a more spacious look
              decoration: BoxDecoration(
                color: Colors.grey.shade100, // Matches the light beige background
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reference Header
                  Text(
                    "Reference",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Text(
                    "Abu Sa'id al-Khudri (radiy Allāhu 'anhu) reported that when the Messenger of Allah (ﷺ) wore a new garment he would name it: either a turban, a shirt, or a cloak; and then he would say [the above].",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Hadith Reference Row
                  Row(
                    children: [
                      Icon(
                        Icons.book,
                        color: VoidColors.brown,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Hadith • Tirmidhi 1767",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: VoidColors.brown,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
