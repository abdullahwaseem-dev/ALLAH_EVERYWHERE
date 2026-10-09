import 'dart:async';
import 'dart:math';

import 'package:adhan/adhan.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/services/local_notifications_service.dart';
import 'package:allah_everywhere/services/prayer_calculation.dart';
import 'package:allah_everywhere/services/islamic_calendar_service.dart';
import 'package:allah_everywhere/data/prayer_reminders_data.dart';
import 'package:allah_everywhere/widgets/prayer_reminder_dialog.dart';
import 'package:allah_everywhere/services/home_widget_service.dart';

/// Single source of truth for prayer times, shared by the Home screen and
/// the standalone Prayer Timing screen so they never show different times
/// for the same moment. Respects the calculation method / madhab chosen in
/// Settings.
class PrayerTimesController extends GetxController {
  static const _methodKey = 'prayer_calculation_method';
  static const _madhabKey = 'prayer_madhab';
  // ISO country of the last located position, so the automatic calculation
  // method is right offline and before reverse geocoding finishes.
  static const _countryKey = 'prayer_country_code';
  static const _lastLatKey = 'prayer_last_latitude';
  static const _lastLngKey = 'prayer_last_longitude';

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

  /// The method the user picked in Settings, or null for automatic.
  CalculationMethod? get manualCalculationMethod {
    final stored = VoidStorage().readData<String>(_methodKey);
    for (final m in CalculationMethod.values) {
      if (m.name == stored) return m;
    }
    return null;
  }

  /// What automatic mode uses for the user's current country.
  CalculationMethod get automaticCalculationMethod =>
      methodForCountry(VoidStorage().readData<String>(_countryKey));

  CalculationMethod get calculationMethod => manualCalculationMethod ?? automaticCalculationMethod;

  /// Null switches back to automatic (by country).
  set manualCalculationMethod(CalculationMethod? method) {
    if (method == null) {
      VoidStorage().removeData(_methodKey);
    } else {
      VoidStorage().saveData(_methodKey, method.name);
    }
    _recomputeIfLocated();
  }

  Madhab get madhab {
    final stored = VoidStorage().readData<String>(_madhabKey);
    return stored == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
  }

  set madhab(Madhab value) {
    VoidStorage().saveData(_madhabKey, value.name);
    _recomputeIfLocated();
  }

  /// Settings changes used to only call refresh(), which redraws widgets but
  /// never recomputed the times - a new method/madhab showed no effect until
  /// the next location fetch. Recompute (and reschedule Adhans) right away.
  void _recomputeIfLocated() {
    final lat = latitude.value;
    final lng = longitude.value;
    if (lat != null && lng != null) _computePrayerTimes(lat, lng);
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
        await _useCachedLocationIfAvailable();
        return;
      }
      if (permission == LocationPermission.denied) {
        locationError.value = 'Location permission is required for accurate prayer times.';
        await _useCachedLocationIfAvailable();
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        locationError.value = 'Location services are turned off.';
        await _useCachedLocationIfAvailable();
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
        if (lastKnown == null) {
          await _useCachedLocationIfAvailable();
          return;
        }
        position = lastKnown;
      }
      latitude.value = position.latitude;
      longitude.value = position.longitude;
      await VoidStorage().saveData(_lastLatKey, position.latitude);
      await VoidStorage().saveData(_lastLngKey, position.longitude);
      _computePrayerTimes(position.latitude, position.longitude);
      _computeIslamicDate();

      try {
        final placemarks =
            await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final country = placemark.isoCountryCode?.trim().toUpperCase() ?? '';
          if (country.isNotEmpty && country != VoidStorage().readData<String>(_countryKey)) {
            final before = calculationMethod;
            await VoidStorage().saveData(_countryKey, country);
            // Times were computed before the country was known - redo them
            // if that changes the (automatic) method.
            if (calculationMethod != before) _computePrayerTimes(position.latitude, position.longitude);
          }
          // Geocoders often leave subLocality or locality blank (or repeat
          // the city in both), which used to render as ", Gulberg, Pakistan".
          final parts = <String>[];
          for (final part in [placemark.subLocality, placemark.locality, placemark.country]) {
            final value = part?.trim() ?? '';
            if (value.isNotEmpty && !parts.contains(value)) parts.add(value);
          }
          location.value = parts.isEmpty ? 'Location found (name unavailable)' : parts.join(', ');
        }
      } catch (e) {
        VoidLogger.error('Reverse geocoding failed', e);
        location.value = 'Location found (name unavailable)';
      }
    } catch (e) {
      VoidLogger.error('Failed to fetch prayer times', e);
      locationError.value = 'Could not determine your location. Please try again.';
      await _useCachedLocationIfAvailable();
    } finally {
      isLoading.value = false;
    }
  }

  /// Falls back to the last successfully-fetched coordinates (persisted to
  /// disk) so prayer times - and critically, the notifications scheduled
  /// from them - still get set up even when a fresh location fix isn't
  /// available right now (permission just revoked, GPS off, indoors, or an
  /// emulator with no location at all). Without this, testers whose fix
  /// fails for any reason got zero prayer notifications, full stop.
  Future<void> _useCachedLocationIfAvailable() async {
    final lat = VoidStorage().readData<double>(_lastLatKey);
    final lng = VoidStorage().readData<double>(_lastLngKey);
    if (lat == null || lng == null) return;
    latitude.value = lat;
    longitude.value = lng;
    if (location.value == 'Fetching location...' || location.value.isEmpty) {
      location.value = 'Using last known location';
    }
    _computePrayerTimes(lat, lng);
    _computeIslamicDate();
  }

  /// Re-issues scheduled prayer notifications using whatever coordinates
  /// are currently known, without needing a fresh location fetch. Used by
  /// LanguageController/Settings when notification text needs to be
  /// re-issued (e.g. after a language change) without recomputing times.
  Future<void> rescheduleNotifications() async {
    final lat = latitude.value;
    final lng = longitude.value;
    if (lat == null || lng == null) return;
    await LocalNotificationsService().reschedulePrayerNotifications(
      latitude: lat,
      longitude: lng,
      calculationMethod: calculationMethod,
      madhab: madhab,
    );
  }

  void _computePrayerTimes(double latitude, double longitude) {
    final params = prayerParameters(calculationMethod, madhab, DateTime.now());
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
    LocalNotificationsService().reschedulePrayerNotifications(
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
      madhab: madhab,
    );
    HomeWidgetService.sync(latitude: latitude, longitude: longitude, method: calculationMethod, madhab: madhab);

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
      final reminder = prayerReminders[Random().nextInt(prayerReminders.length)];
      showPrayerReminderDialog(reminder, prayerName: nextPrayerName.value);
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

  /// Re-reads the Hijri date, e.g. after the Settings Hijri adjustment
  /// changes.
  void refreshIslamicDate() {
    _computeIslamicDate();
    HomeWidgetService.sync(latitude: latitude.value, longitude: longitude.value);
  }

  void _computeIslamicDate() {
    // Shifted by the user's moon-sighting adjustment, like the calendar.
    final hijriDate = HijriCalendar.fromDate(DateTime.now().add(Duration(days: IslamicCalendarService.adjustment)));
    islamicDate.value = '${hijriDate.hDay} ${hijriDate.shortMonthName} ${hijriDate.hYear} AH';
    gregorianDate.value = DateFormat('EEE, dd MMM yyyy').format(DateTime.now());
  }

}
