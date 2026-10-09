import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/utils/constraints/image_strings.dart';

/// Rotates the compass artwork (which has the Kaaba icon acting as the
/// "needle") by the Qiblah-relative bearing reported by `flutter_qiblah`.
/// When the Kaaba icon points to the top of the screen, the device is
/// facing the Qiblah.
class QiblaCompass extends StatelessWidget {
  final double qiblahDirection;

  const QiblaCompass({Key? key, required this.qiblahDirection}) : super(key: key);

  // compass.png's Kaaba graphic isn't drawn at the image's true top (0°) -
  // measured by pixel analysis of the asset, its centroid sits ~31°
  // clockwise from top. Left uncorrected, every reading pointed ~31° too
  // far clockwise of the real Qiblah bearing.
  static const double _kaabaIconOffsetDegrees = 31.0;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -(qiblahDirection + _kaabaIconOffsetDegrees) * (math.pi / 180),
      child: Image.asset(
        VoidImages.compass,
        height: 180.h,
      ),
    );
  }
}
