import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';

/// Search-style "Ask AI" bar for the top of Home. The placeholder cycles
/// through example questions so users see what they can ask. Deliberately
/// unlike the plain search icon: sparkle icon, "Ask AI:" prefix, gold border.
class AskAiPromptBar extends StatefulWidget {
  final VoidCallback onTap;

  const AskAiPromptBar({super.key, required this.onTap});

  @override
  State<AskAiPromptBar> createState() => _AskAiPromptBarState();
}

class _AskAiPromptBarState extends State<AskAiPromptBar> {
  static const _rotateEvery = Duration(milliseconds: 3500);

  int _index = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_rotateEvery, (_) {
      if (mounted) setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade700;
    final examples = [
      t.askAiExampleWitr,
      t.askAiExampleAnxiety,
      t.askAiExampleFast,
      t.askAiExampleTravel,
    ];
    final example = examples[_index % examples.length];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(28.r);

    return Semantics(
      button: true,
      label: '${t.askAi}. ${t.askAiFirstHint}',
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Material(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: accent.withValues(alpha: 0.6), width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              splashColor: accent.withValues(alpha: isDark ? 0.20 : 0.14),
              highlightColor: accent.withValues(alpha: isDark ? 0.12 : 0.08),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.w, 8.h, 8.w, 8.h),
                  child: Row(
                    children: [
                      Icon(Iconsax.magic_star, size: 20.sp, color: accent),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                              child: child,
                            ),
                          ),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: AlignmentDirectional.centerStart,
                            children: [...previous, if (current != null) current],
                          ),
                          child: Text(
                            t.askAiPrompt(example),
                            key: ValueKey(example),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5.sp, color: subColor),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                        // arrow_forward mirrors itself in RTL.
                        child: Icon(Icons.arrow_forward_rounded, size: 18, color: isDark ? VoidColors.oliveDeep : Colors.white),
                      ),
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
