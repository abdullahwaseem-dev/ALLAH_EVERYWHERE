import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_outlined, color: textColor),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: Text(
                      'Prayer Timing',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textColor, fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 48.w),
                ],
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [VoidColors.cardDark, VoidColors.oliveDeep]
                        : [VoidColors.oliveDeep, VoidColors.dustyRose],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                alignment: Alignment.center,
                child: Image.asset(VoidImages.bismillah, height: 30.h, color: Colors.white),
              ),
              SizedBox(height: 20.h),
              Obx(() {
                if (controller.locationError.value.isNotEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Text(
                      controller.locationError.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: textColor),
                    ),
                  );
                }
                return Column(
                  children: [
                    PrayerTimingRow(time: controller.fajrTime.value, label: 'Fajr', isDark: isDark, accent: accent),
                    PrayerTimingRow(time: controller.dhuhrTime.value, label: 'Dhuhr', isDark: isDark, accent: accent),
                    PrayerTimingRow(time: controller.asrTime.value, label: 'Asr', isDark: isDark, accent: accent),
                    PrayerTimingRow(time: controller.maghribTime.value, label: 'Maghrib', isDark: isDark, accent: accent),
                    PrayerTimingRow(time: controller.ishaTime.value, label: 'Isha', isDark: isDark, accent: accent),
                  ],
                );
              }),
              SizedBox(height: 110.h),
            ],
          ),
        ),
      ),
    );
  }
}

class PrayerTimingRow extends StatelessWidget {
  final String time;
  final String label;
  final bool isDark;
  final Color accent;
  final ValueNotifier<bool> isChecked = ValueNotifier(false);

  PrayerTimingRow({required this.time, required this.label, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.0.h),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: textColor, fontSize: 15.sp, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text(time, style: TextStyle(color: textColor, fontSize: 15.sp, fontWeight: FontWeight.w600)),
                SizedBox(width: 4.w),
                ValueListenableBuilder<bool>(
                  valueListenable: isChecked,
                  builder: (context, checked, child) {
                    return Checkbox(
                      value: checked,
                      activeColor: accent,
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
