import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';



class RegistrationSuccess extends StatelessWidget {
  const RegistrationSuccess({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
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
                color: isDark ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 150),
            Text(
              t.welcomeTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.registrationSuccessMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 16.sp,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Get.to(() =>  BottomNavBarApp());
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(accent),
                padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(
                    horizontal: 130.w,
                    vertical: 15.h,
                  ),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
              child: Text(
                t.finish,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
