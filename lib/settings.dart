import 'package:allah_everywhere/privacy_policy.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
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
  // List of countries
  final List<String> countries = [
    'Pakistan', 'India', 'United States', 'Canada', 'Brazil', 'Australia', 'China', 'Russia', 'Japan', 'South Korea',
    'United Kingdom', 'Germany', 'France', 'Italy', 'Mexico', 'Indonesia', 'Turkey', 'Spain', 'Saudi Arabia', 'Argentina',
    'South Africa', 'Egypt', 'Nigeria', 'Thailand', 'Ukraine', 'Poland', 'Vietnam', 'Colombia', 'Kenya', 'Peru',
    'Malaysia', 'Israel', 'Singapore', 'Philippines', 'Bangladesh', 'Romania', 'Chile', 'Iraq', 'Afghanistan', 'Sudan',
    'Algeria', 'Poland', 'Morocco', 'Uzbekistan', 'Venezuela', 'Greece', 'Portugal', 'Sweden', 'Norway', 'Finland',
    'Denmark', 'Switzerland', 'Netherlands', 'Belgium', 'Austria', 'Ireland', 'Czech Republic', 'Hungary', 'New Zealand'
  ];

  // Selected region variable
  String? _selectedRegion;

  // Function to show the region dialog
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
              setState(() {
                // Update selected region
                _selectedRegion = newValue;
              });
              Navigator.pop(context); // Close the dialog after selection
            },
            items: countries.map<DropdownMenuItem<String>>((String country) {
              return DropdownMenuItem<String>(
                value: country,
                child: Text(country),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(VoidImages.otherscreen_background),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                // Sections
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Section
                        SectionTitle(title: 'Account', icon: Icons.account_circle),
                        ListTile(
                          title: GestureDetector(
                              onTap: () {
                                Get.to(EditProfileScreen());
                              },
                              child: Text('Edit Profile')),
                          onTap: () {},
                        ),
                        ListTile(
                          title: GestureDetector(
                            onTap: () {
                              Get.to(() => ChangePasswordScreen());
                            },
                            child: Text('Change Password'),
                          ),
                          onTap: () {},
                        ),
                        ListTile(
                          title: GestureDetector(
                            onTap: () {
                              Get.to(() => PrivacyPolicyScreen());
                            },
                            child: Text('Privacy'),
                          ),
                          onTap: () {},
                        ),
                        Divider(),

                        // Notification Section
                        SectionTitle(title: 'Notification', icon: Icons.notifications),
                        SwitchListTile(
                          title: Text('Notification'),
                          value: true,
                          onChanged: (value) {},
                        ),
                        SwitchListTile(
                          title: Text('Updates'),
                          value: false,
                          onChanged: (value) {},
                        ),
                        Divider(),

                        // Other Section
                        SectionTitle(title: 'Other', icon: Icons.settings),
                        SwitchListTile(
                          title: Text('Dark Mode'),
                          value: false,
                          onChanged: (value) {},
                        ),
                        ListTile(
                          title: Text('Language'),
                          trailing: Text('English'),
                          onTap: () {},
                        ),
                        ListTile(
                          title: Text('Region'),
                          trailing: Text(_selectedRegion ?? 'Select Region'),
                          onTap: () {
                            _showRegionDialog(context); // Open region dropdown
                          },
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

  const SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
