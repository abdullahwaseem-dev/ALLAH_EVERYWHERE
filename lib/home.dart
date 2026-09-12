import 'package:allah_everywhere/prayer_timing.dart';
import 'package:allah_everywhere/quran.dart';
import 'package:allah_everywhere/seerat.dart';
import 'package:allah_everywhere/widgets/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:allah_everywhere/widgets/IconButtonWidget.dart';
import 'package:allah_everywhere/widgets/MosqueCardWidget.dart';
import 'package:allah_everywhere/widgets/NamazTimingWidget.dart';
import 'package:allah_everywhere/qibla.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/controllers/prayer_times_controller.dart';
import 'package:allah_everywhere/services/nearby_mosque_service.dart';
import 'package:allah_everywhere/data/daily_reminder_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // PrayerTimesController sets latitude then longitude as two separate
    // Rx assignments, so listening to only one of them can fire while the
    // other is still null (e.g. latitude changes, its listener runs
    // immediately, but longitude hasn't been assigned yet on the next
    // line) - the guard below then bails and nothing ever retries.
    // Listening to both means whichever assignment happens *second* will
    // always see both values already set.
    ever(controller.latitude, (_) => _maybeFetchNearbyMosques());
    ever(controller.longitude, (_) => _maybeFetchNearbyMosques());
    // Also covers the case where the location already resolved before this
    // screen (and these listeners) existed - PrayerTimesController is a
    // persistent singleton that starts fetching on app start, while Home
    // only mounts once inside the bottom nav's IndexedStack, so `ever`
    // alone would miss an assignment that already happened.
    _maybeFetchNearbyMosques();
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
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => controller.fetchLocationAndTimes(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  child: _buildHeaderCard(isDark, t),
                ),
                SizedBox(height: 18.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildSectionCard(
                    isDark: isDark,
                    child: Obx(() => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _prayerChip('Fajr', controller.fajrTime.value, Iconsax.cloud_sunny),
                              SizedBox(width: 8.w),
                              _prayerChip('Dhuhr', controller.dhuhrTime.value, Iconsax.sun),
                              SizedBox(width: 8.w),
                              _prayerChip('Asr', controller.asrTime.value, Iconsax.sun_1),
                              SizedBox(width: 8.w),
                              _prayerChip('Maghrib', controller.maghribTime.value, Iconsax.sun_fog),
                              SizedBox(width: 8.w),
                              _prayerChip('Isha', controller.ishaTime.value, Iconsax.moon),
                            ],
                          ),
                        )),
                  ),
                ),
                SizedBox(height: 18.h),

                // Quick access grid
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildSectionCard(
                    isDark: isDark,
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      mainAxisSpacing: 14.h,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        GestureDetector(
                            onTap: () => Get.to(() => QuranScreen()),
                            child: IconButtonWidget(icon: Iconsax.book_saved, title: t.quran)),
                        GestureDetector(
                            onTap: () => Get.to(() => HadithScreen()),
                            child: IconButtonWidget(icon: Iconsax.book_1, title: t.hadith)),
                        GestureDetector(
                          onTap: () => Get.to(() => DuaScreen()),
                          child: IconButtonWidget(icon: Iconsax.heart, title: t.dua),
                        ),
                        GestureDetector(
                            onTap: () => Get.to(() => QiblaScreen()),
                            child: IconButtonWidget(icon: Iconsax.discover, title: t.qibla)),
                        GestureDetector(
                          onTap: () => Get.to(() => FiqhScreen()),
                          child: IconButtonWidget(icon: Iconsax.judge, title: t.fiqh),
                        ),
                        GestureDetector(
                            onTap: () => Get.to(() => SeeratScreen()),
                            child: IconButtonWidget(icon: Iconsax.book_square, title: t.seerat)),
                        GestureDetector(
                            onTap: () => Get.to(() => PrayerTimingScreen()),
                            child: IconButtonWidget(icon: Iconsax.clock, title: t.prayer)),
                        GestureDetector(
                            onTap: () => Get.to(() => AskAiScreen()),
                            child: IconButtonWidget(icon: Iconsax.message_question, title: t.askAi)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildDailyReminderBanner(isDark, t),
                ),
                SizedBox(height: 18.h),

                // Nearby Masjid Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.nearbyMasjids,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Obx(() => _buildNearbyMosques(isDark)),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _prayerChip(String name, String time, IconData icon) {
    final isNext = controller.nextPrayerName.value == name;
    return NamazTimingWidget(name: name, time: time, icon: icon, isNext: isNext);
  }

  Widget _buildHeaderCard(bool isDark, AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mosque, color: Colors.white70, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                'Allah Everywhere',
                style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.to(() => SearchScreen()),
                child: Icon(Iconsax.search_normal, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 16.w),
              GestureDetector(
                onTap: () => Get.to(() => NotificationsScreen()),
                child: Icon(Iconsax.notification, color: Colors.white, size: 20.sp),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Obx(() => _buildPrayerSummary(t)),
        ],
      ),
    );
  }

  Widget _buildDailyReminderBanner(bool isDark, AppLocalizations t) {
    final reminder = reminderForDay(DateTime.now());
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
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
              Icon(
                reminder.isHadith ? Iconsax.book_1 : Iconsax.book_saved,
                size: 16.sp,
                color: accent,
              ),
              SizedBox(width: 6.w),
              Text(
                reminder.isHadith ? t.hadithOfTheDay : t.verseOfTheDay,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: accent),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            reminder.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              height: 1.6,
              color: isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            reminder.translation,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.4,
              color: isDark ? VoidColors.textDarkSecondary : VoidColors.oliveDeep.withOpacity(0.85),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            reminder.reference,
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: accent),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerSummary(AppLocalizations t) {
    if (controller.locationError.value.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.locationError.value,
            style: TextStyle(fontSize: 12.sp, color: Colors.white),
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
                color: VoidColors.goldDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.yourLocation,
          style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 3.h),
        Text(
          controller.location.value,
          style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              controller.nextPrayerName.value.isEmpty ? '...' : controller.nextPrayerName.value,
              style: TextStyle(color: VoidColors.goldDark, fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 10.w),
            Text(
              controller.nextPrayerTime.value,
              style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          '${t.nextPrayerIn} ${controller.remainingTime.value}',
          style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Icon(Iconsax.calendar_1, size: 13.sp, color: Colors.white70),
            SizedBox(width: 6.w),
            Text(
              controller.islamicDate.value.isEmpty ? '...' : controller.islamicDate.value,
              style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 10.w),
            Text(
              controller.gregorianDate.value.isEmpty ? '' : '· ${controller.gregorianDate.value}',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNearbyMosques(bool isDark) {
    final t = AppLocalizations.of(context)!;
    final mutedColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade700;
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
                style: TextStyle(fontSize: 13.sp, color: mutedColor),
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
        style: TextStyle(fontSize: 13.sp, color: mutedColor),
      );
    }
    if (_mosqueLookupFailed) {
      return Row(
        children: [
          Expanded(
            child: Text(
              t.couldNotReachMosqueDirectory,
              style: TextStyle(fontSize: 13.sp, color: mutedColor),
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
        style: TextStyle(fontSize: 13.sp, color: mutedColor),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _nearbyMosques!
            .map((mosque) => MosqueCardWidget(
                  name: mosque.name,
                  location: '${mosque.distanceKm.toStringAsFixed(1)} km away',
                  onTap: () => _openMosqueInMaps(mosque),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _openMosqueInMaps(NearbyMosque mosque) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${mosque.latitude},${mosque.longitude}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps app.')),
      );
    }
  }
}
