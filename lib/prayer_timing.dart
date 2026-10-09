import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/data/prayer_reminders_data.dart';
import 'package:allah_everywhere/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:allah_everywhere/controllers/prayer_times_controller.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class PrayerTimingScreen extends StatelessWidget {
  const PrayerTimingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Shares state with Home via Get.put/Get.find so both screens always
    // agree on the same computed times.
    final controller = Get.isRegistered<PrayerTimesController>()
        ? Get.find<PrayerTimesController>()
        : Get.put(PrayerTimesController(), permanent: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    // Stable "reminder of the day" - changes daily rather than on every
    // rebuild, so it doesn't flicker as the countdown ticks each second.
    final reminder = prayerReminders[DateTime.now().day % prayerReminders.length];

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: ReadableWidth(child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  VoidBackButton(),
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
              SizedBox(height: 12.h),

              // Hero card - live countdown to the next prayer.
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [VoidColors.cardDark, VoidColors.oliveDeep]
                        : [VoidColors.oliveDeep, VoidColors.dustyRose],
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Obx(() {
                  if (controller.locationError.value.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(controller.locationError.value, style: TextStyle(fontSize: 13.sp, color: Colors.white)),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: controller.fetchLocationAndTimes,
                          child: Text(
                            'Retry',
                            style: TextStyle(fontSize: 13.sp, color: VoidColors.goldDark, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Iconsax.location, size: 13.sp, color: Colors.white70),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              controller.location.value,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        'Time for',
                        style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        controller.nextPrayerName.value.isEmpty ? '...' : controller.nextPrayerName.value,
                        style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Iconsax.timer_1, size: 14.sp, color: VoidColors.goldDark),
                          SizedBox(width: 6.w),
                          // Own Obx so the per-second tick rebuilds only this.
                          Obx(() => Text(
                                'in ${controller.remainingTime.value}',
                                style: TextStyle(color: VoidColors.goldDark, fontSize: 14.sp, fontWeight: FontWeight.w700),
                              )),
                          const Spacer(),
                          Text(
                            controller.nextPrayerTime.value,
                            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Icon(Iconsax.calendar_1, size: 13.sp, color: Colors.white70),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              '${controller.islamicDate.value.isEmpty ? '...' : controller.islamicDate.value} · ${controller.gregorianDate.value}',
                              style: TextStyle(color: Colors.white, fontSize: 11.5.sp, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ),
              SizedBox(height: 16.h),

              // Full list of the day's prayers.
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Obx(() {
                  if (controller.locationError.value.isNotEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      PrayerTimingRow(time: controller.fajrTime.value, label: 'Fajr', icon: Iconsax.cloud_sunny, isDark: isDark, accent: accent, isNext: controller.nextPrayerName.value == 'Fajr'),
                      PrayerTimingRow(time: controller.sunriseTime.value, label: 'Sunrise', icon: Iconsax.sun_1, isDark: isDark, accent: accent, isNext: false, isInformational: true),
                      PrayerTimingRow(time: controller.dhuhrTime.value, label: 'Dhuhr', icon: Iconsax.sun, isDark: isDark, accent: accent, isNext: controller.nextPrayerName.value == 'Dhuhr'),
                      PrayerTimingRow(time: controller.asrTime.value, label: 'Asr', icon: Iconsax.sun_1, isDark: isDark, accent: accent, isNext: controller.nextPrayerName.value == 'Asr'),
                      PrayerTimingRow(time: controller.maghribTime.value, label: 'Maghrib', icon: Iconsax.sun_fog, isDark: isDark, accent: accent, isNext: controller.nextPrayerName.value == 'Maghrib'),
                      PrayerTimingRow(time: controller.ishaTime.value, label: 'Isha', icon: Iconsax.moon, isDark: isDark, accent: accent, isNext: controller.nextPrayerName.value == 'Isha', isLast: true),
                    ],
                  );
                }),
              ),
              SizedBox(height: 16.h),

              // Calculation method glance - full control lives in Settings.
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: PressableTile(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18.r),
                  semanticLabel: '${controller.calculationMethod.name} · ${controller.madhab.name} Asr',
                  onTap: () => Get.to(() => SettingsScreen()),
                  child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    children: [
                      Icon(Iconsax.setting_4, size: 16.sp, color: accent),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          '${controller.calculationMethod.name} · ${controller.madhab.name[0].toUpperCase()}${controller.madhab.name.substring(1)} Asr',
                          style: TextStyle(fontSize: 12.5.sp, color: textColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Iconsax.arrow_right_3, size: 14.sp, color: subColor),
                    ],
                  ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Ayah/Hadith reminder about the importance of prayer.
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: accent.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.book_1, size: 16.sp, color: accent),
                        SizedBox(width: 6.w),
                        Text(
                          'A Reminder About Prayer',
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: accent),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      reminder.arabic,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700, height: 1.7, color: textColor, fontFamily: 'NotoNaskhArabic'),
                    ),
                    SizedBox(height: 8.h),
                    Text(reminder.translation, style: TextStyle(fontSize: 13.sp, height: 1.4, color: subColor)),
                    SizedBox(height: 6.h),
                    Text(reminder.reference, style: TextStyle(fontSize: 11.sp, color: accent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: 110.h),
            ],
          ),
        ),
      )),
    );
  }
}

class PrayerTimingRow extends StatelessWidget {
  final String time;
  final String label;
  final IconData icon;
  final bool isDark;
  final Color accent;
  final bool isNext;
  final bool isLast;
  final bool isInformational;

  const PrayerTimingRow({
    super.key,
    required this.time,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.accent,
    this.isNext = false,
    this.isLast = false,
    this.isInformational = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 3.h, horizontal: 6.w),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: isNext ? accent.withOpacity(isDark ? 0.18 : 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: isInformational ? subColor : (isNext ? accent : textColor.withOpacity(0.7))),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isInformational ? subColor : textColor,
                fontSize: 14.5.sp,
                fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
          if (isNext)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Text('NEXT', style: TextStyle(color: accent, fontSize: 10.sp, fontWeight: FontWeight.bold)),
            ),
          Text(
            time,
            style: TextStyle(
              color: isInformational ? subColor : textColor,
              fontSize: 14.5.sp,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
