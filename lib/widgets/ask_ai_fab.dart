import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:allah_everywhere/ask_ai.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';

/// Wraps a screen (usually its Scaffold) and floats the pill-shaped
/// "Ask AI" button over it, at the bottom end corner (bottom-left in RTL).
///
/// - Sits above MediaQuery's bottom padding. Inside the bottom nav bar's
///   Scaffold (extendBody: true) that padding is the glass bar's height, so
///   the button always clears the bar; on pushed screens it clears the
///   home indicator.
/// - Shrinks to just the icon while scrolling down, expands on scrolling up.
/// - Hides while the keyboard is open.
/// - [hideNearEndExtent]: hides the button when the scroll position is
///   within this many pixels of the end. Home uses it so the button never
///   covers the banner ad at the bottom of its content.
class AskAiFabHost extends StatefulWidget {
  final Widget child;

  /// Built at tap time, so it always reflects what is on screen right now
  /// (e.g. the current Quran page). Return null for an empty question.
  final String? Function()? questionBuilder;
  final String? category;
  final bool showFirstLaunchHint;
  final double hideNearEndExtent;

  const AskAiFabHost({
    super.key,
    required this.child,
    this.questionBuilder,
    this.category,
    this.showFirstLaunchHint = false,
    this.hideNearEndExtent = 0,
  });

  @override
  State<AskAiFabHost> createState() => _AskAiFabHostState();
}

class _AskAiFabHostState extends State<AskAiFabHost> {
  static const _hintShownKey = 'ask_ai_fab_hint_shown';
  static const double _edgeGap = 16;

  bool _extended = true;
  bool _nearEnd = false;
  bool _showHint = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    if (widget.showFirstLaunchHint && VoidStorage().readData<bool>(_hintShownKey) != true) {
      // Wait for the first layout (and any permission dialog) to settle.
      _hintTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _showHint = true);
        VoidStorage().saveData(_hintShownKey, true);
        _hintTimer = Timer(const Duration(seconds: 8), _dismissHint);
      });
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _dismissHint() {
    _hintTimer?.cancel();
    if (mounted && _showHint) setState(() => _showHint = false);
  }

  bool _onScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return false;

    var extended = _extended;
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) extended = false;
      if (notification.direction == ScrollDirection.forward) extended = true;
    }
    if (metrics.pixels <= metrics.minScrollExtent + 4) extended = true;
    final nearEnd = widget.hideNearEndExtent > 0 && metrics.extentAfter < widget.hideNearEndExtent;

    if (extended != _extended || nearEnd != _nearEnd) {
      setState(() {
        _extended = extended;
        _nearEnd = nearEnd;
      });
    }
    return false;
  }

  void _open() {
    HapticFeedback.lightImpact();
    _dismissHint();
    final question = widget.questionBuilder?.call();
    Get.to(() => AskAiScreen(
          initialCategory: widget.category,
          initialQuestion: (question?.trim().isEmpty ?? true) ? null : question,
          autofocus: true,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final visible = !keyboardOpen && !_nearEnd;
    final bottom = MediaQuery.paddingOf(context).bottom + _edgeGap;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          widget.child,
          PositionedDirectional(
            end: _edgeGap,
            bottom: bottom,
            child: IgnorePointer(
              ignoring: !visible,
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(0, 0.4),
                duration: const Duration(milliseconds: 200),
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _AskAiFab(extended: _extended, onTap: _open),
                ),
              ),
            ),
          ),
          if (_showHint && visible)
            PositionedDirectional(
              end: _edgeGap,
              bottom: bottom + 48 + 10,
              child: _HintBubble(onTap: _dismissHint),
            ),
        ],
      ),
    );
  }
}

/// Colours shared by the button and its hint so they read as one unit.
/// Light: olive pill with gold icon. Dark: gold pill with olive content.
({Color bg, Color fg, Color icon}) _fabColors(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      ? (bg: VoidColors.goldDark, fg: VoidColors.oliveDeep, icon: VoidColors.oliveDeep)
      : (bg: VoidColors.oliveDeep, fg: Colors.white, icon: VoidColors.goldDark);
}

class _AskAiFab extends StatelessWidget {
  final bool extended;
  final VoidCallback onTap;

  const _AskAiFab({required this.extended, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = _fabColors(context);
    return Semantics(
      button: true,
      label: t.askAi,
      child: ExcludeSemantics(
        child: Material(
          color: colors.bg,
          shape: const StadiumBorder(),
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          child: InkWell(
            customBorder: const StadiumBorder(),
            splashColor: colors.fg.withValues(alpha: 0.2),
            highlightColor: colors.fg.withValues(alpha: 0.1),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: extended ? 18 : 13),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.magic_star, size: 22, color: colors.icon),
                      if (extended) ...[
                        const SizedBox(width: 8),
                        Text(
                          t.askAi,
                          maxLines: 1,
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: colors.fg),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-time "Ask any Islamic question" bubble with a small arrow pointing
/// down at the button.
class _HintBubble extends StatelessWidget {
  final VoidCallback onTap;

  const _HintBubble({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = _fabColors(context);
    return Semantics(
      liveRegion: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: 220.w),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Text(
                t.askAiFirstHint,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: colors.fg),
              ),
            ),
            // Arrow, centred over the collapsed (icon-only) button width.
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 18),
              child: CustomPaint(size: const Size(14, 8), painter: _ArrowPainter(colors.bg)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.color != color;
}
