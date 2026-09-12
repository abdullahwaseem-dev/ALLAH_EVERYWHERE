import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/widgets/themed_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/controllers/prayer_times_controller.dart';

class PrayerTimingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Shares state with Home via Get.put/Get.find so both screens always
    // agree on the same computed times.
    final controller = Get.isRegistered<PrayerTimesController>()
        ? Get.find<PrayerTimesController>()
        : Get.put(PrayerTimesController());

    return Scaffold(
      body: Stack(
        children: [
          ThemedBackground(lightImagePath: VoidImages.details_background, fit: BoxFit.fill),
          Positioned(
            top: 120.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: ThemedBackground(lightImagePath: VoidImages.prayer_timing_background, fit: BoxFit.cover),
          ),
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
                    Get.back();
                  },
                ),
                Column(
                  children: [
                    Text(
                      'Prayer Timing',
                      style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Image.asset(VoidImages.bismillah, height: 30.h),
                  ],
                ),
                SizedBox(width: 40.w),
              ],
            ),
          ),
          Positioned(
            top: 400.h,
            left: -10.w,
            right: -10.w,
            bottom: 0,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: VoidColors.secondary,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Obx(() {
                        if (controller.locationError.value.isNotEmpty) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: Text(
                              controller.locationError.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            PrayerTimingRow(time: controller.fajrTime.value, label: 'Fajr'),
                            PrayerTimingRow(time: controller.dhuhrTime.value, label: 'Dhuhr'),
                            PrayerTimingRow(time: controller.asrTime.value, label: 'Asr'),
                            PrayerTimingRow(time: controller.maghribTime.value, label: 'Maghrib'),
                            PrayerTimingRow(time: controller.ishaTime.value, label: 'Isha'),
                          ],
                        );
                      }),
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
  final ValueNotifier<bool> isChecked = ValueNotifier(false);

  PrayerTimingRow({required this.time, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.h),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.black, fontSize: 16.sp)),
            Row(
              children: [
                Text(time, style: TextStyle(color: Colors.black, fontSize: 16.sp)),
                SizedBox(width: 8.w),
                ValueListenableBuilder<bool>(
                  valueListenable: isChecked,
                  builder: (context, checked, child) {
                    return Checkbox(
                      value: checked,
                      onChanged: (bool? value) {
                        if (value != null) {
                          isChecked.value = value;
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
