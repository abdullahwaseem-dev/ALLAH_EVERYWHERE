import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';

class NamazTimingWidget extends StatelessWidget {
  final String name;
  final String time;
  final IconData icon;
  final bool isNext;

  const NamazTimingWidget({
    Key? key,
    required this.name,
    required this.time,
    required this.icon,
    this.isNext = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final cardColor = isNext
        ? accent
        : (isDark ? VoidColors.cardDark : VoidColors.cardLight);
    final contentColor = isNext
        ? (isDark ? VoidColors.oliveDeep : Colors.white)
        : (isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep);

    return Container(
      width: 68.w,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: isNext ? null : Border.all(color: accent.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.06), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isNext ? contentColor : accent, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            name,
            style: TextStyle(color: contentColor, fontSize: 11.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 2.h),
          Text(
            time,
            style: TextStyle(color: contentColor, fontSize: 10.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
