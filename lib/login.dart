import 'package:allah_everywhere/registration.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/widgets/bottom_navbar.dart';
import 'package:allah_everywhere/widgets/login_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'forget_password.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:allah_everywhere/utils/utils/validators/validate.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _keepLoggedIn = false;
  bool _isLoginEnabled = false;
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateLoginButtonState);
    _passwordController.addListener(_updateLoginButtonState);


    _checkLoginStatus();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateLoginButtonState() {
    setState(() {
      _isLoginEnabled =
          VoidValidator.validateEmail(_emailController.text) == null &&
              _passwordController.text.isNotEmpty;
    });
  }

  // Check if the user is logged in automatically
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? keepLoggedIn = prefs.getBool('keepLoggedIn');
    String? uid = prefs.getString('uid');

    if (keepLoggedIn == true && uid != null) {
      // If "Keep me logged in" is true and UID exists, directly go to the app home screen
      Get.to(() => BottomNavBarApp());
    }
  }

  Future<void> _loginWithEmailPassword() async {
    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      // Firebase authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('uid', userCredential.user!.uid);

      await prefs.setBool('keepLoggedIn', _keepLoggedIn);

      Get.to(() => BottomNavBarApp());
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred during login.";

      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No user found for that email.";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password.";
          break;
        case 'invalid-email':
          errorMessage = "The email address is not valid.";
          break;
        default:
          errorMessage = "An error occurred. Please try again.";
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)));
    } catch (e) {
      VoidLogger.error('Login failed', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occurred")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: ReadableWidth(child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                VoidImages.logo,
                width: 200.w,
                height: 200.h,
                color: isDark ? Colors.white : null,
              ),
              Transform.translate(
                offset: Offset(0, -40.h),
                child: Image.asset(
                  VoidImages.ALLAH,
                  width: 320.w,
                  height: 210.h,
                  color: isDark ? Colors.white : null,
                ),
              ),
              SizedBox(height: 10.h),
              buildInputField(
                context,
                t.email,
                TextInputType.emailAddress,
                _emailController,
                icon: Icons.email,
              ),
              SizedBox(height: 10.h),
              buildInputField(
                context,
                t.password,
                TextInputType.text,
                _passwordController,
                obscureText: _isPasswordObscured,
                icon: Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordObscured ? Icons.visibility : Icons
                        .visibility_off,
                    color: subColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  },
                ),
              ),
              SizedBox(height: 20.h),
              // Wrap, not Row: on iPhone SE / large text both don't fit on
              // one line, so "Forgot password" moves below instead of
              // overflowing.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _keepLoggedIn,
                        activeColor: accent,
                        onChanged: (value) {
                          setState(() {
                            _keepLoggedIn = value ?? false;
                          });
                        },
                      ),
                      Text(
                        t.keepMeLoggedIn,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.to(() => ForgetPassword());
                    },
                    child: Text(
                      t.forgotPassword,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: accent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              buildLoginButton(context, _isLoginEnabled, () {
                _loginWithEmailPassword();
              }, label: t.loginTitle),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(child: Divider(color: subColor)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      t.or,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: subColor,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: subColor)),
                ],
              ),
              SizedBox(height: 10.h),
              buildGuestButton(context, label: t.joinAsGuest),
              SizedBox(height: 20.h),
              RichText(
                text: TextSpan(
                  text: t.dontHaveAccount,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: textColor,
                  ),
                  children: [
                    TextSpan(
                      text: t.register,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Get.to(() => RegisterScreen());
                        },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      )),
    );
  }
}
