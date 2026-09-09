
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ButtonsSection extends StatelessWidget {
  final bool isFormValid;
  final VoidCallback onRegisterPressed;
  final VoidCallback onJoinAsGuestPressed;

  const ButtonsSection({
    Key? key,
    required this.isFormValid,
    required this.onRegisterPressed,
    required this.onJoinAsGuestPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isFormValid ? onRegisterPressed : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15.h),
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            child: Text(
              "Register",
              style: TextStyle(fontSize: 16.sp, color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        // Join as Guest Button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onJoinAsGuestPressed,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 15.h),
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            child: Text(
              "Join as a Guest",
              style: TextStyle(fontSize: 16.sp),
            ),
          ),
        ),
      ],
    );
  }
}
