import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/utils/constraints/image_strings.dart';

class QiblaCompass extends StatelessWidget {
  final double deviceHeading;
  final double qiblaDirection;

  QiblaCompass({required this.deviceHeading, required this.qiblaDirection});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (deviceHeading - qiblaDirection) * (3.1415927 / 180),
      child: Image.asset(
        VoidImages.compass,
        height: 180.h,
      ),
    );
  }
}
