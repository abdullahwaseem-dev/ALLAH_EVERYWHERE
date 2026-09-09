import 'dart:async';
import 'package:allah_everywhere/prayer_timing.dart';
import 'package:allah_everywhere/quran.dart';
import 'package:allah_everywhere/seerat.dart';
import 'package:allah_everywhere/tasbeeh.dart';
import 'package:allah_everywhere/widgets/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/widgets/IconButtonWidget.dart';
import 'package:allah_everywhere/widgets/MosqueCardWidget.dart';
import 'package:allah_everywhere/widgets/NamazTimingWidget.dart';
import 'package:allah_everywhere/qibla.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:permission_handler/permission_handler.dart';

import 'alim.dart';
import 'dua.dart';
import 'fiqh.dart';
import 'hadith.dart';
import 'notification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _location = 'Fetching location...';
  String? _nextPrayer = 'Fetching prayer time...';
  String? _nextPrayerTime = '00:00';
  String? _islamicDate = 'Fetching Islamic date...';
  String? _gregorianDate = 'Fetching date...';
  String? _remainingTime = '00:00:00';

  Position? _currentPosition;
  Timer? _timer;
  Duration? _remainingDuration;

  String? _fajrTime;
  String? _dhuhrTime;
  String? _asrTime;
  String? _maghribTime;
  String? _ishaTime;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _getLocation();

  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      _getLocation();
    } else {

      setState(() {
        _location = "Permission denied";
      });
    }
  }
  Future<void> _getLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _currentPosition = position;
    _getPrayerTimes(position.latitude, position.longitude);

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String locationName = "${placemark.subLocality},${placemark.locality}, ${placemark.country}";

    setState(() {
      _location = locationName;
    });

    _getIslamicDate();
  }


  void _getPrayerTimes(double latitude, double longitude) {
    final params = CalculationMethod.muslim_world_league.getParameters();
    final prayerTimes = PrayerTimes.today(
        Coordinates(latitude, longitude), params);


    DateTime currentTime = DateTime.now();
    String nextPrayerName = '';
    String nextPrayerTime = '';
    Duration timeDifference = Duration.zero;

    setState(() {
      _fajrTime = DateFormat('hh:mm a').format(prayerTimes.fajr);
      _dhuhrTime = DateFormat('hh:mm a').format(prayerTimes.dhuhr);
      _asrTime = DateFormat('hh:mm a').format(prayerTimes.asr);
      _maghribTime = DateFormat('hh:mm a').format(prayerTimes.maghrib);
      _ishaTime = DateFormat('hh:mm a').format(prayerTimes.isha);
    });


    DateTime currentUtcTime = currentTime.toUtc();


    if (currentUtcTime.isBefore(prayerTimes.fajr.toUtc())) {
      nextPrayerName = 'Fajr';
      nextPrayerTime = DateFormat('hh:mm a').format(prayerTimes.fajr);
      timeDifference = prayerTimes.fajr.toUtc().difference(currentUtcTime);
    } else if (currentUtcTime.isBefore(prayerTimes.dhuhr.toUtc())) {
      nextPrayerName = 'Dhuhr';
      nextPrayerTime = DateFormat('hh:mm a').format(prayerTimes.dhuhr);
      timeDifference = prayerTimes.dhuhr.toUtc().difference(currentUtcTime);
    } else if (currentUtcTime.isBefore(prayerTimes.asr.toUtc())) {
      nextPrayerName = 'Asr';
      nextPrayerTime = DateFormat('hh:mm a').format(prayerTimes.asr);
      timeDifference = prayerTimes.asr.toUtc().difference(currentUtcTime);
    } else if (currentUtcTime.isBefore(prayerTimes.maghrib.toUtc())) {
      nextPrayerName = 'Maghrib';
      nextPrayerTime = DateFormat('hh:mm a').format(prayerTimes.maghrib);
      timeDifference = prayerTimes.maghrib.toUtc().difference(currentUtcTime);
    } else if (currentUtcTime.isBefore(prayerTimes.isha.toUtc())) {
      nextPrayerName = 'Isha';
      nextPrayerTime = DateFormat('hh:mm a').format(prayerTimes.isha);
      timeDifference = prayerTimes.isha.toUtc().difference(currentUtcTime);
    } else {
      nextPrayerName = 'Fajr';
      nextPrayerTime = DateFormat('hh:mm a').format(prayerTimes.fajr.add(Duration(days: 1)));
      timeDifference = prayerTimes.fajr.add(Duration(days: 1)).toUtc().difference(currentUtcTime);
    }


    setState(() {
      _nextPrayer = nextPrayerName;
      _nextPrayerTime = nextPrayerTime;
      _remainingDuration = timeDifference;
    });


    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }


  void _updateRemainingTime() {
    if (_remainingDuration == null) return;


    _remainingDuration = _remainingDuration! - Duration(seconds: 1);


    if (_remainingDuration!.isNegative || _remainingDuration!.inSeconds == 0) {
      _timer?.cancel();
      setState(() {
        _remainingTime = '00:00:00';
      });
      return;
    }

    int hoursRemaining = _remainingDuration!.inHours;
    int minutesRemaining = _remainingDuration!.inMinutes % 60;
    int secondsRemaining = _remainingDuration!.inSeconds % 60;


    setState(() {
      _remainingTime = '$hoursRemaining h: $minutesRemaining m: $secondsRemaining s';
    });
  }


  void _getIslamicDate() {

    final hijriDate = HijriCalendar.fromDate(DateTime.now());


    final int day = hijriDate.hDay;
    final String monthName = hijriDate.shortMonthName ;
    final int year = hijriDate.hYear;


    final formattedIslamicDate = '$day $monthName $year AH';


    setState(() {
      _islamicDate = formattedIslamicDate;
    });


    final formattedGregorianDate = DateFormat('EEE, dd MMM yyyy').format(DateTime.now());
    setState(() {
      _gregorianDate = formattedGregorianDate;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: VoidColors.secondary,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(VoidImages.home_logo),
                        fit: BoxFit.cover,
                      ),
                    ),
                    height: 510.h,
                  ),
                  Positioned(
                    top: 200.h,
                    left: 22.w,
                    right: 26.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Search bar
                        GestureDetector(
                          onTap: (){
                            Get.to(()=>SearchScreen());
                          },
                          child: Container(
                            height: 40.h,
                            width: 260.w,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(VoidImages.search_bar),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // Notification icon
                        GestureDetector(
                          onTap: () {
                            Get.to(() => NotificationsScreen());
                          },
                          child: Image.asset(
                            VoidImages.notification_icon,
                            height: 40.h,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 250.h,
                    left: 35.w,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Location:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            // Location description
                            Text(
                              _location!,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            // Prayer Info Banner
                            Stack(
                              children: [
                                Image.asset(
                                  alignment: Alignment.center,
                                  VoidImages.banner,
                                  width: 300.w,
                                  height: 180.h,
                                  fit: BoxFit.fill,
                                ),
                                Positioned(
                                  top: 10.h,
                                  left: 10.w,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _nextPrayer ?? 'Loading...',
                                            style: TextStyle(
                                              color: VoidColors.secondary,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Text(
                                            _nextPrayerTime ?? '00:00',
                                            style: TextStyle(
                                              color: VoidColors.secondary,
                                              fontSize: 38.sp,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        _islamicDate ?? 'Loading Islamic date...',
                                        style: TextStyle(
                                          color: VoidColors.white,
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 10.h),
                                      Text(
                                        _gregorianDate ?? 'Loading Gregorian date...',
                                        style: TextStyle(
                                          color: VoidColors.white,
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 10.h),
                                      Text(
                                        'Next Prayer In: \n$_remainingTime',
                                        style: TextStyle(
                                          color: VoidColors.secondary,
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),


              SizedBox(height: 35.h),

              // Grid with icons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(VoidImages.banner_2),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: GridView.count(
                    crossAxisCount: 4,
                    padding: const EdgeInsets.all(10),
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      GestureDetector(
                          onTap: () {
                            Get.to(()=> QuranScreen());
                          },
                          child: IconButtonWidget(imagePath: VoidImages.quran, title: "Quran")),
                      GestureDetector(
                          onTap: () {
                            Get.to(()=> HadithScreen());
                          },
                          child: IconButtonWidget(imagePath: VoidImages.hadith, title: "Hadith")),
                      GestureDetector(
                        onTap: (){
                      Get.to(() => DuaScreen());
                      },
                          child: IconButtonWidget(imagePath: VoidImages.dua, title: "Dua")),
                      GestureDetector(
                          onTap: () {
                            Get.to(() => QiblaScreen());
                          },
                          child: IconButtonWidget(imagePath: VoidImages.qibla, title: "Qibla")),
                      GestureDetector(
                        onTap: (){
                          Get.to(()=>FiqhScreen());
                        },
                          child: IconButtonWidget(imagePath: VoidImages.fiqh, title: "Fiqh")),
                      GestureDetector(
                          onTap: () {
                              Get.to(()=>SeeratScreen());
                          },
                          child: IconButtonWidget(imagePath: VoidImages.seerat_nabwi, title: "Seerat")),
                      GestureDetector(
                          onTap: () {
                            Get.to(() => PrayerTimingScreen());
                          },
                          child: IconButtonWidget(imagePath: VoidImages.prayer_time, title: "Prayer")),
                      GestureDetector(
                          onTap: () {
                            Get.to(() => AlimScreen());
                          },
                          child: IconButtonWidget(imagePath: VoidImages.alim, title: "Alim")),
                    ],
                  ),
                ),
              ),

              // Nearby Masjid Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nearby Masjid's",
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 15.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          MosqueCardWidget(name: "Faisal Mosque", location: "Islamabad", imagePath: VoidImages.mosque_faisal),
                          MosqueCardWidget(name: "Lal Masjid", location: "Sector G-6", imagePath: VoidImages.mosque_lal),
                          // Add more cards here as needed
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Namaz Timing Section
              // Namaz Timing Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VoidColors.whitish,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Color(0xFF5D8082),
                      width: 2,
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: NamazTimingWidget(name: 'Fajr', time: _fajrTime ?? 'Loading...'),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: NamazTimingWidget(name: 'Dhuhr', time: _dhuhrTime ?? 'Loading...'),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: NamazTimingWidget(name: 'Asr', time: _asrTime ?? 'Loading...'),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: NamazTimingWidget(name: 'Maghrib', time: _maghribTime ?? 'Loading...'),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: NamazTimingWidget(name: 'Isha', time: _ishaTime ?? 'Loading...'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
