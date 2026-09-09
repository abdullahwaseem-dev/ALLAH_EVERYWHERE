import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../home.dart';
import '../profile.dart';
import '../settings.dart';
import '../tasbeeh.dart';
import '../tib_e_nabwi.dart';
import '../utils/utils/constraints/colors.dart';
import '../utils/utils/constraints/image_strings.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
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
        color: VoidColors.blusih,
        buttonBackgroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        height: 60.0,
        items: <Widget>[
          _buildIcon(VoidImages.home, 0, 25, 25),
          _buildIcon(VoidImages.muhammad_icon, 1, 25, 25),
          _buildIcon(VoidImages.tasbeeh, 2, 25, 25),
          _buildIcon(VoidImages.setting, 3, 25, 25),
          _buildIcon(VoidImages.profile, 4, 25, 25),
        ],
      ),
    );
  }

  Widget _buildIcon(String iconPath, int index, double width, double height) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:Colors.transparent,
      ),
      child: Image.asset(
        iconPath,
        width: width,
        height: height,
      ),
    );
  }
}




