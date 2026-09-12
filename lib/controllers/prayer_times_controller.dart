import 'dart:async';
import 'dart:math';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/services/local_notifications_service.dart';
import 'package:allah_everywhere/data/prayer_reminders_data.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';

/// Single source of truth for prayer times, shared by the Home screen and
/// the standalone Prayer Timing screen so they never show different times
/// for the same moment. Respects the calculation method / madhab chosen in
/// Settings.
class PrayerTimesController extends GetxController {
  static const _methodKey = 'prayer_calculation_method';
  static const _madhabKey = 'prayer_madhab';

  final RxString location = 'Fetching location...'.obs;
  final RxString locationError = ''.obs;
  final RxBool permissionPermanentlyDenied = false.obs;
  final RxBool isLoading = true.obs;
  final Rx<double?> latitude = Rx<double?>(null);
  final Rx<double?> longitude = Rx<double?>(null);

  final RxString fajrTime = '--:--'.obs;
  final RxString sunriseTime = '--:--'.obs;
  final RxString dhuhrTime = '--:--'.obs;
  final RxString asrTime = '--:--'.obs;
  final RxString maghribTime = '--:--'.obs;
  final RxString ishaTime = '--:--'.obs;

  final RxString nextPrayerName = ''.obs;
  final RxString nextPrayerTime = '--:--'.obs;
  final RxString remainingTime = '00:00:00'.obs;
  final RxString islamicDate = ''.obs;
  final RxString gregorianDate = ''.obs;

  /// Raw (non-formatted) times for the 5 daily prayers, in device-local
  /// time. Consumed by LocalNotificationsService to schedule Adhan alerts -
  /// bumped every time prayer times are (re)computed so listeners (`ever`)
  /// know to reschedule.
  final Rx<Map<String, DateTime>> prayerDateTimes = Rx<Map<String, DateTime>>({});

  /// Set to the prayer name the instant its time is reached (while the app
  /// is running) so the UI layer can show the in-app reminder dialog, then
  /// cleared. Kept separate from [nextPrayerName] (which already points at
  /// the *next* prayer) to avoid ambiguity about what just happened.
  final Rx<String?> justReachedPrayer = Rx<String?>(null);

  Timer? _timer;
  Duration? _remainingDuration;

  CalculationMethod get calculationMethod {
    final stored = VoidStorage().readData<String>(_methodKey);
    return CalculationMethod.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => CalculationMethod.muslim_world_league,
    );
  }

  set calculationMethod(CalculationMethod method) {
    VoidStorage().saveData(_methodKey, method.name);
    refresh();
  }

  Madhab get madhab {
    final stored = VoidStorage().readData<String>(_madhabKey);
    return stored == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
  }

  set madhab(Madhab value) {
    VoidStorage().saveData(_madhabKey, value.name);
    refresh();
  }

  @override
  void onInit() {
    super.onInit();
    fetchLocationAndTimes();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> fetchLocationAndTimes() async {
    isLoading.value = true;
    locationError.value = '';
    permissionPermanentlyDenied.value = false;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        permissionPermanentlyDenied.value = true;
        locationError.value =
            'Location permission was permanently denied. Enable it from app settings.';
        isLoading.value = false;
        return;
      }
      if (permission == LocationPermission.denied) {
        locationError.value = 'Location permission is required for accurate prayer times.';
        isLoading.value = false;
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        locationError.value = 'Location services are turned off.';
        isLoading.value = false;
        return;
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        );
      } on TimeoutException {
        // A fresh GPS fix can take a long time (or never arrive) with a
        // weak signal - fall back to the last known fix rather than
        // leaving the user staring at an infinite spinner.
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown == null) rethrow;
        position = lastKnown;
      }
      latitude.value = position.latitude;
      longitude.value = position.longitude;
      _computePrayerTimes(position.latitude, position.longitude);
      _computeIslamicDate();

      try {
        final placemarks =
            await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          location.value = "${placemark.subLocality}, ${placemark.locality}, ${placemark.country}";
        }
      } catch (e) {
        VoidLogger.error('Reverse geocoding failed', e);
        location.value = 'Location found (name unavailable)';
      }
    } catch (e) {
      VoidLogger.error('Failed to fetch prayer times', e);
      locationError.value = 'Could not determine your location. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void _computePrayerTimes(double latitude, double longitude) {
    final params = calculationMethod.getParameters();
    params.madhab = madhab;
    final prayerTimes = PrayerTimes.today(Coordinates(latitude, longitude), params);

    fajrTime.value = DateFormat('hh:mm a').format(prayerTimes.fajr);
    sunriseTime.value = DateFormat('hh:mm a').format(prayerTimes.sunrise);
    dhuhrTime.value = DateFormat('hh:mm a').format(prayerTimes.dhuhr);
    asrTime.value = DateFormat('hh:mm a').format(prayerTimes.asr);
    maghribTime.value = DateFormat('hh:mm a').format(prayerTimes.maghrib);
    ishaTime.value = DateFormat('hh:mm a').format(prayerTimes.isha);

    prayerDateTimes.value = {
      'Fajr': prayerTimes.fajr,
      'Dhuhr': prayerTimes.dhuhr,
      'Asr': prayerTimes.asr,
      'Maghrib': prayerTimes.maghrib,
      'Isha': prayerTimes.isha,
    };
    LocalNotificationsService().reschedulePrayerNotifications(prayerDateTimes.value);

    final now = DateTime.now().toUtc();
    String name;
    DateTime time;

    if (now.isBefore(prayerTimes.fajr.toUtc())) {
      name = 'Fajr';
      time = prayerTimes.fajr;
    } else if (now.isBefore(prayerTimes.dhuhr.toUtc())) {
      name = 'Dhuhr';
      time = prayerTimes.dhuhr;
    } else if (now.isBefore(prayerTimes.asr.toUtc())) {
      name = 'Asr';
      time = prayerTimes.asr;
    } else if (now.isBefore(prayerTimes.maghrib.toUtc())) {
      name = 'Maghrib';
      time = prayerTimes.maghrib;
    } else if (now.isBefore(prayerTimes.isha.toUtc())) {
      name = 'Isha';
      time = prayerTimes.isha;
    } else {
      name = 'Fajr';
      time = prayerTimes.fajr.add(const Duration(days: 1));
    }

    nextPrayerName.value = name;
    nextPrayerTime.value = DateFormat('hh:mm a').format(time);
    _remainingDuration = time.toUtc().difference(now);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_remainingDuration == null) return;
    _remainingDuration = _remainingDuration! - const Duration(seconds: 1);

    if (_remainingDuration!.isNegative) {
      _timer?.cancel();
      justReachedPrayer.value = nextPrayerName.value;
      _showPrayerReminderDialog(nextPrayerName.value);
      // Prayer window passed - recompute for the next one.
      fetchLocationAndTimes();
      return;
    }

    final d = _remainingDuration!;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    remainingTime.value = '$h:$m:$s';
  }

  void _computeIslamicDate() {
    final hijriDate = HijriCalendar.fromDate(DateTime.now());
    islamicDate.value = '${hijriDate.hDay} ${hijriDate.shortMonthName} ${hijriDate.hYear} AH';
    gregorianDate.value = DateFormat('EEE, dd MMM yyyy').format(DateTime.now());
  }

  /// Shown while the app is in the foreground at the moment a prayer time
  /// is reached - a reminder of why prayer matters, with a fresh
  /// Quran/Hadith citation each time. Uses Get.dialog so it doesn't need a
  /// BuildContext from whichever screen happens to be visible.
  void _showPrayerReminderDialog(String prayerName) {
    if (Get.overlayContext == null) return;
    final reminder = prayerReminders[Random().nextInt(prayerReminders.length)];
    Get.dialog(
      AlertDialog(
        title: Text("It's time for $prayerName"),
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
}
