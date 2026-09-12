import 'package:flutter/material.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';

class IconButtonWidget extends StatelessWidget {
  final IconData icon;
  final String title;

  const IconButtonWidget({Key? key, required this.icon, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isDark ? VoidColors.oliveDeepLight.withOpacity(0.35) : VoidColors.gold.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 22,
            color: isDark ? VoidColors.goldDark : VoidColors.gold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep,
          ),
        ),
      ],
    );
  }
}
