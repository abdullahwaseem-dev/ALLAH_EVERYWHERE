import 'dart:async';
import 'package:allah_everywhere/widgets/instruction_text.dart';
import 'package:allah_everywhere/widgets/location_info.dart';
import 'package:allah_everywhere/widgets/masjid_image.dart';
import 'package:allah_everywhere/widgets/mobile_rotation_image.dart';
import 'package:allah_everywhere/widgets/qibla_compass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double _qiblaDirection = 0.0;
  double _deviceHeading = 0.0;
  String _currentLocation = "Fetching location...";

  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _startCompass();
  }

  Future<void> _checkPermissions() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      print("Location permission granted.");
      _fetchCurrentLocation();
      _fetchQiblaDirection();
    } else {
      print("Location permission denied.");
    }
  }

  Future<void> _fetchQiblaDirection() async {
    try {
      FlutterQiblah.qiblahStream.listen((QiblahDirection qiblaDirection) {
        if (mounted) {
          setState(() {
            _qiblaDirection = qiblaDirection.qiblah;
          });
        }
      });
    } catch (e) {
      print("Error fetching Qibla direction: $e");
    }
  }

  void _startCompass() {
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          _deviceHeading = event.x;
        });
      }
    });
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await GeocodingPlatform.instance!.placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _currentLocation = "${placemark.subLocality}, ${placemark.locality}, ${placemark.country}";
        });
      } else {
        setState(() {
          _currentLocation = "Location unavailable";
        });
      }
    } catch (e) {
      print("Error fetching location: $e");
      setState(() {
        _currentLocation = "Location unavailable";
      });
    }
  }

  @override
  void dispose() {
    _gyroscopeSubscription.cancel();
    super.dispose();
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
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Qibla",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              VoidImages.semicircle_background,
              fit: BoxFit.fill,
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 50.h),
                QiblaCompass(deviceHeading: _deviceHeading, qiblaDirection: _qiblaDirection),
                SizedBox(height: 10.h),
                MasjidImage(),
                SizedBox(height: 20.h),
                InstructionText(),
                SizedBox(height: 20.h),
                MobileRotationImage(),
                SizedBox(height: 10.h),
              ],
            ),
          ),
          Positioned(
            bottom: 10.h,
            left: 0,
            right: 0,
            child: LocationInfo(currentLocation: _currentLocation),
          ),
        ],
      ),
    );
  }
}
