import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';

class MosqueCardWidget extends StatelessWidget {
  final String name;
  final String location;
  final String imagePath;
  final VoidCallback? onTap;

  const MosqueCardWidget({
    Key? key,
    required this.name,
    required this.location,
    required this.imagePath,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 170.w,
      margin: EdgeInsets.only(right: 10.w),
      decoration: BoxDecoration(
        color: VoidColors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: VoidColors.white),
        boxShadow: [
          BoxShadow(
            color: VoidColors.white.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            child: Image.asset(
              imagePath,
              height: 100.h,
              fit: BoxFit.fill,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16.sp,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey,
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
