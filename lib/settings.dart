import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:allah_everywhere/privacy_policy.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/controllers/theme_controller.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/controllers/prayer_times_controller.dart';
import 'package:allah_everywhere/services/local_notifications_service.dart';
import 'package:allah_everywhere/services/push_notification_service.dart';
import 'package:allah_everywhere/services/quran_audio_service.dart';
import 'package:allah_everywhere/services/islamic_calendar_service.dart';
import 'package:allah_everywhere/services/adhkar_service.dart';
import 'package:allah_everywhere/data/reciters_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:allah_everywhere/services/app_share_service.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';

import 'change_password_screen.dart';
import 'editprofilescreen.dart';
import 'help_faq.dart';
import 'adhan_sound_settings.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _updatesKey = 'updates_enabled';
  static const _regionKey = 'selected_region';

  final ThemeController _themeController = Get.find<ThemeController>();
  final LanguageController _languageController = Get.find<LanguageController>();
  final LocalNotificationsService _notificationsService = LocalNotificationsService();
  final List<String> countries = [
    'Pakistan', 'India', 'United States', 'Canada', 'Brazil', 'Australia', 'China', 'Russia', 'Japan', 'South Korea',
    'United Kingdom', 'Germany', 'France', 'Italy', 'Mexico', 'Indonesia', 'Turkey', 'Spain', 'Saudi Arabia', 'Argentina',
    'South Africa', 'Egypt', 'Nigeria', 'Thailand', 'Ukraine', 'Poland', 'Vietnam', 'Colombia', 'Kenya', 'Peru',
    'Malaysia', 'Israel', 'Singapore', 'Philippines', 'Bangladesh', 'Romania', 'Chile', 'Iraq', 'Afghanistan', 'Sudan',
    'Algeria', 'Morocco', 'Uzbekistan', 'Venezuela', 'Greece', 'Portugal', 'Sweden', 'Norway', 'Finland',
    'Denmark', 'Switzerland', 'Netherlands', 'Belgium', 'Austria', 'Ireland', 'Czech Republic', 'Hungary', 'New Zealand'
  ];

  String? _selectedRegion;
  bool _notificationsEnabled = true;
  bool _updatesEnabled = false;
  bool _challengeNotifications = PushNotificationService.challengeNotificationsEnabled;
  bool _quranReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _jumuahReminderEnabled = true;
  TimeOfDay _jumuahReminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _jumuahAsrReminderEnabled = false;
  int _hijriAdjustment = 0;
  bool _whiteDaysReminder = false;
  bool _mondayThursdayReminder = false;
  bool _importantDatesReminder = true;
  bool _morningAdhkarReminder = false;
  bool _eveningAdhkarReminder = false;
  String _selectedReciterId = 'ar.alafasy';

  @override
  void initState() {
    super.initState();
    _selectedRegion = VoidStorage().readData<String>(_regionKey);
    _notificationsEnabled = _notificationsService.notificationsEnabled;
    _quranReminderEnabled = _notificationsService.quranReminderEnabled;
    _reminderTime = _notificationsService.reminderTime;
    _jumuahReminderEnabled = _notificationsService.jumuahReminderEnabled;
    _jumuahReminderTime = _notificationsService.jumuahReminderTime;
    _jumuahAsrReminderEnabled = _notificationsService.jumuahAsrReminderEnabled;
    _hijriAdjustment = IslamicCalendarService.adjustment;
    _whiteDaysReminder = IslamicCalendarService.whiteDaysReminder;
    _mondayThursdayReminder = IslamicCalendarService.mondayThursdayReminder;
    _importantDatesReminder = IslamicCalendarService.importantDatesReminder;
    _morningAdhkarReminder = AdhkarService.morningReminderEnabled;
    _eveningAdhkarReminder = AdhkarService.eveningReminderEnabled;
    _updatesEnabled = VoidStorage().readData<bool>(_updatesKey) ?? false;
    _selectedReciterId = QuranAudioService.selectedReciterId;
  }

  void _showReciterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Reciter'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: availableReciters.map((reciter) {
                final selected = reciter.editionId == _selectedReciterId;
                return ListTile(
                  title: Text(reciter.name),
                  subtitle: Text(reciter.arabicName),
                  trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () async {
                    setState(() => _selectedReciterId = reciter.editionId);
                    await QuranAudioService.setSelectedReciter(reciter.editionId);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  String _signedDays(int days) => days > 0 ? '+$days' : '$days';

  void _showHijriAdjustmentDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.hijriAdjustment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.hijriAdjustmentSubtitle),
            SizedBox(height: 8.h),
            for (int days = IslamicCalendarService.minAdjustment; days <= IslamicCalendarService.maxAdjustment; days++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(days == 0 ? t.hijriAdjustmentNone : _signedDays(days)),
                trailing: days == _hijriAdjustment ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => _hijriAdjustment = days);
                  await IslamicCalendarService.setAdjustment(days);
                  if (Get.isRegistered<PrayerTimesController>()) {
                    Get.find<PrayerTimesController>().refreshIslamicDate();
                  }
                  await _notificationsService.scheduleIslamicCalendarReminders();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _setCalendarReminder(String key, bool value, void Function(bool) apply) async {
    setState(() => apply(value));
    await VoidStorage().saveData(key, value);
    await _notificationsService.scheduleIslamicCalendarReminders();
  }

  Future<void> _setAdhkarReminder(String key, bool value, void Function(bool) apply) async {
    setState(() => apply(value));
    await VoidStorage().saveData(key, value);
    await _notificationsService.scheduleAdhkarReminders();
  }

  Future<void> _contactForAppreciation(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'maw112266@gmail.com',
      query: 'subject=${Uri.encodeComponent('Appreciation for Allah Everywhere')}',
    );
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open an email app. Please email maw112266@gmail.com directly.')),
      );
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.selectLanguage),
          content: SizedBox(
            width: double.maxFinite,
            child: Obx(() => ListView(
                  shrinkWrap: true,
                  children: supportedAppLanguages.map((lang) {
                    final selected = _languageController.locale.value.languageCode == lang.code;
                    return ListTile(
                      title: Text(lang.nativeName),
                      subtitle: Text(lang.englishName),
                      trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
                      onTap: () {
                        _languageController.setLanguage(lang.code);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                )),
          ),
        );
      },
    );
  }

  void _showRegionDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.selectRegion),
          content: DropdownButton<String>(
            isExpanded: true,
            hint: Text(t.selectRegion),
            value: _selectedRegion,
            onChanged: (String? newValue) {
              setState(() => _selectedRegion = newValue);
              VoidStorage().saveData(_regionKey, newValue);
              Navigator.pop(context);
            },
            items: countries.map<DropdownMenuItem<String>>((String country) {
              return DropdownMenuItem<String>(value: country, child: Text(country));
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCalculationDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final prayerController = Get.isRegistered<PrayerTimesController>()
        ? Get.find<PrayerTimesController>()
        : Get.put(PrayerTimesController(), permanent: true);

    showDialog(
      context: context,
      builder: (context) {
        CalculationMethod? method = prayerController.manualCalculationMethod;
        var madhab = prayerController.madhab;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(t.calculationMethodAndMadhab),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calculation Method', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<CalculationMethod?>(
                    isExpanded: true,
                    value: method,
                    onChanged: (value) => setDialogState(() => method = value),
                    items: [
                      // null = pick by the user's country.
                      DropdownMenuItem<CalculationMethod?>(
                        value: null,
                        child: Text(t.calculationAutomatic(prayerController.automaticCalculationMethod.name)),
                      ),
                      ...CalculationMethod.values
                          .map((m) => DropdownMenuItem<CalculationMethod?>(value: m, child: Text(m.name))),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text('Madhab (Asr)', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<Madhab>(
                    isExpanded: true,
                    value: madhab,
                    onChanged: (value) {
                      if (value != null) setDialogState(() => madhab = value);
                    },
                    items: Madhab.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    prayerController.manualCalculationMethod = method;
                    prayerController.madhab = madhab;
                    Navigator.pop(context);
                  },
                  child: Text(t.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: ReadableWidth(child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Center(
                child: Text(
                  t.settingsTitle,
                  style: TextStyle(color: textColor, fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      isDark: isDark,
                      accent: accent,
                      icon: Iconsax.profile_circle,
                      title: t.account,
                      children: [
                        _NavRow(label: t.editProfile, textColor: textColor, onTap: () => Get.to(EditProfileScreen())),
                        _NavRow(
                            label: t.changePassword,
                            textColor: textColor,
                            onTap: () => Get.to(() => ChangePasswordScreen())),
                        _NavRow(
                            label: t.privacy,
                            textColor: textColor,
                            onTap: () => Get.to(() => PrivacyPolicyScreen()),
                            isLast: true),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _SectionCard(
                      isDark: isDark,
                      accent: accent,
                      icon: Iconsax.clock,
                      title: t.prayerSection,
                      children: [
                        _NavRow(
                          label: t.calculationMethodAndMadhab,
                          subtitle: t.calculationMethodSubtitle,
                          textColor: textColor,
                          subColor: subColor,
                          onTap: () => _showCalculationDialog(context),
                        ),
                        _NavRow(
                          label: t.hijriAdjustment,
                          subtitle: t.hijriAdjustmentSubtitle,
                          trailing: _hijriAdjustment == 0 ? '0' : _signedDays(_hijriAdjustment),
                          textColor: textColor,
                          subColor: subColor,
                          onTap: () => _showHijriAdjustmentDialog(context),
                          isLast: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _SectionCard(
                      isDark: isDark,
                      accent: accent,
                      icon: Iconsax.notification,
                      title: t.notificationSection,
                      children: [
                        _SwitchRow(
                          label: t.notification,
                          subtitle: t.notificationSubtitle,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          value: _notificationsEnabled,
                          onChanged: (value) async {
                            setState(() => _notificationsEnabled = value);
                            await VoidStorage().saveData(
                              LocalNotificationsService.notificationsEnabledKey,
                              value,
                            );
                            if (value) {
                              if (Get.isRegistered<PrayerTimesController>()) {
                                await Get.find<PrayerTimesController>().rescheduleNotifications();
                              }
                              await _notificationsService.scheduleDailyQuranReminder();
                              await _notificationsService.scheduleJumuahReminders();
                              await _notificationsService.scheduleIslamicCalendarReminders();
                              await _notificationsService.scheduleChallengeReminders();
                            } else {
                              await _notificationsService.cancelAll();
                            }
                          },
                        ),
                        _NavRow(
                          label: t.adhanSound,
                          subtitle: t.adhanSoundSubtitle,
                          textColor: textColor,
                          subColor: subColor,
                          enabled: _notificationsEnabled,
                          onTap: () => Get.to(() => const AdhanSoundSettingsScreen()),
                        ),
                        _SwitchRow(
                          label: t.dailyQuranReminder,
                          subtitle: '${t.reminderTime}: ${_reminderTime.format(context)}',
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          value: _quranReminderEnabled,
                          onChanged: !_notificationsEnabled
                              ? null
                              : (value) async {
                                  setState(() => _quranReminderEnabled = value);
                                  await _notificationsService.setQuranReminderEnabled(value);
                                },
                        ),
                        _NavRow(
                          label: t.reminderTime,
                          trailing: _reminderTime.format(context),
                          textColor: textColor,
                          enabled: _notificationsEnabled && _quranReminderEnabled,
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: _reminderTime);
                            if (picked != null) {
                              setState(() => _reminderTime = picked);
                              await _notificationsService.setReminderTime(picked);
                            }
                          },
                        ),
                        _SwitchRow(
                          label: t.jumuahReminderSetting,
                          subtitle: t.jumuahReminderSubtitle,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          value: _jumuahReminderEnabled,
                          onChanged: !_notificationsEnabled
                              ? null
                              : (value) async {
                                  setState(() => _jumuahReminderEnabled = value);
                                  await _notificationsService.setJumuahReminderEnabled(value);
                                },
                        ),
                        _NavRow(
                          label: t.jumuahReminderTime,
                          trailing: _jumuahReminderTime.format(context),
                          textColor: textColor,
                          enabled: _notificationsEnabled && _jumuahReminderEnabled,
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: _jumuahReminderTime);
                            if (picked != null) {
                              setState(() => _jumuahReminderTime = picked);
                              await _notificationsService.setJumuahReminderTime(picked);
                            }
                          },
                        ),
                        _SwitchRow(
                          label: t.jumuahAsrReminderSetting,
                          subtitle: _jumuahAsrReminderEnabled && !_notificationsService.hasPrayerLocation
                              ? t.jumuahAsrNeedsLocation
                              : t.jumuahAsrReminderSubtitle,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          value: _jumuahAsrReminderEnabled,
                          onChanged: !_notificationsEnabled
                              ? null
                              : (value) async {
                                  setState(() => _jumuahAsrReminderEnabled = value);
                                  await _notificationsService.setJumuahAsrReminderEnabled(value);
                                },
                        ),
                        _SwitchRow(
                          label: t.importantDatesReminder,
                          subtitle: t.importantDatesReminderSubtitle,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          value: _importantDatesReminder,
                          onChanged: !_notificationsEnabled
                              ? null
                              : (value) => _setCalendarReminder(IslamicCalendarService.importantDatesReminderKey,
                                  value, (v) => _importantDatesReminder = v),
                        ),
                        _SwitchRow(
                          label: t.whiteDaysReminder,
                          subtitle: t.whiteDaysReminderSubtitle,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          value: _whiteDaysReminder,
                          onChanged: !_notificationsEnabled
                              ? null
                              : (value) => _setCalendarReminder(IslamicCalendarService.whiteDaysReminderKey, value,
                                  (v) => _whiteDaysReminder = v),
                        ),
                        _SwitchRow(
                          label: t.mondayThursdayReminder,
                          subtitle: t.mondayThursdayReminderSubtitle,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          value: _mondayThursdayReminder,
                          onChanged: !_notificationsEnabled
                              ? null
                              : (value) => _setCalendarReminder(IslamicCalendarService.mondayThursdayReminderKey,
                                  value, (v) => _mondayThursdayReminder = v),
                        ),
                        _SwitchRow(
                          label: t.morningAdhkarReminder,
                          subtitle: _morningAdhkarReminder && !_notificationsService.hasPrayerLocation
                              ? t.adhkarNeedsLocation
                              : t.morningAdhkarReminderSubtitle,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          value: _morningAdhkarReminder,
                          onChanged: !_notificationsEnabled
                              ? null
                              : (value) => _setAdhkarReminder(
                                  AdhkarService.morningReminderKey, value, (v) => _morningAdhkarReminder = v),
                        ),
                        _SwitchRow(
                          label: t.eveningAdhkarReminder,
                          subtitle: _eveningAdhkarReminder && !_notificationsService.hasPrayerLocation
                              ? t.adhkarNeedsLocation
                              : t.eveningAdhkarReminderSubtitle,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          value: _eveningAdhkarReminder,
                          onChanged: !_notificationsEnabled
                              ? null
                              : (value) => _setAdhkarReminder(
                                  AdhkarService.eveningReminderKey, value, (v) => _eveningAdhkarReminder = v),
                        ),
                        _SwitchRow(
                          label: t.challengesNotificationsSetting,
                          subtitle: t.challengesNotificationsSubtitle,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          value: _challengeNotifications,
                          onChanged: (value) {
                            setState(() => _challengeNotifications = value);
                            PushNotificationService().setChallengeNotifications(value);
                          },
                        ),
                        _SwitchRow(
                          label: t.updates,
                          subtitle: t.updatesSubtitle,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          value: _updatesEnabled,
                          onChanged: (value) {
                            setState(() => _updatesEnabled = value);
                            VoidStorage().saveData(_updatesKey, value);
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _SectionCard(
                      isDark: isDark,
                      accent: accent,
                      icon: Iconsax.book_1,
                      title: 'Quran',
                      children: [
                        _NavRow(
                          label: 'Reciter',
                          trailing: reciterFor(_selectedReciterId).name,
                          textColor: textColor,
                          subColor: subColor,
                          onTap: () => _showReciterDialog(context),
                          isLast: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _SectionCard(
                      isDark: isDark,
                      accent: accent,
                      icon: Iconsax.setting_2,
                      title: t.otherSection,
                      children: [
                        Obx(() => _SwitchRow(
                              label: t.darkMode,
                              textColor: textColor,
                              subColor: subColor,
                              accent: accent,
                              value: _themeController.isDarkMode,
                              onChanged: (value) => _themeController.setDarkMode(value),
                            )),
                        Obx(() {
                          final current = supportedAppLanguages.firstWhere(
                            (l) => l.code == _languageController.locale.value.languageCode,
                            orElse: () => supportedAppLanguages.first,
                          );
                          return _NavRow(
                            label: t.language,
                            trailing: current.nativeName,
                            textColor: textColor,
                            onTap: () => _showLanguageDialog(context),
                          );
                        }),
                        _NavRow(
                          label: t.region,
                          trailing: _selectedRegion ?? t.selectRegion,
                          textColor: textColor,
                          onTap: () => _showRegionDialog(context),
                          isLast: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _SectionCard(
                      isDark: isDark,
                      accent: accent,
                      icon: Iconsax.heart,
                      title: 'Support',
                      children: [
                        _NavRow(
                          label: 'Rate the App',
                          subtitle: 'Enjoying Allah Everywhere? A rating on the ${Platform.isIOS ? 'App Store' : 'Play Store'} helps others find it.',
                          textColor: textColor,
                          subColor: subColor,
                          onTap: () => AppShareService.rateApp(context),
                        ),
                        _NavRow(
                          label: 'Share the App',
                          subtitle: 'Invite friends and family to use Allah Everywhere.',
                          textColor: textColor,
                          subColor: subColor,
                          onTap: () => AppShareService.shareApp(context),
                        ),
                        _NavRow(
                          label: 'Help & FAQ',
                          textColor: textColor,
                          subColor: subColor,
                          onTap: () => Get.to(() => HelpFaqScreen()),
                        ),
                        _NavRow(
                          label: 'Support the Developer',
                          subtitle: 'If this app has benefited you and you\'d like to give '
                              'something back, reach out by email - no in-app purchase needed.',
                          textColor: textColor,
                          subColor: subColor,
                          onTap: () => _contactForAppreciation(context),
                          isLast: true,
                        ),
                      ],
                    ),
                    SizedBox(height: navBarClearance(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.isDark,
    required this.accent,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String? trailing;
  final Color textColor;
  final Color? subColor;
  final VoidCallback onTap;
  final bool enabled;
  final bool isLast;

  const _NavRow({
    required this.label,
    this.subtitle,
    this.trailing,
    required this.textColor,
    this.subColor,
    required this.onTap,
    this.enabled = true,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressableTile(
      onTap: enabled ? onTap : null,
      semanticLabel: label,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: isLast
            ? null
            : BoxDecoration(border: Border(bottom: BorderSide(color: textColor.withOpacity(0.08)))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      color: enabled ? textColor : textColor.withOpacity(0.4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(subtitle!, style: TextStyle(fontSize: 11.5.sp, color: subColor)),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Text(trailing!, style: TextStyle(fontSize: 12.5.sp, color: subColor ?? textColor)),
            SizedBox(width: 4.w),
            Icon(Iconsax.arrow_right_3, size: 14.sp, color: subColor ?? textColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Color textColor;
  final Color subColor;
  final Color accent;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isLast;

  const _SwitchRow({
    required this.label,
    this.subtitle,
    required this.textColor,
    required this.subColor,
    required this.accent,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return PressableTile(
      onTap: enabled ? () => onChanged!(!value) : null,
      semanticLabel: label,
      child: Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: isLast
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: textColor.withOpacity(0.08)))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    color: enabled ? textColor : textColor.withOpacity(0.4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(subtitle!, style: TextStyle(fontSize: 11.5.sp, color: subColor)),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: accent),
        ],
      ),
      ),
    );
  }
}
