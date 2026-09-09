import 'package:adhan/adhan.dart';
import 'package:allah_everywhere/privacy_policy.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/controllers/theme_controller.dart';
import 'package:allah_everywhere/controllers/prayer_times_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'change_password_screen.dart';
import 'editprofilescreen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _notificationsKey = 'notifications_enabled';
  static const _updatesKey = 'updates_enabled';
  static const _regionKey = 'selected_region';

  final ThemeController _themeController = Get.find<ThemeController>();
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

  @override
  void initState() {
    super.initState();
    _selectedRegion = VoidStorage().readData<String>(_regionKey);
    _notificationsEnabled = VoidStorage().readData<bool>(_notificationsKey) ?? true;
    _updatesEnabled = VoidStorage().readData<bool>(_updatesKey) ?? false;
  }

  void _showRegionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Region"),
          content: DropdownButton<String>(
            isExpanded: true,
            hint: Text("Choose your region"),
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
              title: Text('Prayer Calculation'),
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
                  child: Text('Save'),
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
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage(VoidImages.otherscreen_background), fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(color: Colors.transparent),
                  child: Center(
                    child: Text(
                      'Settings',
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
                        SectionTitle(title: 'Account', icon: Icons.account_circle),
                        ListTile(
                          title: Text('Edit Profile'),
                          onTap: () => Get.to(EditProfileScreen()),
                        ),
                        ListTile(
                          title: Text('Change Password'),
                          onTap: () => Get.to(() => ChangePasswordScreen()),
                        ),
                        ListTile(
                          title: Text('Privacy'),
                          onTap: () => Get.to(() => PrivacyPolicyScreen()),
                        ),
                        Divider(),

                        SectionTitle(title: 'Prayer', icon: Icons.access_time),
                        ListTile(
                          title: Text('Calculation Method & Madhab'),
                          subtitle: Text('Affects Fajr/Isha angle and Asr timing'),
                          onTap: () => _showCalculationDialog(context),
                        ),
                        Divider(),

                        SectionTitle(title: 'Notification', icon: Icons.notifications),
                        SwitchListTile(
                          title: Text('Notification'),
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() => _notificationsEnabled = value);
                            VoidStorage().saveData(_notificationsKey, value);
                          },
                        ),
                        SwitchListTile(
                          title: Text('Updates'),
                          value: _updatesEnabled,
                          onChanged: (value) {
                            setState(() => _updatesEnabled = value);
                            VoidStorage().saveData(_updatesKey, value);
                          },
                        ),
                        Divider(),

                        SectionTitle(title: 'Other', icon: Icons.settings),
                        Obx(() => SwitchListTile(
                              title: Text('Dark Mode'),
                              value: _themeController.isDarkMode,
                              onChanged: (value) => _themeController.setDarkMode(value),
                            )),
                        ListTile(
                          title: Text('Language'),
                          trailing: Text('English (more coming soon)', style: TextStyle(color: Colors.grey)),
                          enabled: false,
                        ),
                        ListTile(
                          title: Text('Region'),
                          trailing: Text(_selectedRegion ?? 'Select Region'),
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
