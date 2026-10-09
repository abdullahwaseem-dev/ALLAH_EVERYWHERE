import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:allah_everywhere/data/rewards_data.dart';
import 'package:allah_everywhere/services/rewards_service.dart';

// The looks unlocked in My Rewards: purely cosmetic, never a feature.

/// The ring around the Profile photo, in the chosen avatar frame.
BoxDecoration avatarFrameDecoration(Color accent, {String? frame}) {
  switch (frame ?? RewardsService.selected(CosmeticKind.avatarFrame)) {
    case 'avatar_crescent':
      return BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [accent, accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.15), accent]),
      );
    case 'avatar_star':
      return BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 3),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 14, spreadRadius: 2)],
      );
    case 'avatar_garden':
      return BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [accent, const Color(0xFF5E9E6E), accent, const Color(0xFF5E9E6E), accent]),
      );
    default:
      return BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent, width: 2.5));
  }
}

/// The Tasbeeh counter's surface in the chosen bead style; null keeps the
/// plain card colour.
Gradient? beadGradient(Color bead, Color card, {String? style}) {
  switch (style ?? RewardsService.selected(CosmeticKind.bead)) {
    case 'bead_pearl':
      return RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 1.0,
        colors: [Color.alphaBlend(Colors.white.withValues(alpha: 0.85), card), card, Color.alphaBlend(bead.withValues(alpha: 0.18), card)],
        stops: const [0, 0.55, 1],
      );
    case 'bead_glow':
      return RadialGradient(
        radius: 0.9,
        colors: [Color.alphaBlend(bead.withValues(alpha: 0.32), card), card],
      );
    default:
      return null;
  }
}

/// A decorative frame around a Mushaf page.
class MushafPageFrame extends StatelessWidget {
  final Color color;
  final Widget child;
  final String? frame;

  const MushafPageFrame({super.key, required this.color, required this.child, this.frame});

  @override
  Widget build(BuildContext context) {
    final id = frame ?? RewardsService.selected(CosmeticKind.mushafFrame);
    if (id == 'frame_none') return child;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: CustomPaint(
        foregroundPainter: _FramePainter(color.withValues(alpha: 0.6), arch: id == 'frame_arch'),
        child: Padding(padding: const EdgeInsets.all(6), child: child),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final Color color;
  final bool arch;

  _FramePainter(this.color, {required this.arch});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final thin = Paint()
      ..color = color.withValues(alpha: color.a * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    if (arch) {
      // A pointed arch over the page, like a mihrab.
      Path archPath(double inset) {
        final w = size.width - 2 * inset;
        final top = inset;
        final shoulder = inset + math.min(56.0, size.height * 0.12);
        return Path()
          ..moveTo(inset, size.height - inset)
          ..lineTo(inset, shoulder)
          ..quadraticBezierTo(inset, top, inset + w / 2, top)
          ..quadraticBezierTo(inset + w, top, inset + w, shoulder)
          ..lineTo(inset + w, size.height - inset)
          ..close();
      }

      canvas.drawPath(archPath(1), line);
      canvas.drawPath(archPath(4), thin);
      return;
    }
    // Double border with an eight-point star in each corner.
    canvas.drawRect(Rect.fromLTWH(1, 1, size.width - 2, size.height - 2), line);
    canvas.drawRect(Rect.fromLTWH(4, 4, size.width - 8, size.height - 8), thin);
    final fill = Paint()..color = color;
    for (final c in [
      const Offset(4, 4),
      Offset(size.width - 4, 4),
      Offset(4, size.height - 4),
      Offset(size.width - 4, size.height - 4),
    ]) {
      canvas.drawPath(eightPointStar(c, 6), fill);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.color != color || old.arch != arch;
}

/// An eight-point star (two overlapping squares) centred on [c].
Path eightPointStar(Offset c, double r) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final angle = i * math.pi / 8 - math.pi / 2;
    final radius = i.isEven ? r : r * 0.55;
    final p = c + Offset(math.cos(angle), math.sin(angle)) * radius;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}
