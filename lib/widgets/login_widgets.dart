import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'bottom_navbar.dart';

Widget buildInputField(
    String label,
    TextInputType keyboardType,
    TextEditingController controller,
    {bool obscureText = false, IconData? icon, Widget? suffixIcon}) {
  return TextField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}

Widget buildLoginButton(bool isLoginEnabled, Function onTap) {
  return GestureDetector(
    onTap: isLoginEnabled ? () => onTap() : null,
    child: Container(
      width: double.infinity,
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: isLoginEnabled ? Colors.pinkAccent : Colors.grey,
      ),
      child: Center(
        child: Text(
          'Login',
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

Widget buildGuestButton() {
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
        color: Colors.white,
      ),
      child: Center(
        child: Text(
          'Join as a Guest',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    ),
  );
}
