import 'package:allah_everywhere/prayer_timing.dart';
import 'package:allah_everywhere/quran.dart';
import 'package:allah_everywhere/seerat.dart';
import 'package:allah_everywhere/widgets/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/widgets/IconButtonWidget.dart';
import 'package:allah_everywhere/widgets/MosqueCardWidget.dart';
import 'package:allah_everywhere/widgets/NamazTimingWidget.dart';
import 'package:allah_everywhere/qibla.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/controllers/prayer_times_controller.dart';
import 'package:allah_everywhere/services/nearby_mosque_service.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

import 'ask_ai.dart';
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
  final PrayerTimesController controller = Get.put(PrayerTimesController());
  final NearbyMosqueService _mosqueService = NearbyMosqueService();

  List<NearbyMosque>? _nearbyMosques;
  bool _loadingMosques = false;
  bool _mosqueLookupFailed = false;

  @override
  void initState() {
    super.initState();
    ever(controller.latitude, (_) => _maybeFetchNearbyMosques());
  }

  Future<void> _maybeFetchNearbyMosques() async {
    final lat = controller.latitude.value;
    final lon = controller.longitude.value;
    if (lat == null || lon == null || _loadingMosques) return;

    setState(() {
      _loadingMosques = true;
      _mosqueLookupFailed = false;
    });
    final result = await _mosqueService.fetchNearby(lat, lon);
    if (!mounted) return;
    setState(() {
      _nearbyMosques = result.mosques;
      _mosqueLookupFailed = result.hadError;
      _loadingMosques = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        color: isDark ? Colors.black : VoidColors.secondary,
        child: RefreshIndicator(
          onRefresh: () => controller.fetchLocationAndTimes(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                          GestureDetector(
                            onTap: () {
                              Get.to(() => SearchScreen());
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
                      right: 35.w,
                      child: Obx(() => _buildPrayerSummary()),
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
                              Get.to(() => QuranScreen());
                            },
                            child: IconButtonWidget(imagePath: VoidImages.quran, title: t.quran)),
                        GestureDetector(
                            onTap: () {
                              Get.to(() => HadithScreen());
                            },
                            child: IconButtonWidget(imagePath: VoidImages.hadith, title: t.hadith)),
                        GestureDetector(
                          onTap: () {
                            Get.to(() => DuaScreen());
                          },
                          child: IconButtonWidget(imagePath: VoidImages.dua, title: t.dua),
                        ),
                        GestureDetector(
                            onTap: () {
                              Get.to(() => QiblaScreen());
                            },
                            child: IconButtonWidget(imagePath: VoidImages.qibla, title: t.qibla)),
                        GestureDetector(
                          onTap: () {
                            Get.to(() => FiqhScreen());
                          },
                          child: IconButtonWidget(imagePath: VoidImages.fiqh, title: t.fiqh),
                        ),
                        GestureDetector(
                            onTap: () {
                              Get.to(() => SeeratScreen());
                            },
                            child: IconButtonWidget(imagePath: VoidImages.seerat_nabwi, title: t.seerat)),
                        GestureDetector(
                            onTap: () {
                              Get.to(() => PrayerTimingScreen());
                            },
                            child: IconButtonWidget(imagePath: VoidImages.prayer_time, title: t.prayer)),
                        GestureDetector(
                            onTap: () {
                              Get.to(() => AskAiScreen());
                            },
                            child: IconButtonWidget(imagePath: VoidImages.alim, title: t.askAi)),
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
                        t.nearbyMasjids,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 15.h),
                      Obx(() => _buildNearbyMosques()),
                    ],
                  ),
                ),

                // Namaz Timing Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : VoidColors.whitish,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFF5D8082), width: 2),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Obx(() => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 6.0),
                                child: NamazTimingWidget(name: 'Fajr', time: controller.fajrTime.value),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 6.0),
                                child: NamazTimingWidget(name: 'Dhuhr', time: controller.dhuhrTime.value),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 6.0),
                                child: NamazTimingWidget(name: 'Asr', time: controller.asrTime.value),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 6.0),
                                child: NamazTimingWidget(name: 'Maghrib', time: controller.maghribTime.value),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 6.0),
                                child: NamazTimingWidget(name: 'Isha', time: controller.ishaTime.value),
                              ),
                            ],
                          )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerSummary() {
    final t = AppLocalizations.of(context)!;
    if (controller.locationError.value.isNotEmpty) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.locationError.value,
              style: TextStyle(fontSize: 12.sp, color: Colors.black87),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: controller.permissionPermanentlyDenied.value
                  ? Geolocator.openAppSettings
                  : controller.fetchLocationAndTimes,
              child: Text(
                controller.permissionPermanentlyDenied.value ? t.openSettings : t.retry,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.yourLocation,
          style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5.h),
        Text(
          controller.location.value,
          style: TextStyle(color: Colors.black, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10.h),
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
                        controller.nextPrayerName.value.isEmpty
                            ? 'Loading...'
                            : controller.nextPrayerName.value,
                        style: TextStyle(
                          color: VoidColors.secondary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        controller.nextPrayerTime.value,
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
                    controller.islamicDate.value.isEmpty ? 'Loading Islamic date...' : controller.islamicDate.value,
                    style: TextStyle(color: VoidColors.white, fontSize: 17.sp, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    controller.gregorianDate.value.isEmpty ? 'Loading date...' : controller.gregorianDate.value,
                    style: TextStyle(color: VoidColors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '${t.nextPrayerIn} \n${controller.remainingTime.value}',
                    style: TextStyle(color: VoidColors.secondary, fontSize: 15.sp, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNearbyMosques() {
    final t = AppLocalizations.of(context)!;
    if (_loadingMosques) {
      return SizedBox(
        height: 60.h,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_nearbyMosques == null) {
      if (controller.locationError.value.isNotEmpty) {
        return Row(
          children: [
            Expanded(
              child: Text(
                controller.locationError.value,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
              ),
            ),
            TextButton(
              onPressed: controller.permissionPermanentlyDenied.value
                  ? Geolocator.openAppSettings
                  : controller.fetchLocationAndTimes,
              child: Text(
                controller.permissionPermanentlyDenied.value ? t.openSettings : t.retry,
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
          ],
        );
      }
      return Text(
        t.waitingForLocation,
        style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
      );
    }
    if (_mosqueLookupFailed) {
      return Row(
        children: [
          Expanded(
            child: Text(
              t.couldNotReachMosqueDirectory,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: _maybeFetchNearbyMosques,
            child: Text(t.retry, style: TextStyle(fontSize: 13.sp)),
          ),
        ],
      );
    }
    if (_nearbyMosques!.isEmpty) {
      return Text(
        t.noMosquesFound,
        style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _nearbyMosques!
            .map((mosque) => MosqueCardWidget(
                  name: mosque.name,
                  location: '${mosque.distanceKm.toStringAsFixed(1)} km away',
                  imagePath: VoidImages.masjid_vector,
                ))
            .toList(),
      ),
    );
  }
}
