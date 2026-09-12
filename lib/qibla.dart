import 'dart:async';
import 'dart:math' as math;

import 'package:allah_everywhere/widgets/instruction_text.dart';
import 'package:allah_everywhere/widgets/location_info.dart';
import 'package:allah_everywhere/widgets/masjid_image.dart';
import 'package:allah_everywhere/widgets/mobile_rotation_image.dart';
import 'package:allah_everywhere/widgets/qibla_compass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:allah_everywhere/controllers/prayer_times_controller.dart';

// Kaaba coordinates, matching the ones flutter_qiblah itself uses.
const double _kaabaLat = 21.422487;
const double _kaabaLon = 39.826206;

/// Standard great-circle initial-bearing ("forward azimuth") formula from
/// the given point to the Kaaba, in degrees from true North (0-360).
double _qiblaBearingFromNorth(double lat, double lon) {
  final phi1 = lat * math.pi / 180;
  final phi2 = _kaabaLat * math.pi / 180;
  final deltaLambda = (_kaabaLon - lon) * math.pi / 180;
  final y = math.sin(deltaLambda) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
  final theta = math.atan2(y, x) * 180 / math.pi;
  return (theta + 360) % 360;
}

class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  String _currentLocation = "Fetching location...";
  LocationStatus? _locationStatus;

  // flutter_qiblah's own qiblahStream merges the compass with
  // Geolocator.getPositionStream() (continuous, default settings) via
  // combineLatest - on devices with slow/weak GPS that stream can take a
  // very long time to emit even a first update, which leaves the merged
  // stream (and the compass UI) stuck forever. A one-shot
  // getCurrentPosition() call is already proven to resolve reliably here
  // (it's what powers the location name below), so the Qibla bearing is
  // computed from that instead, and only the live compass heading comes
  // from a stream.
  double? _qiblaOffsetFromNorth;
  double? _qiblahDirection;
  bool _positionFailed = false;
  // On some devices the compass plugin's live heading stream never
  // delivers a single event to Dart even though the native sensor is
  // actively running (observed on this test device - not something this
  // app's code controls). Rather than leave the screen stuck forever
  // waiting for a live heading, a short timeout falls back to showing the
  // compass using the calculated Qibla bearing alone.
  bool _compassTimedOut = false;
  StreamSubscription<CompassEvent>? _compassSub;
  Timer? _compassTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    var status = await FlutterQiblah.checkLocationStatus();
    if (status.enabled && status.status == LocationPermission.denied) {
      await FlutterQiblah.requestPermissions();
      status = await FlutterQiblah.checkLocationStatus();
    }

    if (!mounted) return;
    setState(() => _locationStatus = status);

    if (status.enabled &&
        (status.status == LocationPermission.always ||
            status.status == LocationPermission.whileInUse)) {
      _fetchCurrentLocationName();
    }
  }

  /// Reuses PrayerTimesController's already-resolved position when
  /// available (instant - Home resolves it on launch), otherwise fetches a
  /// fresh one. Weak/slow GPS on some devices can leave a plain
  /// getCurrentPosition() call pending forever with no error and no data,
  /// so this mirrors PrayerTimesController's own timeout + last-known-fix
  /// fallback rather than waiting indefinitely.
  Future<(double, double)> _resolvePosition() async {
    if (Get.isRegistered<PrayerTimesController>()) {
      final controller = Get.find<PrayerTimesController>();
      final lat = controller.latitude.value;
      final lon = controller.longitude.value;
      if (lat != null && lon != null) return (lat, lon);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      return (position.latitude, position.longitude);
    } on TimeoutException {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown == null) rethrow;
      return (lastKnown.latitude, lastKnown.longitude);
    }
  }

  Future<void> _fetchCurrentLocationName() async {
    try {
      final (lat, lon) = await _resolvePosition();
      if (!mounted) return;
      setState(() {
        _qiblaOffsetFromNorth = _qiblaBearingFromNorth(lat, lon);
      });
      _subscribeToCompass();

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _currentLocation =
              "${placemark.subLocality}, ${placemark.locality}, ${placemark.country}";
        });
      } else {
        setState(() => _currentLocation = "Location unavailable");
      }
    } catch (e) {
      VoidLogger.error('Error fetching Qibla location name', e);
      if (mounted) {
        setState(() {
          _currentLocation = "Location unavailable";
          _positionFailed = true;
        });
      }
    }
  }

  void _subscribeToCompass() {
    _compassSub?.cancel();
    _compassSub = FlutterCompass.events?.listen((event) {
      final offset = _qiblaOffsetFromNorth;
      if (!mounted || offset == null) return;
      _compassTimeoutTimer?.cancel();
      final heading = event.heading ?? 0.0;
      setState(() {
        _qiblahDirection = heading + (360 - offset);
        _compassTimedOut = false;
      });
    });

    // If the device's compass stream never delivers a single heading
    // update (seen on some devices even while the native sensor is
    // actively running), fall back to a static Qibla direction instead of
    // leaving the screen stuck on "move your phone" forever.
    _compassTimeoutTimer?.cancel();
    _compassTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _qiblahDirection != null) return;
      final offset = _qiblaOffsetFromNorth;
      if (offset == null) return;
      setState(() {
        _qiblahDirection = 360 - offset;
        _compassTimedOut = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          "Qibla",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: textColor),
        ),
        centerTitle: true,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final status = _locationStatus;
    if (status == null) {
      return Center(child: CircularProgressIndicator(color: accent));
    }
    if (!status.enabled) {
      return _buildLocationError(
        "Location services are turned off. Please enable them to find the Qibla direction.",
        isDark,
      );
    }
    if (status.status == LocationPermission.denied) {
      return _buildLocationError(
        "Location permission is required to find the Qibla direction.",
        isDark,
      );
    }
    if (status.status == LocationPermission.deniedForever) {
      return _buildLocationError(
        "Location permission was permanently denied. Please enable it from app settings.",
        isDark,
        showSettingsButton: true,
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 50.h),
          if (_positionFailed)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  Text(
                    'Could not determine your location for the Qibla direction.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.sp, color: isDark ? VoidColors.textDarkSecondary : Colors.black54),
                  ),
                  SizedBox(height: 10.h),
                  TextButton(
                    onPressed: () {
                      setState(() => _positionFailed = false);
                      _fetchCurrentLocationName();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_qiblahDirection == null)
            SizedBox(
              height: 180.h,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 12.h),
                  Text(
                    'Move your phone in a figure-8 to calibrate the compass',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.sp, color: isDark ? VoidColors.textDarkSecondary : Colors.black54),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                QiblaCompass(qiblahDirection: _qiblahDirection!),
                if (_compassTimedOut) ...[
                  SizedBox(height: 10.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      "Live compass rotation isn't available on this device right now - this points toward the Qibla assuming your phone is held facing forward.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5.sp, color: isDark ? VoidColors.textDarkSecondary : Colors.black54),
                    ),
                  ),
                ],
              ],
            ),
          SizedBox(height: 10.h),
          MasjidImage(),
          SizedBox(height: 20.h),
          InstructionText(),
          SizedBox(height: 20.h),
          MobileRotationImage(),
          SizedBox(height: 60.h),
          LocationInfo(currentLocation: _currentLocation),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildLocationError(String message, bool isDark, {bool showSettingsButton = false}) {
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.black54;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 48.sp, color: subColor),
            SizedBox(height: 16.h),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: textColor)),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: showSettingsButton ? Geolocator.openAppSettings : _checkLocationStatus,
              child: Text(showSettingsButton ? 'Open Settings' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _compassTimeoutTimer?.cancel();
    super.dispose();
  }
}
