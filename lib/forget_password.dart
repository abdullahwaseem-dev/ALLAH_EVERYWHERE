import 'package:allah_everywhere/registration_success.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Firebase import

import 'forget_password_success.dart'; // for text validation

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

  // Function to validate the email format containing "@gmail.com"
  bool _isValidEmail(String email) {
    return email.contains('@gmail.com');
  }

  @override
  void initState() {
    super.initState();

    // Add listener to enable/disable the button based on email input
    _emailController.addListener(() {
      setState(() {
        _isButtonEnabled = _isValidEmail(_emailController.text);
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
            const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10), // Reduced space between image and text
            const Text(
              'Don’t worry! It happens. Please enter the email associated with your account.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
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
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey, width: 1.5),
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
                      'Send',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          _isButtonEnabled ? Colors.pinkAccent : Colors.grey),
                      padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(vertical: 15, horizontal: 150)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
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
