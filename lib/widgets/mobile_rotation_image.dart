import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/utils/constraints/image_strings.dart';

class MobileRotationImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      VoidImages.mobile_rotation,
      height: 170.h,
    );
  }
}
