import 'package:allah_everywhere/login.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';

class ForgetPasswordSuccess extends StatelessWidget {
  const ForgetPasswordSuccess({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Back', style: TextStyle(color: VoidColors.black, fontSize: 18)),
        backgroundColor: VoidColors.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: VoidColors.black),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      backgroundColor: VoidColors.primary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 100.h),
                  Image.asset(
                    VoidImages.email,
                    width: 200.w,
                    height: 200.h,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Check Your Mail',
                    style: TextStyle(
                      color: VoidColors.black,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'We have sent a password recover instructions to your email',
                    style: TextStyle(
                      color: VoidColors.black,
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: () {
                     Get.to(() => Login());
                    },
                    child: Text('Back to Login',style: TextStyle(color: VoidColors.white),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VoidColors.pink,
                      minimumSize: Size(300.w, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
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