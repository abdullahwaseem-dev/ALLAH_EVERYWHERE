import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        leading: const VoidBackButton(),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? VoidColors.bgDark : VoidColors.bgLight,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Heading
                Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  'At Allah Everywhere, we value your privacy. This policy explains what data the app actually collects and why, and who it is shared with. We do not sell your data. The app shows a small banner ad and uses an AI model to answer Ask AI questions, both of which involve limited data sharing described below.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 30.h),
                Text(
                  'What We Collect',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  '• Account data: your email address and display name, via Firebase Authentication.\n'
                  '• Profile data stored in Firebase Cloud Firestore: your name, optional profile picture (Firebase Storage), reading/Tasbeeh activity counters, and questions you ask in Ask AI (with the AI-generated answers).\n'
                  '• Ask AI questions: the text you type is sent to Google\'s Gemini API to generate an answer. Do not include sensitive personal information in your questions.\n'
                  '• Advertising data: the app shows a small banner ad using Google Mobile Ads (AdMob), which collects an advertising identifier, approximate (IP-based) location, and device information to show and measure ads. You can reset or limit this identifier in your device\'s system settings.\n'
                  '• Device location: used only on-device to calculate accurate prayer times and Qibla direction. We do not store a history of your locations.\n'
                  '• Push notification token: stored so we can deliver in-app notifications to your device via Firebase Cloud Messaging.\n'
                  '• Crash and error reports: sent to Firebase Crashlytics to help us fix bugs.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 30.h),
                Text(
                  'Third-Party Services',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  'Quran text is fetched from a public Quran API, and Hadith text from hadithapi.com. These requests include only the passage being viewed, not your identity. Nearby mosque lookups use the public OpenStreetMap Overpass API with your current coordinates, sent directly from your device. Ask AI questions are sent to Google\'s Gemini API to generate a response. The app displays ads via Google Mobile Ads (AdMob), which may use your advertising identifier and approximate location to select and measure ads.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 30.h),
                Text(
                  'Your Choices',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  'You can use the app as a guest without creating an account, though some features (saved Ask AI history, synced counters) require signing in. You can delete your account and associated profile data at any time from Settings > Delete Account.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 40.h),
                Text(
                  'By using this app, you agree to the collection and use of information as described above. If you have questions, please contact us.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
