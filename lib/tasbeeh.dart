import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';


class TasbeehScreen extends StatefulWidget {
  @override
  _TasbeehScreenState createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int tasbeehCount = 0;
  int lapCount = 0;
  Color beadColor = Colors.blue;
  List<bool> beadStates = List.generate(33, (index) => false);

  void incrementTasbeeh(int index) {
    setState(() {
      if (!beadStates[index]) {
        tasbeehCount++;
        beadStates[index] = true;
        if (tasbeehCount % 33 == 0) {
          lapCount++;
          beadStates = List.generate(33, (index) => false);
        }
      }
    });
  }

  void resetTasbeeh() {
    setState(() {
      tasbeehCount = 0;
      lapCount = 0;
      beadStates = List.generate(33, (index) => false);
    });
  }

  void changeBeadColor(Color color) {
    setState(() {
      beadColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidColors.secondary,
      body: Column(
        children: [
          Stack(
            children: [
              ClipPath(
                clipper: CustomAppBarClipper(),
                child: Container(
                  height: 120.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFC6AC9F), Color(0xFF60534D)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Text(
                      'Tasbeeh',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Beads Section
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (int i = 0; i < 33; i++)
                    Positioned(
                      left: 160.w + 150.w * cos((i * 360 / 33) * 3.1415926535 / 180),
                      top: 135.h + 130.h * sin((i * 360 / 33) * 3.1415926535 / 180),
                      child: GestureDetector(
                        onTap: () => incrementTasbeeh(i),
                        child: Container(
                          width: 40.w,
                          height: 25.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: beadStates[i] ? beadColor : beadColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Counter Section
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Column(
              children: [
                Text(
                  'Tasbeeh Count: $tasbeehCount',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                if (lapCount > 0)
                  Text(
                    'Laps Completed: $lapCount',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                  ),
              ],
            ),
          ),
          // Reset Button
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: ElevatedButton(
              onPressed: resetTasbeeh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                child: Text(
                  'Reset',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                ),
              ),
            ),
          ),
          // Bead Color Selector
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ColorPicker(color: Colors.blue, onTap: () => changeBeadColor(Colors.blue)),
                ColorPicker(color: Colors.green, onTap: () => changeBeadColor(Colors.green)),
                ColorPicker(color: Colors.red, onTap: () => changeBeadColor(Colors.red)),
                ColorPicker(color: Colors.purple, onTap: () => changeBeadColor(Colors.purple)),
                ColorPicker(color: Colors.orange, onTap: () => changeBeadColor(Colors.orange)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class ColorPicker extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const ColorPicker({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
