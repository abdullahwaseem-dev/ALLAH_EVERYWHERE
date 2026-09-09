import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';



class RegistrationSuccess extends StatelessWidget {
  const RegistrationSuccess({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidColors.primary,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, 130.h),
              child: Image.asset(
                VoidImages.ALLAH,
                width: 320.w,
                height: 220.h,
              ),
            ),
            const SizedBox(height: 150),
            Text(
              'Welcome To \nAllah Everywhere',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: VoidColors.black,
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'You have successfully registered, strengthening your faith journey is now easier with ALLAH Everywhere',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: VoidColors.black,
                fontSize: 16.sp,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Get.to(() =>  BottomNavBarApp());
              },
              child: Text(
                'Finish',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.pinkAccent),

                padding: MaterialStateProperty.all(
                  EdgeInsets.symmetric(
                    horizontal: 130.w,
                    vertical: 15.h,

                  ),

                ),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),

            ),
          ],
        ),
      ),
    );
  }
}
