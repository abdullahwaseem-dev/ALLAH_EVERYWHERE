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
          _emailController.text.isNotEmpty &&
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
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occurred")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidColors.primary,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                VoidImages.logo,
                width: 200.w,
                height: 200.h,
              ),
              Transform.translate(
                offset: Offset(0, -40.h),
                child: Image.asset(
                  VoidImages.ALLAH,
                  width: 320.w,
                  height: 210.h,
                ),
              ),
              SizedBox(height: 10.h),
              buildInputField(
                'Email',
                TextInputType.emailAddress,
                _emailController,
                icon: Icons.email,
              ),
              SizedBox(height: 10.h),
              buildInputField(
                'Password',
                TextInputType.text,
                _passwordController,
                obscureText: _isPasswordObscured,
                icon: Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordObscured ? Icons.visibility : Icons
                        .visibility_off,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  },
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _keepLoggedIn,
                        onChanged: (value) {
                          setState(() {
                            _keepLoggedIn = value ?? false;
                          });
                        },
                      ),
                      Text(
                        'Keep me logged in',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.to(() => ForgetPassword());
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.pinkAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
             
              buildLoginButton(_isLoginEnabled, () {
                _loginWithEmailPassword();
              }),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.black54)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.black54)),
                ],
              ),
              SizedBox(height: 10.h),
              buildGuestButton(),
              SizedBox(height: 20.h),
              RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                  children: [
                    TextSpan(
                      text: 'Register',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.pinkAccent,
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
      ),
    );
  }
}
