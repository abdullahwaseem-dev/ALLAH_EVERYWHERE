import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/utils/constraints/image_strings.dart';

class MasjidImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      VoidImages.masjid_vector,
      height: 170.h,
    );
  }
}
