import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';

/// The one back-button look used across every screen - same icon, size and
/// theme-aware color everywhere, instead of each screen picking its own
/// (previously a mix of arrow_back, arrow_back_ios and arrow_back_ios_new
/// with inconsistent hardcoded colors).
class VoidBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const VoidBackButton({super.key, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = color ?? (isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep);
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new_outlined, color: resolvedColor, size: 20.sp),
      onPressed: onPressed ?? () => Get.back(),
    );
  }
}
