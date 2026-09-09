
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class FormSection extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isChecked;
  final ValueChanged<bool?> onCheckboxChanged;
  final ValueChanged<String> onTextChanged;

  const FormSection({
    Key? key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isChecked,
    required this.onCheckboxChanged,
    required this.onTextChanged,
  }) : super(key: key);

  @override
  _FormSectionState createState() => _FormSectionState();
}

class _FormSectionState extends State<FormSection> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _checkFormValidity() {
    widget.onTextChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        TextField(
          controller: widget.emailController,
          decoration: InputDecoration(
            labelText: "Email",
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          onChanged: (value) => _checkFormValidity(),
        ),
        SizedBox(height: 20.h),
        // Password Text Field
        TextField(
          controller: widget.passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: "Password",
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          onChanged: (value) => _checkFormValidity(),
        ),
        SizedBox(height: 20.h),

        TextField(
          controller: widget.confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            labelText: "Confirm Password",
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          onChanged: (value) => _checkFormValidity(),
        ),
        SizedBox(height: 20.h),
        // Terms and Conditions Checkbox
        Row(
          children: [
            Checkbox(
              value: widget.isChecked,
              onChanged: widget.onCheckboxChanged,
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: "I agree to ",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: "Terms of Service",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.pinkAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: " and "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.pinkAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
