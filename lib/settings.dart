import 'package:adhan/adhan.dart';
import 'package:allah_everywhere/privacy_policy.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/widgets/themed_background.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/controllers/theme_controller.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/controllers/prayer_times_controller.dart';
import 'package:allah_everywhere/services/local_notifications_service.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'change_password_screen.dart';
import 'editprofilescreen.dart';

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
  bool _quranReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _selectedRegion = VoidStorage().readData<String>(_regionKey);
    _notificationsEnabled = _notificationsService.notificationsEnabled;
    _quranReminderEnabled = _notificationsService.quranReminderEnabled;
    _reminderTime = _notificationsService.reminderTime;
    _updatesEnabled = VoidStorage().readData<bool>(_updatesKey) ?? false;
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
        : Get.put(PrayerTimesController());

    showDialog(
      context: context,
      builder: (context) {
        var method = prayerController.calculationMethod;
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
                  DropdownButton<CalculationMethod>(
                    isExpanded: true,
                    value: method,
                    onChanged: (value) {
                      if (value != null) setDialogState(() => method = value);
                    },
                    items: CalculationMethod.values
                        .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                        .toList(),
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
                    prayerController.calculationMethod = method;
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
    return Scaffold(
      body: Stack(
        children: [
          ThemedBackground(lightImagePath: VoidImages.otherscreen_background, fit: BoxFit.cover),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(color: Colors.transparent),
                  child: Center(
                    child: Text(
                      t.settingsTitle,
                      style: TextStyle(color: Colors.black, fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(title: t.account, icon: Icons.account_circle),
                        ListTile(
                          title: Text(t.editProfile),
                          onTap: () => Get.to(EditProfileScreen()),
                        ),
                        ListTile(
                          title: Text(t.changePassword),
                          onTap: () => Get.to(() => ChangePasswordScreen()),
                        ),
                        ListTile(
                          title: Text(t.privacy),
                          onTap: () => Get.to(() => PrivacyPolicyScreen()),
                        ),
                        Divider(),

                        SectionTitle(title: t.prayerSection, icon: Icons.access_time),
                        ListTile(
                          title: Text(t.calculationMethodAndMadhab),
                          subtitle: Text(t.calculationMethodSubtitle),
                          onTap: () => _showCalculationDialog(context),
                        ),
                        Divider(),

                        SectionTitle(title: t.notificationSection, icon: Icons.notifications),
                        SwitchListTile(
                          title: Text(t.notification),
                          subtitle: Text(t.notificationSubtitle),
                          value: _notificationsEnabled,
                          onChanged: (value) async {
                            setState(() => _notificationsEnabled = value);
                            await VoidStorage().saveData(
                              LocalNotificationsService.notificationsEnabledKey,
                              value,
                            );
                            if (value) {
                              final prayerController = Get.isRegistered<PrayerTimesController>()
                                  ? Get.find<PrayerTimesController>()
                                  : null;
                              if (prayerController != null) {
                                await _notificationsService
                                    .reschedulePrayerNotifications(prayerController.prayerDateTimes.value);
                              }
                              await _notificationsService.scheduleDailyQuranReminder();
                            } else {
                              await _notificationsService.cancelAll();
                            }
                          },
                        ),
                        SwitchListTile(
                          title: Text(t.dailyQuranReminder),
                          subtitle: Text('${t.reminderTime}: ${_reminderTime.format(context)}'),
                          value: _quranReminderEnabled,
                          onChanged: !_notificationsEnabled
                              ? null
                              : (value) async {
                                  setState(() => _quranReminderEnabled = value);
                                  await _notificationsService.setQuranReminderEnabled(value);
                                },
                        ),
                        ListTile(
                          title: Text(t.reminderTime),
                          trailing: Text(_reminderTime.format(context)),
                          enabled: _notificationsEnabled && _quranReminderEnabled,
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: _reminderTime);
                            if (picked != null) {
                              setState(() => _reminderTime = picked);
                              await _notificationsService.setReminderTime(picked);
                            }
                          },
                        ),
                        SwitchListTile(
                          title: Text(t.updates),
                          subtitle: Text(t.updatesSubtitle),
                          value: _updatesEnabled,
                          onChanged: (value) {
                            setState(() => _updatesEnabled = value);
                            VoidStorage().saveData(_updatesKey, value);
                          },
                        ),
                        Divider(),

                        SectionTitle(title: t.otherSection, icon: Icons.settings),
                        Obx(() => SwitchListTile(
                              title: Text(t.darkMode),
                              value: _themeController.isDarkMode,
                              onChanged: (value) => _themeController.setDarkMode(value),
                            )),
                        Obx(() {
                          final current = supportedAppLanguages.firstWhere(
                            (l) => l.code == _languageController.locale.value.languageCode,
                            orElse: () => supportedAppLanguages.first,
                          );
                          return ListTile(
                            title: Text(t.language),
                            trailing: Text(current.nativeName),
                            onTap: () => _showLanguageDialog(context),
                          );
                        }),
                        ListTile(
                          title: Text(t.region),
                          trailing: Text(_selectedRegion ?? t.selectRegion),
                          onTap: () => _showRegionDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
