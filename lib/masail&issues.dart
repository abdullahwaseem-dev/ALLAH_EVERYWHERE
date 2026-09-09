import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class MasailAndIssues extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(VoidImages.details_background),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Positioned(
            top: 40.h,
            left: 16.w,
            right: 16.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
                  onPressed: () {
                    Get.back(); // Use GetX navigation
                  },
                ),
                Column(
                  children: [
                    Text(
                      'Issues(Masial)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Image.asset(
                      VoidImages.bismillah,
                      height: 30.h,
                    ),
                  ],
                ),
                SizedBox(width: 40.w), // Placeholder to balance the layout
              ],
            ),
          ),
          Center(
            child: Container(
              width: 300.w, // Adjust width
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Color(0xFFECC3B1),
                borderRadius: BorderRadius.circular(12.w),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add your Issues',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: TextField(
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Write Your Questions',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFCCAEA2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.w),
                      ),
                    ),
                    child: Text('Submit',style: TextStyle(color: VoidColors.white),),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
