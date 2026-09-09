import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/utils/constraints/image_strings.dart';

/// Rotates the compass artwork (which has the Kaaba icon fixed at the top
/// of the image, acting as the "needle") by the Qiblah-relative bearing
/// reported by `flutter_qiblah`. When the Kaaba icon points to the top of
/// the screen, the device is facing the Qiblah.
class QiblaCompass extends StatelessWidget {
  final double qiblahDirection;

  const QiblaCompass({Key? key, required this.qiblahDirection}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -qiblahDirection * (math.pi / 180),
      child: Image.asset(
        VoidImages.compass,
        height: 180.h,
      ),
    );
  }
}
