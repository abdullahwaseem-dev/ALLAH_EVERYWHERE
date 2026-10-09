import 'package:allah_everywhere/prayer_timing.dart';
import 'package:allah_everywhere/quran.dart';
import 'package:allah_everywhere/seerat.dart';
import 'package:allah_everywhere/widgets/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:allah_everywhere/widgets/IconButtonWidget.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/ask_ai_fab.dart';
import 'package:allah_everywhere/widgets/ask_ai_prompt_bar.dart';
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
import 'package:allah_everywhere/widgets/banner_ad_widget.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/share_cards/share_strings.dart';
import 'package:allah_everywhere/share_cards/share_studio_screen.dart';
import 'package:allah_everywhere/services/local_notifications_service.dart';
import 'package:allah_everywhere/data/jumuah_data.dart';
import 'package:allah_everywhere/data/asma_ul_husna_data.dart';
import 'package:allah_everywhere/asma_ul_husna.dart';
import 'package:allah_everywhere/zakat.dart';
import 'package:allah_everywhere/islamic_calendar.dart';
import 'package:allah_everywhere/adhkar.dart';
import 'package:allah_everywhere/challenges.dart';
import 'package:allah_everywhere/hajj_umrah.dart';
import 'package:allah_everywhere/prophet_stories.dart';
import 'package:allah_everywhere/services/prophet_stories_service.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:async';
import 'package:allah_everywhere/hifz_dashboard.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:quran/quran.dart' as quran;

import 'ask_ai.dart';
import 'dua.dart';
import 'fiqh.dart';
import 'hadith.dart';
import 'notification.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Permanent: this controller is the app-wide prayer clock (countdown +
  // Adhan scheduling). Owned by a route, GetX deleted it - cancelling its
  // timer - whenever that route was replaced, freezing the countdown at
  // 00:00:00 for the screen that picked it up next.
  final PrayerTimesController controller = Get.isRegistered<PrayerTimesController>()
      ? Get.find<PrayerTimesController>()
      : Get.put(PrayerTimesController(), permanent: true);
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
    // If a notification (e.g. the Friday Al-Kahf reminder) launched the app,
    // open its target now that the splash/login flow has finished.
    WidgetsBinding.instance.addPostFrameCallback((_) => LocalNotificationsService().consumeLaunchPayload());
    // Same for a home screen widget tap (cold start), and later taps.
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_openFromWidget).catchError((_) {});
    _widgetClicks = HomeWidget.widgetClicked.listen(_openFromWidget, onError: (_) {});
  }

  StreamSubscription<Uri?>? _widgetClicks;

  @override
  void dispose() {
    _widgetClicks?.cancel();
    super.dispose();
  }

  /// Home screen widgets open allaheverywhere://prayer or ://calendar; the
  /// Verse of the Day widget just opens the app (Home shows the same entry).
  void _openFromWidget(Uri? uri) {
    if (!mounted || uri == null) return;
    switch (uri.host) {
      case 'prayer':
        Get.to(() => const PrayerTimingScreen());
      case 'calendar':
        Get.to(() => const IslamicCalendarScreen());
    }
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
    return AskAiFabHost(
      showFirstLaunchHint: true,
      // The banner ad is the last thing on Home (above the nav-bar
      // clearance). Hide the button whenever that end of the page is on
      // screen so it never covers the ad (ads are at most ~100pt tall).
      hideNearEndExtent: navBarClearance(context) + 130,
      child: Scaffold(
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
                // One column on phones; two side by side on iPad.
                ..._homeColumns(
                  left: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                      child: _buildHeaderCard(isDark, t),
                    ),
                    SizedBox(height: 12.h),
                    if (DateTime.now().weekday == DateTime.friday) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: _buildJumuahCard(isDark, t),
                      ),
                      SizedBox(height: 12.h),
                    ],
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: AskAiPromptBar(
                        onTap: () => Get.to(() => const AskAiScreen(autofocus: true)),
                      ),
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
                          // Taller than square so a 2-line label fits at 1.3x text.
                          childAspectRatio: 0.8,
                          shrinkWrap: true,
                          mainAxisSpacing: 14.h,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            PressableTile(
                                onTap: () => Get.to(() => QuranScreen()),
                                semanticLabel: t.quran,
                                child: IconButtonWidget(icon: Iconsax.book_saved, title: t.quran)),
                            PressableTile(
                                onTap: () => Get.to(() => HadithScreen()),
                                semanticLabel: t.hadith,
                                child: IconButtonWidget(icon: Iconsax.book_1, title: t.hadith)),
                            PressableTile(
                              onTap: () => Get.to(() => DuaScreen()),
                              semanticLabel: t.dua,
                              child: IconButtonWidget(icon: Iconsax.heart, title: t.dua)),
                            PressableTile(
                                onTap: () => Get.to(() => QiblaScreen()),
                                semanticLabel: t.qibla,
                                child: IconButtonWidget(icon: Iconsax.discover, title: t.qibla)),
                            PressableTile(
                              onTap: () => Get.to(() => FiqhScreen()),
                              semanticLabel: t.fiqh,
                              child: IconButtonWidget(icon: Iconsax.judge, title: t.fiqh)),
                            PressableTile(
                                onTap: () => Get.to(() => SeeratScreen()),
                                semanticLabel: t.seerat,
                                child: IconButtonWidget(icon: Iconsax.book_square, title: t.seerat)),
                            PressableTile(
                                onTap: () => Get.to(() => PrayerTimingScreen()),
                                semanticLabel: t.prayer,
                                child: IconButtonWidget(icon: Iconsax.clock, title: t.prayer)),
                            PressableTile(
                                onTap: () => Get.to(() => AskAiScreen()),
                                semanticLabel: t.askAi,
                                child: IconButtonWidget(icon: Iconsax.message_question, title: t.askAi)),
                            PressableTile(
                                onTap: () => Get.to(() => const AsmaUlHusnaScreen()),
                                semanticLabel: t.names99,
                                child: IconButtonWidget(icon: Iconsax.magic_star, title: t.names99)),
                            PressableTile(
                                onTap: () => Get.to(() => const ZakatScreen()),
                                semanticLabel: t.zakatTile,
                                child: IconButtonWidget(icon: Iconsax.wallet_money, title: t.zakatTile)),
                            PressableTile(
                                onTap: () => Get.to(() => const IslamicCalendarScreen()),
                                semanticLabel: t.calendarTile,
                                child: IconButtonWidget(icon: Iconsax.calendar_1, title: t.calendarTile)),
                            PressableTile(
                                onTap: () => Get.to(() => const AdhkarScreen()),
                                semanticLabel: t.adhkarTile,
                                child: IconButtonWidget(icon: Iconsax.sun_1, title: t.adhkarTile)),
                            PressableTile(
                                onTap: () => Get.to(() => const HifzDashboardScreen()),
                                semanticLabel: t.hifzTile,
                                child: IconButtonWidget(icon: Iconsax.teacher, title: t.hifzTile)),
                            PressableTile(
                                onTap: () => Get.to(() => const HajjUmrahScreen()),
                                semanticLabel: t.hajjTile,
                                child: IconButtonWidget(icon: Iconsax.building_3, title: t.hajjTile)),
                            if (ProphetStoriesService.enabled)
                            PressableTile(
                                onTap: () => Get.to(() => const ProphetStoriesScreen()),
                                semanticLabel: t.storiesTile,
                                child: IconButtonWidget(icon: Iconsax.archive_book, title: t.storiesTile)),
                            PressableTile(
                                onTap: () => Get.to(() => const ChallengesScreen()),
                                semanticLabel: t.challengesTile,
                                child: IconButtonWidget(icon: Iconsax.cup, title: t.challengesTile)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),
                  ],
                  right: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _buildShareStudioCard(isDark),
                    ),
                    SizedBox(height: 18.h),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _buildDailyReminderBanner(isDark, t),
                    ),
                    SizedBox(height: 18.h),
                    if (ProphetStoriesService.enabled)
                    StoryOfTheDayCard(padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 18.h)),
                    ActiveChallengeCard(padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 18.h)),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _buildNameOfTheDayCard(isDark, t),
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
                          Obx(() {
                            // Obx throws "improper use" if a build runs without
                            // reading an observable. Several branches of
                            // _buildNearbyMosques (loading, failed, loaded list)
                            // read none, so touch the location observables here -
                            // this both silences that error and keeps the section
                            // rebuilding when location/permission state changes.
                            controller.latitude.value;
                            controller.longitude.value;
                            controller.locationError.value;
                            controller.permissionPermanentlyDenied.value;
                            return _buildNearbyMosques(isDark);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                const Center(child: BannerAdWidget()),
                // Clearance so content can't end up hidden behind the
                // floating glass nav bar (Scaffold uses extendBody: true).
                SizedBox(height: navBarClearance(context)),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  /// Phones: [left] then [right] in one column. iPad / wide windows: two
  /// columns side by side (capped at 1100 wide) so the screen is used
  /// instead of stretching every card across it.
  List<Widget> _homeColumns({required List<Widget> left, required List<Widget> right}) {
    if (!isWideLayout(context)) return [...left, ...right];
    return [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: left)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [SizedBox(height: 12.h), ...right],
                ),
              ),
            ],
          ),
        ),
      ),
    ];
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

  Widget _buildShareStudioCard(bool isDark) {
    return Obx(() {
      final s = ShareStrings(Get.find<LanguageController>().locale.value.languageCode);
      return PressableTile(
        onTap: () => Get.to(() => const ShareStudioScreen()),
        semanticLabel: s.title,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0B1330), const Color(0xFF2D2A6E)]
                  : [VoidColors.gold, VoidColors.dustyRose],
            ),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.gallery_edit, color: Colors.white, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      s.homeSubtitle,
                      style: TextStyle(fontSize: 11.5.sp, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14.sp),
            ],
          ),
        ),
      );
    });
  }

  /// Friday-only shortcut to Surah Al-Kahf.
  Widget _buildJumuahCard(bool isDark, AppLocalizations t) {
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    return PressableTile(
      onTap: () => LocalNotificationsService.openSurah(jumuahSurahNumber),
      semanticLabel: '${t.jumuahCardTitle} - ${t.jumuahCardSubtitle}',
      borderRadius: BorderRadius.circular(18.r),
      child: Ink(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Iconsax.book_saved, color: accent, size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.jumuahCardTitle,
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    t.jumuahCardSubtitle,
                    style: TextStyle(fontSize: 11.5.sp, color: textColor.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
            Text(
              quran.getSurahNameArabic(jumuahSurahNumber),
              textDirection: TextDirection.rtl,
              style: ScriptureText.arabic(fontSize: 16.sp, color: accent),
            ),
            SizedBox(width: 6.w),
            Icon(Iconsax.arrow_right_3, size: 14.sp, color: accent),
          ],
        ),
      ),
    );
  }

  /// One of the 99 Names, rotating daily (day-of-year % 99).
  Widget _buildNameOfTheDayCard(bool isDark, AppLocalizations t) {
    final name = nameOfTheDay(DateTime.now());
    final languageCode = Localizations.localeOf(context).languageCode;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : VoidColors.oliveDeep.withValues(alpha: 0.85);
    final meaning = divineNameMeaning(name, languageCode);
    return PressableTile(
      onTap: () => Get.to(() => AsmaUlHusnaDetailScreen(name: name)),
      semanticLabel: '${t.nameOfTheDay}: ${name.transliteration}, $meaning',
      borderRadius: BorderRadius.circular(18.r),
      child: Ink(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.magic_star, size: 16.sp, color: accent),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    t.nameOfTheDay,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: accent),
                  ),
                ),
                Text('${name.number}/${asmaUlHusna.length}', style: TextStyle(fontSize: 11.sp, color: accent)),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.transliteration,
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        meaning,
                        style: languageCode == 'ur'
                            ? ScriptureText.urdu(fontSize: 12.5.sp, color: subColor)
                            : TextStyle(fontSize: 12.5.sp, height: 1.35, color: subColor),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name.arabic,
                      textDirection: TextDirection.rtl,
                      style: ScriptureText.arabic(fontSize: 26.sp, color: accent, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
        // Own Obx: the countdown ticks every second, and only this line
        // should rebuild, not the whole prayer summary.
        Obx(() => Text(
              '${t.nextPrayerIn} ${controller.remainingTime.value}',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.w600),
            )),
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
