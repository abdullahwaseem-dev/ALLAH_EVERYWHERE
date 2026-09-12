import 'package:adhan/adhan.dart';
import 'package:allah_everywhere/privacy_policy.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/controllers/theme_controller.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/controllers/prayer_times_controller.dart';
import 'package:allah_everywhere/services/local_notifications_service.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: SafeArea(
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
                    SizedBox(height: 110.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
    return InkWell(
      onTap: enabled ? onTap : null,
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
    return Container(
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
    );
  }
}
