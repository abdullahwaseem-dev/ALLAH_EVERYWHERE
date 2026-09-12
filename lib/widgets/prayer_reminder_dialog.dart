import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/data/prayer_reminders_data.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';

/// Shown both when a prayer time is reached while the app is open, and when
/// the user taps the Adhan notification - a reminder of why prayer matters,
/// with a Quran/Hadith citation. Uses Get.dialog so it doesn't need a
/// BuildContext from whichever screen happens to be visible.
void showPrayerReminderDialog(PrayerReminder reminder, {String? prayerName}) {
  if (Get.overlayContext == null) return;
  Get.dialog(
    AlertDialog(
      title: Text(prayerName != null ? "It's time for $prayerName" : 'A Reminder About Prayer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reminder.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 18, fontFamily: 'NotoNaskhArabic', height: 1.6),
            ),
            const SizedBox(height: 12),
            Text(reminder.translation, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 8),
            Text(
              reminder.reference,
              style: TextStyle(fontSize: 12, color: VoidColors.brown, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Ameen')),
      ],
    ),
    barrierDismissible: true,
  );
}
