
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';

class FormSection extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isChecked;
  final ValueChanged<bool?> onCheckboxChanged;
  final ValueChanged<String> onTextChanged;
  final String? errorText;

  const FormSection({
    Key? key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isChecked,
    required this.onCheckboxChanged,
    required this.onTextChanged,
    this.errorText,
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
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        TextField(
          controller: widget.emailController,
          decoration: InputDecoration(
            labelText: t.email,
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
            labelText: t.password,
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
            labelText: t.confirmPassword,
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
        if (widget.errorText != null) ...[
          SizedBox(height: 8.h),
          Text(
            widget.errorText!,
            style: TextStyle(color: Colors.red, fontSize: 12.sp),
          ),
        ],
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
                  text: t.agreeToTermsPrefix,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: t.termsOfService,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.pinkAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: ' ${t.and} '),
                    TextSpan(
                      text: t.privacyPolicy,
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
