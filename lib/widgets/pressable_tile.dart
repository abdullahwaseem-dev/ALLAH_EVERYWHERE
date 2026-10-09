import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';

/// Makes a whole row / card / tile tappable with a themed ripple.
///
/// Use this instead of a bare GestureDetector: a GestureDetector without
/// HitTestBehavior.opaque only reacts to painted pixels (the text), so taps
/// on empty space inside the row are lost.
///
/// - [color]: the card background. It is painted by the Material so the
///   ripple shows on top of it. Leave null for transparent list rows.
/// - Keep margins and shadows outside this widget, and keep dividers
///   outside too so they never belong to the wrong row.
class PressableTile extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;
  final BorderRadius? borderRadius;
  final Color? color;
  final double minHeight;

  const PressableTile({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.borderRadius,
    this.color,
    this.minHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final radius = borderRadius ?? BorderRadius.circular(12.r);

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: Material(
        color: color ?? Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: accent.withValues(alpha: isDark ? 0.20 : 0.14),
          highlightColor: accent.withValues(alpha: isDark ? 0.12 : 0.08),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: child,
          ),
        ),
      ),
    );
  }
}
