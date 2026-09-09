import 'package:allah_everywhere/widgets/instruction_text.dart';
import 'package:allah_everywhere/widgets/location_info.dart';
import 'package:allah_everywhere/widgets/masjid_image.dart';
import 'package:allah_everywhere/widgets/mobile_rotation_image.dart';
import 'package:allah_everywhere/widgets/qibla_compass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  String _currentLocation = "Fetching location...";
  LocationStatus? _locationStatus;

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

  Future<void> _fetchCurrentLocationName() async {
    try {
      Position position =
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

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
      if (mounted) setState(() => _currentLocation = "Location unavailable");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Qibla",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(VoidImages.semicircle_background, fit: BoxFit.fill),
          ),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final status = _locationStatus;
    if (status == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!status.enabled) {
      return _buildLocationError(
        "Location services are turned off. Please enable them to find the Qibla direction.",
      );
    }
    if (status.status == LocationPermission.denied) {
      return _buildLocationError(
        "Location permission is required to find the Qibla direction.",
      );
    }
    if (status.status == LocationPermission.deniedForever) {
      return _buildLocationError(
        "Location permission was permanently denied. Please enable it from app settings.",
        showSettingsButton: true,
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 50.h),
          StreamBuilder<QiblahDirection>(
            stream: FlutterQiblah.qiblahStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox(
                  height: 180.h,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              return QiblaCompass(qiblahDirection: snapshot.data!.qiblah);
            },
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

  Widget _buildLocationError(String message, {bool showSettingsButton = false}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 48.sp, color: Colors.black54),
            SizedBox(height: 16.h),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp)),
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
    FlutterQiblah().dispose();
    super.dispose();
  }
}
