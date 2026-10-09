import 'package:allah_everywhere/login.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class ForgetPasswordSuccess extends StatelessWidget {
  const ForgetPasswordSuccess({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey;
    return Scaffold(
      appBar: AppBar(
        title: Text('Back', style: TextStyle(color: textColor, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const VoidBackButton(),
      ),
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: ReadableWidth(child: SingleChildScrollView(
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
                      color: textColor,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'We have sent a password recover instructions to your email',
                    style: TextStyle(
                      color: subColor,
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: () {
                     Get.to(() => Login());
                    },
                    child: const Text('Back to Login', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
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
      )),
    );
  }
}