import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';

class AboutUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'About Us',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(VoidImages.otherscreen_background),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 50.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading
                Text(
                  'The Developer',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  'Allah Everywhere is built and maintained by a single solo developer - Muhammad Abdullah Waseem. There is no company or team behind it: every feature, every line of code, and every bit of content in this app is his own work.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 30.h),
                Text(
                  'Our Mission',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  'This app exists to ease the journey of Muslims in learning, reflecting, and growing as better Muslims. Its purpose is to make my Akhirah (Hereafter) better. It is built as a form of Sadaqah Jariyah, where your benefit is my reward, and you will never be interrupted by ads or any distractions. There are no materialistic intentions here - only a request for your prayers.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 30.h),
                // History of the app
                Text(
                  'App History',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  'This app was a dream I had back in 2021. Due to limited resources and knowledge, I was unable to bring it to life at that time. But by the grace of Allah, I continued pursuing this dream, and now, Alhamdulillah, this app is finally here for you to benefit from.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 40.h),
                // Sher in Urdu
                Center(
                  child: Text(
                    'دین کی خدمت وہ ہے جس سے انسانیت کو فائدہ ہو، اور انسان کا بہترین عمل وہ ہے جو اس کی آخرت کے لیے بہتر ہو۔',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 30.h),
                // Footer text
                Text(
                  'Alhamdulillah, I have come this far, and it’s all because of Allah’s blessing. May He accept this effort and make this app a means of guidance for everyone.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
