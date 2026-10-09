import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'login.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({required this.icon, required this.title, required this.description});
}

const List<_OnboardingPage> _pages = [
  _OnboardingPage(
    icon: Iconsax.book_saved,
    title: 'Quran & Hadith',
    description: 'Read the Quran and explore authentic Hadith collections, all in one place.',
  ),
  _OnboardingPage(
    icon: Iconsax.clock,
    title: 'Prayer Times & Reminders',
    description: 'Get accurate prayer times for your location, with notifications so you never miss a prayer.',
  ),
  _OnboardingPage(
    icon: Iconsax.discover,
    title: 'Qibla Compass',
    description: 'Find the direction of the Kaaba wherever you are, using your device\'s compass and location.',
  ),
  _OnboardingPage(
    icon: Iconsax.message_question,
    title: 'Ask AI',
    description: 'Ask questions about Islam and get answers grounded in the Quran and authentic Hadith.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _finish() {
    Get.offAll(() => Login());
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      _finish();
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: ReadableWidth(child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(right: 16.w, top: 8.h),
                child: TextButton(
                  onPressed: _finish,
                  child: Text('Skip', style: TextStyle(fontSize: 13.5.sp, color: subColor)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(28.w),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 56.sp, color: accent),
                        ),
                        SizedBox(height: 32.h),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.sp, color: subColor, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: isActive ? 20.w : 7.w,
                  height: 7.h,
                  decoration: BoxDecoration(
                    color: isActive ? accent : accent.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                );
              }),
            ),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  onPressed: _next,
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
