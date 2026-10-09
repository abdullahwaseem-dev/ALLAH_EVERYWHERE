import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'layout_helpers.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import '../home.dart';
import '../profile.dart';
import '../settings.dart';
import '../tasbeeh.dart';
import '../tib_e_nabwi.dart';
import '../services/push_notification_service.dart';
import '../utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/rewards.dart';

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
    (icon: FlutterIslamicIcons.mohammad, activeIcon: FlutterIslamicIcons.solidMohammad),
    (icon: FlutterIslamicIcons.tasbih, activeIcon: FlutterIslamicIcons.solidTasbih),
    (icon: Iconsax.settings, activeIcon: Iconsax.settings5),
    (icon: Iconsax.profile_circle, activeIcon: Iconsax.profile_circle5),
  ];

  @override
  void initState() {
    super.initState();
    PushNotificationService().init();
    RewardsWatcher.start();
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
    // Sits above the home indicator (it used to be a fixed 20 from the
    // bottom edge, overlapping it), and stays phone-sized on iPad.
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, floatingNavBarBottomGap(context)),
      child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: floatingNavBarHeight,
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
      ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark, Color accent) {
    final isSelected = index == _currentIndex;
    final item = _items[index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (index != _currentIndex) HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: isSelected ? 48 : 40,
        height: isSelected ? 48 : 40,
        alignment: Alignment.center,
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
