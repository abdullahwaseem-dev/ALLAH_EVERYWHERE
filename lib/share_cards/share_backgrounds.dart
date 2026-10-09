import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The decorative motif painted over a background's gradient.
enum BackgroundMotif {
  starTiles,
  arches,
  mosqueSkyline,
  nightSky,
  hexLattice,
  lanterns,
  overlappingCircles,
  dunes,
  mihrabFrame,
  bokeh,
  diagonalLattice,
  sunrays,
}

/// A share-card background, drawn in code so it stays sharp at any export
/// resolution and adds nothing to the app's download size.
class ShareBackground {
  final String id;
  final bool isDark;
  final List<Color> gradient;
  final Color motifColor;
  final BackgroundMotif motif;

  const ShareBackground({
    required this.id,
    required this.isDark,
    required this.gradient,
    required this.motifColor,
    required this.motif,
  });
}

const List<ShareBackground> shareBackgrounds = [
  // Light
  ShareBackground(
      id: 'l_sand_stars',
      isDark: false,
      gradient: [Color(0xFFFBF3E4), Color(0xFFEBD3A8)],
      motifColor: Color(0x33A87B2F),
      motif: BackgroundMotif.starTiles),
  ShareBackground(
      id: 'l_rose_arches',
      isDark: false,
      gradient: [Color(0xFFFCEFEA), Color(0xFFE6B8A6)],
      motifColor: Color(0x55FFFFFF),
      motif: BackgroundMotif.arches),
  ShareBackground(
      id: 'l_dawn_skyline',
      isDark: false,
      gradient: [Color(0xFFFFE7C2), Color(0xFFF6B48F), Color(0xFFD9879A)],
      motifColor: Color(0x66FFFFFF),
      motif: BackgroundMotif.mosqueSkyline),
  ShareBackground(
      id: 'l_mint_hex',
      isDark: false,
      gradient: [Color(0xFFEFF8F1), Color(0xFFBFDCC6)],
      motifColor: Color(0x33306B45),
      motif: BackgroundMotif.hexLattice),
  ShareBackground(
      id: 'l_sky_circles',
      isDark: false,
      gradient: [Color(0xFFEAF4FB), Color(0xFFB9D7EE)],
      motifColor: Color(0x33205A86),
      motif: BackgroundMotif.overlappingCircles),
  ShareBackground(
      id: 'l_desert_dunes',
      isDark: false,
      gradient: [Color(0xFFFFF4DF), Color(0xFFF3D19A)],
      motifColor: Color(0x40C07A2C),
      motif: BackgroundMotif.dunes),
  ShareBackground(
      id: 'l_lavender_lanterns',
      isDark: false,
      gradient: [Color(0xFFF4EEFB), Color(0xFFD3C3EA)],
      motifColor: Color(0x55644A8F),
      motif: BackgroundMotif.lanterns),
  ShareBackground(
      id: 'l_ivory_mihrab',
      isDark: false,
      gradient: [Color(0xFFFFFBF3), Color(0xFFEFE3CC)],
      motifColor: Color(0x4DB08A45),
      motif: BackgroundMotif.mihrabFrame),
  ShareBackground(
      id: 'l_peach_bokeh',
      isDark: false,
      gradient: [Color(0xFFFFEEE3), Color(0xFFF8C9B0)],
      motifColor: Color(0x66FFFFFF),
      motif: BackgroundMotif.bokeh),
  ShareBackground(
      id: 'l_olive_lattice',
      isDark: false,
      gradient: [Color(0xFFF4F3E6), Color(0xFFD7D5B2)],
      motifColor: Color(0x334B4B32),
      motif: BackgroundMotif.diagonalLattice),
  ShareBackground(
      id: 'l_gold_rays',
      isDark: false,
      gradient: [Color(0xFFFFF8E6), Color(0xFFF1D58C)],
      motifColor: Color(0x33FFFFFF),
      motif: BackgroundMotif.sunrays),
  ShareBackground(
      id: 'l_pearl_stars',
      isDark: false,
      gradient: [Color(0xFFF7F7F4), Color(0xFFDCDDD6)],
      motifColor: Color(0x2E6E6E48),
      motif: BackgroundMotif.starTiles),
  // Dark
  ShareBackground(
      id: 'd_midnight_sky',
      isDark: true,
      gradient: [Color(0xFF0B1330), Color(0xFF1C2B5A)],
      motifColor: Color(0xCCFFF3D6),
      motif: BackgroundMotif.nightSky),
  ShareBackground(
      id: 'd_emerald_stars',
      isDark: true,
      gradient: [Color(0xFF062A21), Color(0xFF0F4D3B)],
      motifColor: Color(0x33E8C165),
      motif: BackgroundMotif.starTiles),
  ShareBackground(
      id: 'd_dusk_skyline',
      isDark: true,
      gradient: [Color(0xFF1B1036), Color(0xFF53306B), Color(0xFFB0605F)],
      motifColor: Color(0xCC120A22),
      motif: BackgroundMotif.mosqueSkyline),
  ShareBackground(
      id: 'd_olive_arches',
      isDark: true,
      gradient: [Color(0xFF15140F), Color(0xFF3A3A26)],
      motifColor: Color(0x26E8C165),
      motif: BackgroundMotif.arches),
  ShareBackground(
      id: 'd_navy_hex',
      isDark: true,
      gradient: [Color(0xFF0D1B2A), Color(0xFF1B3A57)],
      motifColor: Color(0x2E9CC7E8),
      motif: BackgroundMotif.hexLattice),
  ShareBackground(
      id: 'd_maroon_lanterns',
      isDark: true,
      gradient: [Color(0xFF2A0C12), Color(0xFF5A1A26)],
      motifColor: Color(0x80E8C165),
      motif: BackgroundMotif.lanterns),
  ShareBackground(
      id: 'd_charcoal_circles',
      isDark: true,
      gradient: [Color(0xFF141414), Color(0xFF2E2A22)],
      motifColor: Color(0x2EE8C165),
      motif: BackgroundMotif.overlappingCircles),
  ShareBackground(
      id: 'd_night_dunes',
      isDark: true,
      gradient: [Color(0xFF10132B), Color(0xFF3B2E4F)],
      motifColor: Color(0x33F4C98B),
      motif: BackgroundMotif.dunes),
  ShareBackground(
      id: 'd_teal_mihrab',
      isDark: true,
      gradient: [Color(0xFF042F33), Color(0xFF0B5157)],
      motifColor: Color(0x40E8C165),
      motif: BackgroundMotif.mihrabFrame),
  ShareBackground(
      id: 'd_plum_bokeh',
      isDark: true,
      gradient: [Color(0xFF1C0F24), Color(0xFF45244F)],
      motifColor: Color(0x33F2C6E8),
      motif: BackgroundMotif.bokeh),
  ShareBackground(
      id: 'd_black_gold_lattice',
      isDark: true,
      gradient: [Color(0xFF0E0E0C), Color(0xFF25221A)],
      motifColor: Color(0x33CB9B3F),
      motif: BackgroundMotif.diagonalLattice),
  ShareBackground(
      id: 'd_indigo_rays',
      isDark: true,
      gradient: [Color(0xFF14123A), Color(0xFF2D2A6E)],
      motifColor: Color(0x1FFFFFFF),
      motif: BackgroundMotif.sunrays),
];

/// Fills its size with [background]'s gradient and motif.
class ShareBackgroundView extends StatelessWidget {
  final ShareBackground background;

  const ShareBackgroundView({super.key, required this.background});

  @override
  Widget build(BuildContext context) {
    // Clipped because the motifs deliberately draw past the edges (tiles,
    // rays) so patterns run off-canvas instead of stopping short.
    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: background.gradient,
          ),
        ),
        child: CustomPaint(
          painter: _MotifPainter(background.motif, background.motifColor),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MotifPainter extends CustomPainter {
  final BackgroundMotif motif;
  final Color color;

  _MotifPainter(this.motif, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Every motif is laid out relative to the width, so the preview and the
    // 3x export look identical.
    final u = size.width / 360;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * u;
    final fill = Paint()..color = color;

    switch (motif) {
      case BackgroundMotif.starTiles:
        _starTiles(canvas, size, u, stroke);
      case BackgroundMotif.arches:
        _arches(canvas, size, u, fill);
      case BackgroundMotif.mosqueSkyline:
        _skyline(canvas, size, u, fill);
      case BackgroundMotif.nightSky:
        _nightSky(canvas, size, u, fill);
      case BackgroundMotif.hexLattice:
        _hexLattice(canvas, size, u, stroke);
      case BackgroundMotif.lanterns:
        _lanterns(canvas, size, u, stroke, fill);
      case BackgroundMotif.overlappingCircles:
        _circles(canvas, size, u, stroke);
      case BackgroundMotif.dunes:
        _dunes(canvas, size, u, fill);
      case BackgroundMotif.mihrabFrame:
        _mihrab(canvas, size, u, stroke);
      case BackgroundMotif.bokeh:
        _bokeh(canvas, size, u, fill);
      case BackgroundMotif.diagonalLattice:
        _diagonalLattice(canvas, size, u, stroke);
      case BackgroundMotif.sunrays:
        _sunrays(canvas, size, u, fill);
    }
  }

  /// Eight-pointed star (two overlaid squares) centred at [c].
  Path _star(Offset c, double r) {
    final path = Path();
    for (int s = 0; s < 2; s++) {
      final rot = s * math.pi / 4;
      for (int i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2 + math.pi / 4;
        final p = c + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
    }
    return path;
  }

  void _starTiles(Canvas canvas, Size size, double u, Paint stroke) {
    final step = 60 * u;
    for (double y = 0; y < size.height + step; y += step) {
      for (double x = 0; x < size.width + step; x += step) {
        final c = Offset(x, y);
        canvas.drawPath(_star(c, 22 * u), stroke);
        canvas.drawCircle(c, 8 * u, stroke);
        canvas.drawPath(_star(c + Offset(step / 2, step / 2), 9 * u), stroke);
      }
    }
  }

  Path _archPath(double left, double width, double baseY, double height) {
    final shoulder = baseY - height + width * 0.55;
    return Path()
      ..moveTo(left, baseY)
      ..lineTo(left, shoulder)
      ..quadraticBezierTo(
          left, baseY - height + width * 0.12, left + width / 2, baseY - height)
      ..quadraticBezierTo(
          left + width, baseY - height + width * 0.12, left + width, shoulder)
      ..lineTo(left + width, baseY)
      ..close();
  }

  void _arches(Canvas canvas, Size size, double u, Paint fill) {
    const count = 3;
    final w = size.width / count;
    for (int i = 0; i < count; i++) {
      canvas.drawPath(
          _archPath(
              i * w + 10 * u, w - 20 * u, size.height, size.height * 0.42),
          fill);
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 14 * u), fill);
  }

  void _dome(Canvas canvas, double cx, double baseY, double r, Paint fill) {
    canvas.drawPath(
      Path()
        ..moveTo(cx - r, baseY)
        ..cubicTo(cx - r, baseY - r * 1.2, cx - r * 0.2, baseY - r * 1.35, cx,
            baseY - r * 1.7)
        ..cubicTo(cx + r * 0.2, baseY - r * 1.35, cx + r, baseY - r * 1.2,
            cx + r, baseY)
        ..close(),
      fill,
    );
  }

  void _minaret(
      Canvas canvas, double cx, double baseY, double w, double h, Paint fill) {
    canvas.drawRect(Rect.fromLTWH(cx - w / 2, baseY - h, w, h), fill);
    canvas.drawRect(
        Rect.fromLTWH(cx - w * 0.8, baseY - h * 0.72, w * 1.6, w * 0.5), fill);
    canvas.drawPath(
      Path()
        ..moveTo(cx - w / 2, baseY - h)
        ..lineTo(cx, baseY - h - w * 2.4)
        ..lineTo(cx + w / 2, baseY - h)
        ..close(),
      fill,
    );
  }

  void _crescent(Canvas canvas, Offset c, double r, Paint fill) {
    final moon = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final bite = Path()
      ..addOval(Rect.fromCircle(
          center: c + Offset(r * 0.38, -r * 0.18), radius: r * 0.86));
    canvas.drawPath(Path.combine(PathOperation.difference, moon, bite), fill);
  }

  void _skyline(Canvas canvas, Size size, double u, Paint fill) {
    final base = size.height;
    final cx = size.width / 2;
    canvas.drawRect(Rect.fromLTWH(0, base - 40 * u, size.width, 40 * u), fill);
    canvas.drawRect(
        Rect.fromLTWH(cx - 95 * u, base - 95 * u, 190 * u, 60 * u), fill);
    _dome(canvas, cx, base - 90 * u, 62 * u, fill);
    _dome(canvas, cx - 80 * u, base - 90 * u, 26 * u, fill);
    _dome(canvas, cx + 80 * u, base - 90 * u, 26 * u, fill);
    _minaret(canvas, cx - 140 * u, base - 38 * u, 14 * u, 170 * u, fill);
    _minaret(canvas, cx + 140 * u, base - 38 * u, 14 * u, 170 * u, fill);
    _crescent(
        canvas, Offset(size.width * 0.8, size.height * 0.1), 22 * u, fill);
  }

  void _nightSky(Canvas canvas, Size size, double u, Paint fill) {
    final rnd = math.Random(7);
    for (int i = 0; i < 90; i++) {
      final p = Offset(
          rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.85);
      final r = (rnd.nextDouble() * 1.4 + 0.4) * u;
      canvas.drawCircle(p, r,
          fill..color = color.withValues(alpha: 0.3 + rnd.nextDouble() * 0.7));
    }
    fill.color = color;
    _crescent(
        canvas, Offset(size.width * 0.78, size.height * 0.12), 30 * u, fill);
    final ground = Paint()..color = Colors.black.withValues(alpha: 0.35);
    _skyline(canvas, size, u, ground);
  }

  void _hexLattice(Canvas canvas, Size size, double u, Paint stroke) {
    final r = 26 * u;
    final w = math.sqrt(3) * r;
    final h = 1.5 * r;
    int row = 0;
    for (double y = 0; y < size.height + h; y += h, row++) {
      final offset = row.isOdd ? w / 2 : 0.0;
      for (double x = -w; x < size.width + w; x += w) {
        final c = Offset(x + offset, y);
        final hex = Path();
        for (int i = 0; i < 6; i++) {
          final a = math.pi / 6 + i * math.pi / 3;
          final p = c + Offset(math.cos(a), math.sin(a)) * r;
          i == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
        }
        hex.close();
        canvas.drawPath(hex, stroke);
        canvas.drawPath(_star(c, r * 0.45), stroke);
      }
    }
  }

  void _lantern(Canvas canvas, Offset top, double s, Paint stroke, Paint fill) {
    canvas.drawLine(Offset(top.dx, 0), top, stroke);
    final body = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(top.dx - 10 * s, top.dy + 12 * s)
      ..lineTo(top.dx - 14 * s, top.dy + 40 * s)
      ..lineTo(top.dx - 8 * s, top.dy + 50 * s)
      ..lineTo(top.dx + 8 * s, top.dy + 50 * s)
      ..lineTo(top.dx + 14 * s, top.dy + 40 * s)
      ..lineTo(top.dx + 10 * s, top.dy + 12 * s)
      ..close();
    canvas.drawPath(body, stroke);
    canvas.drawCircle(Offset(top.dx, top.dy + 30 * s), 4 * s, fill);
    canvas.drawLine(Offset(top.dx, top.dy + 50 * s),
        Offset(top.dx, top.dy + 58 * s), stroke);
  }

  void _lanterns(Canvas canvas, Size size, double u, Paint stroke, Paint fill) {
    const specs = [
      [0.15, 0.10, 1.0],
      [0.38, 0.20, 1.3],
      [0.62, 0.07, 0.9],
      [0.85, 0.16, 1.2],
    ];
    for (final s in specs) {
      _lantern(canvas, Offset(size.width * s[0], size.height * s[1]), s[2] * u,
          stroke..strokeWidth = 1.4 * u, fill);
    }
  }

  void _circles(Canvas canvas, Size size, double u, Paint stroke) {
    final r = 30 * u;
    final dy = r * math.sqrt(3) / 2;
    int row = 0;
    for (double y = 0; y < size.height + r; y += dy, row++) {
      for (double x = row.isOdd ? r / 2 : 0; x < size.width + r; x += r) {
        canvas.drawCircle(Offset(x, y), r, stroke);
      }
    }
  }

  void _dunes(Canvas canvas, Size size, double u, Paint fill) {
    canvas.drawCircle(
        Offset(size.width * 0.72, size.height * 0.62), 40 * u, fill);
    for (int i = 0; i < 3; i++) {
      final top = size.height * (0.68 + i * 0.09);
      final path = Path()
        ..moveTo(0, top + 20 * u)
        ..quadraticBezierTo(
            size.width * 0.3, top - 30 * u, size.width * 0.55, top + 10 * u)
        ..quadraticBezierTo(
            size.width * 0.8, top + 40 * u, size.width, top - 10 * u)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, fill);
    }
  }

  void _mihrab(Canvas canvas, Size size, double u, Paint stroke) {
    for (int i = 0; i < 3; i++) {
      final inset = (18 + i * 10) * u;
      canvas.drawPath(
        _archPath(inset, size.width - inset * 2, size.height - inset,
            size.height - inset * 2),
        stroke..strokeWidth = (i == 0 ? 2.4 : 1.0) * u,
      );
    }
  }

  void _bokeh(Canvas canvas, Size size, double u, Paint fill) {
    final rnd = math.Random(3);
    for (int i = 0; i < 26; i++) {
      final p =
          Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      canvas.drawCircle(
          p,
          (10 + rnd.nextDouble() * 38) * u,
          fill
            ..color = color.withValues(
                alpha: color.a * (0.4 + rnd.nextDouble() * 0.6)));
    }
  }

  void _diagonalLattice(Canvas canvas, Size size, double u, Paint stroke) {
    final step = 34 * u;
    for (double d = -size.height; d < size.width + size.height; d += step) {
      canvas.drawLine(
          Offset(d, 0), Offset(d + size.height, size.height), stroke);
      canvas.drawLine(
          Offset(d, size.height), Offset(d + size.height, 0), stroke);
    }
    for (double y = step / 2; y < size.height; y += step) {
      for (double x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 2.2 * u, Paint()..color = stroke.color);
      }
    }
  }

  void _sunrays(Canvas canvas, Size size, double u, Paint fill) {
    final c = Offset(size.width / 2, size.height * 0.35);
    final r = size.height * 1.2;
    const rays = 24;
    for (int i = 0; i < rays; i += 2) {
      final a1 = i * 2 * math.pi / rays;
      final a2 = (i + 1) * 2 * math.pi / rays;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a1) * r, c.dy + math.sin(a1) * r)
          ..lineTo(c.dx + math.cos(a2) * r, c.dy + math.sin(a2) * r)
          ..close(),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MotifPainter old) =>
      old.motif != motif || old.color != color;
}
