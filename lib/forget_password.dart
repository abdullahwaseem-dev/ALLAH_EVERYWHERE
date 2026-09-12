import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Firebase import

import 'forget_password_success.dart';
import 'package:allah_everywhere/utils/utils/validators/validate.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({Key? key}) : super(key: key);

  @override
  _ForgetPasswordState createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  // Declare a TextEditingController for email input
  final TextEditingController _emailController = TextEditingController();
  bool _isButtonEnabled = false;

  // FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    // Add listener to enable/disable the button based on email input
    _emailController.addListener(() {
      setState(() {
        _isButtonEnabled = VoidValidator.validateEmail(_emailController.text) == null;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Function to send password reset email using Firebase
  Future<void> _sendPasswordResetEmail() async {
    try {
      // Send the password reset email
      await _auth.sendPasswordResetEmail(email: _emailController.text);

      // Navigate to success screen on successful email send
      Get.to(ForgetPasswordSuccess());
    } on FirebaseAuthException catch (e) {
      // Handle errors like user not found or invalid email
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'An error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey;
    return Scaffold(
      appBar: AppBar(
        title: Text('Back', style: TextStyle(color: textColor, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: textColor),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: SingleChildScrollView( // Make the body scrollable
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 20.0), // Adjust padding to reduce distance
              child: Image.asset(
                VoidImages.forget_pass,
                height: 200.h,
                width: 200.w,
              ),
            ),
            Text(
              t.forgotPassword,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10), // Reduced space between image and text
            Text(
              t.forgotPasswordDescription,
              style: TextStyle(
                fontSize: 16,
                color: subColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  // Email TextField with border and validation
                  TextField(
                    controller: _emailController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: t.email,
                      hintStyle: TextStyle(color: subColor),
                      filled: true,
                      fillColor: isDark ? VoidColors.cardDark : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: subColor, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Send Button that is disabled until a valid email is entered
                  ElevatedButton(
                    onPressed: _isButtonEnabled
                        ? () {
                      _sendPasswordResetEmail(); // Trigger password reset
                    }
                        : null,
                    child: Text(
                      t.send,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          _isButtonEnabled ? accent : Colors.grey),
                      padding: WidgetStateProperty.all(
                          EdgeInsets.symmetric(vertical: 15, horizontal: 150)),
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      )),
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
