import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'controllers/splash_screen_controller.dart';
import 'login.dart';
import 'onboarding.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _onboardingSeenKey = 'has_seen_onboarding';

  late SplashScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SplashScreenController(vsync: this);
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final hasSeenOnboarding = VoidStorage().readData<bool>(_onboardingSeenKey) ?? false;
      if (hasSeenOnboarding) {
        Get.to(() => Login());
      } else {
        VoidStorage().saveData(_onboardingSeenKey, true);
        Get.to(() => const OnboardingScreen());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: VoidColors.primary,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              VoidImages.blur_top,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              VoidImages.blur_bottom,
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  VoidImages.logo,
                  width: 350.w,
                  height: 350.h,
                ),
                SizedBox(height: 20.h),
                // Dots loading animation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _controller.buildDot(0),
                    SizedBox(width: 8),
                    _controller.buildDot(1),
                    SizedBox(width: 8),
                    _controller.buildDot(2),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
