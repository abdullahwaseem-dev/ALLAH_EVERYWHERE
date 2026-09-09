import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class PrayerTimingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // First Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(VoidImages.details_background),
                fit: BoxFit.fill,
              ),
            ),
          ),
          // Second Background Image stacked on top of the first, starting from the middle
          Positioned(
            top: 120.h, // Start the second image from the middle of the screen using ScreenUtil
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(VoidImages.prayer_timing_background),
                  fit: BoxFit.cover, // Cover the entire screen with the second background
                ),
              ),
            ),
          ),
          // Back Button and Header
          Positioned(
            top: 40.h,
            left: 16.w,
            right: 16.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
                  onPressed: () {
                    Get.back(); // Use GetX navigation
                  },
                ),
                Column(
                  children: [
                    Text(
                      'Prayer Timing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Image.asset(
                      VoidImages.bismillah,
                      height: 30.h,
                    ),
                  ],
                ),
                SizedBox(width: 40.w), // Placeholder to balance the layout
              ],
            ),
          ),
          // Prayer Timing Content
          Positioned(
            top: 400.h, // Adjust the top padding to ensure the content starts below the header
            left: -10.w,
            right: -10.w,
            bottom: 0,
            child: SingleChildScrollView(  // Make this part scrollable
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w), // Add horizontal padding for content
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Container containing namaz timings
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w), // Added padding for inner spacing
                      decoration: BoxDecoration(
                        color: VoidColors.secondary, // Adjusted color
                        borderRadius: BorderRadius.circular(16.r), // Rounded corners for container
                      ),
                      child: Column(
                        children: [
                          PrayerTimingRow(time: '06:06', label: 'Fajr'),
                          PrayerTimingRow(time: '12:19', label: 'Zohar'),
                          PrayerTimingRow(time: '04:24', label: 'Asr'),
                          PrayerTimingRow(time: '06:12', label: 'Maghrib'),
                          PrayerTimingRow(time: '07:19', label: 'Isha'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrayerTimingRow extends StatelessWidget {
  final String time;
  final String label;
  final ValueNotifier<bool> isChecked = ValueNotifier(false);  // Track checkbox state

  PrayerTimingRow({required this.time, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.h), // Use ScreenUtil for vertical padding
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w), // Padding for the container
        decoration: BoxDecoration(
          color: Colors.white, // White background for the prayer boxes
          borderRadius: BorderRadius.circular(12.r), // Rounded corners for the box
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: 16.sp), // Black text for the label
            ),
            Row(
              children: [
                Text(
                  time,
                  style: TextStyle(color: Colors.black, fontSize: 16.sp), // Black text for the time
                ),
                IconButton(
                  icon: Icon(Icons.volume_up, color: Colors.black), // Black icon color
                  onPressed: () {
                    // Add your logic to play sound here
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: isChecked,
                  builder: (context, checked, child) {
                    return Checkbox(
                      value: checked,
                      onChanged: (bool? value) {
                        if (value != null) {
                          isChecked.value = value;  // Update the checkbox state
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
