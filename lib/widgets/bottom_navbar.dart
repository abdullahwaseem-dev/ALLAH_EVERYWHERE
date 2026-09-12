import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:iconsax/iconsax.dart';
import '../home.dart';
import '../profile.dart';
import '../settings.dart';
import '../tasbeeh.dart';
import '../tib_e_nabwi.dart';
import '../services/push_notification_service.dart';
import '../utils/utils/constraints/colors.dart';

class BottomNavBarApp extends StatefulWidget {
  @override
  _BottomNavBarAppState createState() => _BottomNavBarAppState();
}

class _BottomNavBarAppState extends State<BottomNavBarApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    TibENabwi(),
    TasbeehScreen(),
    SettingsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    PushNotificationService().init();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
        buttonBackgroundColor: accent,
        backgroundColor: Colors.transparent,
        height: 60.0,
        items: <Widget>[
          _buildIcon(Iconsax.home_2, 0, isDark, accent),
          _buildIcon(Iconsax.health, 1, isDark, accent),
          _buildIcon(Iconsax.activity, 2, isDark, accent),
          _buildIcon(Iconsax.setting_2, 3, isDark, accent),
          _buildIcon(Iconsax.user, 4, isDark, accent),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index, bool isDark, Color accent) {
    final isSelected = index == _currentIndex;
    return Icon(
      icon,
      size: 24,
      color: isSelected ? Colors.white : (isDark ? VoidColors.textDarkSecondary : VoidColors.oliveDeep),
    );
  }
}




