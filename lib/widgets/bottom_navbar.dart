import 'dart:ui';
import 'package:flutter/material.dart';
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

  static const _items = [
    (icon: Iconsax.home_2, activeIcon: Iconsax.home_25),
    (icon: Iconsax.health, activeIcon: Iconsax.health5),
    (icon: Iconsax.activity, activeIcon: Iconsax.activity5),
    (icon: Iconsax.setting_2, activeIcon: Iconsax.setting_25),
    (icon: Iconsax.user, activeIcon: Iconsax.user5),
  ];

  @override
  void initState() {
    super.initState();
    PushNotificationService().init();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFloatingGlassBar(isDark),
    );
  }

  Widget _buildFloatingGlassBar(bool isDark) {
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(isDark ? 0.45 : 0.55),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.white).withOpacity(isDark ? 0.10 : 0.65),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < _items.length; i++) _buildNavItem(i, isDark, accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark, Color accent) {
    final isSelected = index == _currentIndex;
    final item = _items[index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: isSelected ? 48 : 40,
        height: isSelected ? 48 : 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? accent.withOpacity(isDark ? 0.9 : 1) : Colors.transparent,
          boxShadow: isSelected
              ? [BoxShadow(color: accent.withOpacity(0.45), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Icon(
          isSelected ? item.activeIcon : item.icon,
          size: 22,
          color: isSelected
              ? (isDark ? VoidColors.oliveDeep : Colors.white)
              : (isDark ? VoidColors.textDarkSecondary : VoidColors.oliveDeep.withOpacity(0.7)),
        ),
      ),
    );
  }
}
