import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';

import 'bottom_navbar.dart';

Widget buildInputField(
    BuildContext context,
    String label,
    TextInputType keyboardType,
    TextEditingController controller,
    {bool obscureText = false, IconData? icon, Widget? suffixIcon}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return TextField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    style: TextStyle(color: isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? VoidColors.textDarkSecondary : null),
      prefixIcon: icon != null ? Icon(icon, color: isDark ? VoidColors.textDarkSecondary : null) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      filled: true,
      fillColor: isDark ? VoidColors.cardDark : Colors.white,
    ),
  );
}

Widget buildLoginButton(BuildContext context, bool isLoginEnabled, Function onTap, {String label = 'Login'}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
  return GestureDetector(
    onTap: isLoginEnabled ? () => onTap() : null,
    child: Container(
      width: double.infinity,
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: isLoginEnabled ? accent : Colors.grey,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

Widget buildGuestButton(BuildContext context, {String label = 'Join as a Guest'}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return GestureDetector(
    onTap: () {
      Get.to(() => BottomNavBarApp());
    },
    child: Container(
      width: double.infinity,
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey),
        color: isDark ? VoidColors.cardDark : Colors.white,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? VoidColors.textDarkPrimary : Colors.black,
          ),
        ),
      ),
    ),
  );
}
