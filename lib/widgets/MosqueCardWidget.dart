import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';

class MosqueCardWidget extends StatelessWidget {
  final String name;
  final String location;
  final VoidCallback? onTap;

  const MosqueCardWidget({
    Key? key,
    required this.name,
    required this.location,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160.w,
        margin: EdgeInsets.only(right: 10.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: accent.withOpacity(isDark ? 0.25 : 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.buildings, size: 18.sp, color: accent),
            ),
            SizedBox(height: 10.h),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Iconsax.location, size: 13.sp, color: isDark ? VoidColors.textDarkSecondary : Colors.grey),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
