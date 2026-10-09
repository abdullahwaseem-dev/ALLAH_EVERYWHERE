import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:allah_everywhere/services/app_share_service.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';

import 'share_backgrounds.dart';
import 'share_content.dart';

/// Export sizes. The card is laid out at [logicalSize] (360 wide) and
/// captured at 3x, giving the 1080px-wide images WhatsApp and Instagram
/// expect.
enum ShareFormat {
  story(Size(360, 640)), // 9:16 - WhatsApp Status, Instagram Story
  post(Size(360, 450)), // 4:5 - Instagram feed
  square(Size(360, 360)); // 1:1

  final Size logicalSize;
  const ShareFormat(this.logicalSize);
}

/// Who the card is "from": the signed-in user's name and photo, or the app
/// itself (logo + app name) for guests or users without a photo.
class ShareIdentity {
  final String name;
  final ImageProvider? photo;

  const ShareIdentity({required this.name, this.photo});
}

/// The shareable image. Everything is sized in the card's own 360-wide
/// coordinate space (no ScreenUtil), so the preview and the exported PNG are
/// pixel-for-pixel the same layout.
class ShareCard extends StatelessWidget {
  final ShareContent content;
  final ShareBackground background;
  final ShareFormat format;
  final ShareIdentity identity;
  final bool showArabic;
  final bool showTranslation;
  final String downloadLabel;
  final String kindLabel;

  const ShareCard({
    super.key,
    required this.content,
    required this.background,
    required this.format,
    required this.identity,
    required this.showArabic,
    required this.showTranslation,
    required this.downloadLabel,
    required this.kindLabel,
  });

  @override
  Widget build(BuildContext context) {
    final size = format.logicalSize;
    final dark = background.isDark;
    final cardColor = dark ? const Color(0xE6121210) : const Color(0xF2FFFFFF);
    final textColor = dark ? VoidColors.textDarkPrimary : const Color(0xFF1F1E17);
    final subColor = dark ? VoidColors.textDarkSecondary : const Color(0xFF6B6A5E);
    final accent = dark ? VoidColors.goldDark : VoidColors.gold;
    final footerColor = dark ? Colors.white : VoidColors.oliveDeep;

    final arabic = showArabic ? content.arabic : '';
    final translation = showTranslation ? content.translation : '';
    final scale = _textScale(arabic.length + translation.length);
    final compact = format != ShareFormat.story;

    return SizedBox.fromSize(
      size: size,
      // Rendered offscreen for export, so it needs its own Material/Directionality
      // ancestors rather than borrowing the app's text direction.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShareBackgroundView(background: background),
              Padding(
                padding: EdgeInsets.fromLTRB(20, compact ? 18 : 40, 20, compact ? 12 : 26),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: size.width - 40,
                            child: _card(cardColor, textColor, subColor, accent, arabic, translation, scale, dark),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 18),
                    _footer(footerColor, dark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shrinks text as it gets longer so most passages fit at a comfortable
  /// size; the FittedBox above is only the last resort for very long ones.
  double _textScale(int chars) {
    final budget = switch (format) {
      ShareFormat.story => 520,
      ShareFormat.post => 340,
      ShareFormat.square => 250,
    };
    if (chars <= budget) return 1;
    return math.max(0.62, math.sqrt(budget / chars));
  }

  Widget _card(Color cardColor, Color textColor, Color subColor, Color accent, String arabic,
      String translation, double scale, bool dark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        border: dark ? Border.all(color: accent.withValues(alpha: 0.35)) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.35 : 0.12), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _avatar(38, dark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      identity.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      kindLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: subColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (arabic.isNotEmpty)
            Text(
              arabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: ScriptureText.arabic(fontSize: 21 * scale, color: textColor),
            ),
          if (arabic.isNotEmpty && translation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Center(child: Container(width: 44, height: 1.5, color: accent.withValues(alpha: 0.7))),
            const SizedBox(height: 10),
          ],
          if (translation.isNotEmpty)
            Text(
              translation,
              textAlign: TextAlign.center,
              textDirection: content.translationIsUrdu ? TextDirection.rtl : TextDirection.ltr,
              style: content.translationIsUrdu
                  ? ScriptureText.urdu(fontSize: 14.5 * scale, color: textColor)
                  : TextStyle(fontSize: 14.5 * scale, height: 1.45, color: textColor),
            ),
          const SizedBox(height: 14),
          Text(
            content.reference,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: accent),
          ),
        ],
      ),
    );
  }

  Widget _avatar(double size, bool dark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: (dark ? VoidColors.goldDark : VoidColors.gold).withValues(alpha: 0.6), width: 1.2),
        image: DecorationImage(
          image: identity.photo ?? const AssetImage(VoidImages.launcher),
          fit: identity.photo != null ? BoxFit.cover : BoxFit.contain,
        ),
      ),
    );
  }

  Widget _footer(Color color, bool dark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Image.asset(VoidImages.launcher, fit: BoxFit.contain),
            ),
            const SizedBox(width: 8),
            Text(
              AppLinks.appName,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          downloadLabel,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: color.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _storeBadge(Icons.shop, 'GET IT ON', 'Google Play'),
            const SizedBox(width: 8),
            _storeBadge(Icons.apple, 'Download on the', 'App Store'),
          ],
        ),
      ],
    );
  }

  Widget _storeBadge(IconData icon, String small, String big) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(small, style: const TextStyle(fontSize: 6.5, color: Colors.white, height: 1.1)),
              Text(big, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, height: 1.15)),
            ],
          ),
        ],
      ),
    );
  }
}
