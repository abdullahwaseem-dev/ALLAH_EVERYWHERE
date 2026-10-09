part of 'rewards.dart';

/// One plant in the painted garden.
class _Spot {
  final GardenKind kind;
  final String label;
  final DateTime? date;
  final Offset at;
  final double scale;

  const _Spot(this.kind, this.label, this.date, this.at, this.scale);
}

/// Places the plants in [state] across the ground of a [size] garden, back
/// rows smaller, with a small fixed jitter so it looks planted, not gridded.
List<_Spot> _layout(RewardsState state, Size size) {
  final items = <(GardenKind, String, DateTime?)>[
    for (final p in state.plants) (p.kind, p.label, p.earnedAt),
    for (var i = 0; i < math.min(state.palms, RewardRules.maxPalmsShown); i++) (GardenKind.palm, '', null),
  ];
  if (items.isEmpty) return const [];
  final perRow = size.width < 300 ? 6 : 8;
  final rows = (items.length / perRow).ceil();
  final groundTop = size.height * 0.48;
  final groundHeight = size.height - groundTop;
  final spots = <_Spot>[];
  for (var i = 0; i < items.length; i++) {
    final row = i ~/ perRow;
    final col = i % perRow;
    // Front row first (bottom), later rows further back.
    final depth = rows == 1 ? 1.0 : 1 - row / rows;
    final y = groundTop + groundHeight * (0.2 + 0.72 * depth);
    final jitter = ((i * 37) % 11 - 5) / 5;
    final x = size.width * ((col + 0.5 + jitter * 0.18 + (row.isOdd ? 0.5 : 0)) / (perRow + 0.5));
    spots.add(_Spot(items[i].$1, items[i].$2, items[i].$3, Offset(x, y), 0.6 + 0.4 * depth));
  }
  // Paint back to front.
  spots.sort((a, b) => a.at.dy.compareTo(b.at.dy));
  return spots;
}

/// The garden scene: sky, hills and the plants earned.
class GardenPainter extends CustomPainter {
  final RewardsState state;
  final bool dark;
  final bool compact;

  GardenPainter({required this.state, required this.dark, this.compact = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = dark
        ? const [Color(0xFF0E1630), Color(0xFF26304A), Color(0xFF3B3A2C)]
        : const [Color(0xFFDDEEF5), Color(0xFFF5EBD8), Color(0xFFF8F0DF)];
    canvas.drawRect(rect, Paint()..shader = LinearGradient(colors: sky, begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(rect));

    // Moon or soft sun.
    final orb = Offset(size.width * 0.82, size.height * 0.16);
    if (dark) {
      canvas.drawCircle(orb, size.height * 0.07, Paint()..color = const Color(0xFFF3E7C4));
      canvas.drawCircle(orb + Offset(size.height * 0.03, -size.height * 0.015), size.height * 0.065, Paint()..color = const Color(0xFF16203A));
      final star = Paint()..color = const Color(0xCCF3E7C4);
      for (var i = 0; i < 14; i++) {
        canvas.drawCircle(Offset(size.width * ((i * 0.137) % 1), size.height * (0.05 + ((i * 0.071) % 0.3))), 1.1, star);
      }
    } else {
      canvas.drawCircle(orb, size.height * 0.12, Paint()..color = const Color(0x33F4C66B));
      canvas.drawCircle(orb, size.height * 0.07, Paint()..color = const Color(0xFFF6D58B));
    }

    // Two rolling hills.
    Path hill(double top, double amp, double phase) {
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 8) {
        path.lineTo(x, top + math.sin(x / size.width * math.pi * 2 + phase) * amp);
      }
      return path
        ..lineTo(size.width, size.height)
        ..close();
    }

    canvas.drawPath(hill(size.height * 0.46, size.height * 0.04, 0.6),
        Paint()..color = dark ? const Color(0xFF233626) : const Color(0xFFBFD7A5));
    canvas.drawPath(hill(size.height * 0.6, size.height * 0.03, 2.4),
        Paint()..color = dark ? const Color(0xFF2C4430) : const Color(0xFFA5C98A));

    for (final s in _layout(state, size)) {
      final unit = (compact ? 0.55 : 1.0) * s.scale * math.min(size.height * 0.16, 46);
      switch (s.kind) {
        case GardenKind.tree:
          _tree(canvas, s.at, unit);
        case GardenKind.palm:
          _palm(canvas, s.at, unit);
        case GardenKind.flower:
          _flower(canvas, s.at, unit * 0.7);
        case GardenKind.fountain:
          _fountain(canvas, s.at, unit);
      }
    }
  }

  Color get _leaf => dark ? const Color(0xFF4F8A57) : const Color(0xFF5E9E5A);
  Color get _leafLight => dark ? const Color(0xFF6BA56F) : const Color(0xFF7DBA6F);
  Color get _trunk => dark ? const Color(0xFF6B4E33) : const Color(0xFF8A6542);

  void _tree(Canvas canvas, Offset base, double u) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: base - Offset(0, u * 0.35), width: u * 0.16, height: u * 0.7),
            Radius.circular(u * 0.05)),
        Paint()..color = _trunk);
    final leaf = Paint()..color = _leaf;
    final light = Paint()..color = _leafLight;
    canvas.drawCircle(base - Offset(0, u * 0.95), u * 0.42, leaf);
    canvas.drawCircle(base - Offset(u * 0.28, u * 0.75), u * 0.3, leaf);
    canvas.drawCircle(base - Offset(-u * 0.28, u * 0.75), u * 0.3, leaf);
    canvas.drawCircle(base - Offset(u * 0.1, u * 1.08), u * 0.2, light);
  }

  void _palm(Canvas canvas, Offset base, double u) {
    final top = base - Offset(u * 0.15, u * 1.25);
    final trunk = Path()
      ..moveTo(base.dx - u * 0.06, base.dy)
      ..quadraticBezierTo(base.dx + u * 0.12, base.dy - u * 0.6, top.dx - u * 0.03, top.dy)
      ..lineTo(top.dx + u * 0.04, top.dy)
      ..quadraticBezierTo(base.dx + u * 0.2, base.dy - u * 0.6, base.dx + u * 0.06, base.dy)
      ..close();
    canvas.drawPath(trunk, Paint()..color = _trunk);
    final frond = Paint()
      ..color = _leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.1
      ..strokeCap = StrokeCap.round;
    for (final angle in [-2.6, -2.0, -1.2, -0.5, 0.1]) {
      final end = top + Offset(math.cos(angle), math.sin(angle) + 0.6) * u * 0.62;
      final ctrl = top + Offset(math.cos(angle), math.sin(angle) - 0.2) * u * 0.42;
      canvas.drawPath(Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy), frond);
    }
    canvas.drawCircle(top + Offset(0, u * 0.05), u * 0.07, Paint()..color = _trunk);
  }

  void _flower(Canvas canvas, Offset base, double u) {
    canvas.drawLine(base, base - Offset(0, u * 0.8),
        Paint()
          ..color = _leaf
          ..strokeWidth = u * 0.08);
    final head = base - Offset(0, u * 0.85);
    final petal = Paint()..color = dark ? const Color(0xFFE7A9B8) : const Color(0xFFE48FA4);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawCircle(head + Offset(math.cos(a), math.sin(a)) * u * 0.2, u * 0.15, petal);
    }
    canvas.drawCircle(head, u * 0.12, Paint()..color = const Color(0xFFF2C14E));
  }

  void _fountain(Canvas canvas, Offset base, double u) {
    final stone = Paint()..color = dark ? const Color(0xFF8C8778) : const Color(0xFFD9CFB8);
    final water = Paint()
      ..color = dark ? const Color(0xFF7FB3D5) : const Color(0xFF6FA8D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(Rect.fromCenter(center: base - Offset(0, u * 0.12), width: u * 1.3, height: u * 0.36), stone);
    canvas.drawOval(Rect.fromCenter(center: base - Offset(0, u * 0.18), width: u * 1.0, height: u * 0.2),
        Paint()..color = water.color.withValues(alpha: 0.7));
    canvas.drawRect(Rect.fromCenter(center: base - Offset(0, u * 0.45), width: u * 0.14, height: u * 0.55), stone);
    final spout = base - Offset(0, u * 0.75);
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(Path()
        ..moveTo(spout.dx, spout.dy)
        ..quadraticBezierTo(spout.dx + side * u * 0.3, spout.dy - u * 0.35, spout.dx + side * u * 0.45, spout.dy + u * 0.5), water);
    }
  }

  @override
  bool shouldRepaint(GardenPainter old) =>
      old.dark != dark || old.state.plants.length != state.plants.length || old.state.palms != state.palms;
}

String _gardenKindLabel(GardenKind kind, AppLocalizations t) => switch (kind) {
      GardenKind.tree => t.gardenTree,
      GardenKind.fountain => t.gardenFountain,
      GardenKind.flower => t.gardenFlower,
      GardenKind.palm => t.gardenPalm,
    };

IconData _gardenIcon(GardenKind kind) => switch (kind) {
      GardenKind.tree => Iconsax.tree,
      GardenKind.fountain => Iconsax.drop,
      GardenKind.flower => Iconsax.lovely,
      GardenKind.palm => Iconsax.sun_fog,
    };

/// My Jannah Garden: every completed challenge, finished Khatam, memorised
/// surah and 1,000 dhikr plants something. Nothing ever wilts or is taken
/// away.
class JannahGardenScreen extends StatefulWidget {
  final RewardsService? service;

  const JannahGardenScreen({super.key, this.service});

  @override
  State<JannahGardenScreen> createState() => _JannahGardenScreenState();
}

class _JannahGardenScreenState extends State<JannahGardenScreen> {
  late final RewardsService _svc = widget.service ?? RewardsService();
  late final Stream<RewardsState> _stream = _svc.watch();

  void _tapAt(Offset local, Size size, RewardsState state) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    _Spot? best;
    var bestDistance = double.infinity;
    for (final s in _layout(state, size)) {
      final d = (s.at - const Offset(0, 20) - local).distance;
      if (d < bestDistance) {
        bestDistance = d;
        best = s;
      }
    }
    if (best == null || bestDistance > 44) return;
    final parts = [
      _gardenKindLabel(best.kind, t),
      if (best.label.isNotEmpty) best.label,
      if (best.date != null) DateFormat.yMMMd(lang).format(best.date!),
    ];
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(parts.join(' · '))));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _P(context);
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.rewardsGarden, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: p.text)),
        centerTitle: true,
      ),
      body: ReadableWidth(
        child: StreamBuilder<RewardsState>(
          stream: _stream,
          initialData: const RewardsState(),
          builder: (context, snap) {
            final state = snap.data ?? const RewardsState();
            final empty = state.plants.isEmpty && state.palms == 0;
            final counts = {
              for (final k in GardenKind.values)
                k: k == GardenKind.palm ? state.palms : state.plants.where((p) => p.kind == k).length,
            };
            return ListView(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: SizedBox(
                    height: 300.h,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        return GestureDetector(
                          onTapUp: (d) => _tapAt(d.localPosition, size, state),
                          child: Semantics(
                            label: '${t.rewardsGarden}, ${t.rewardsPlants(state.plants.length + state.palms)}',
                            child: CustomPaint(size: size, painter: GardenPainter(state: state, dark: p.dark)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (state.palms > RewardRules.maxPalmsShown) ...[
                  SizedBox(height: 6.h),
                  Text(t.gardenMorePalms(state.palms - RewardRules.maxPalmsShown),
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, color: p.sub)),
                ],
                SizedBox(height: 14.h),
                Text(t.gardenReminder,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, height: 1.45, fontWeight: FontWeight.w700, color: p.text)),
                SizedBox(height: 4.h),
                Text(t.gardenNeverLost,
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: p.sub)),
                if (empty) ...[
                  SizedBox(height: 14.h),
                  Text(t.gardenEmpty,
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp, height: 1.5, color: p.sub)),
                ],
                SizedBox(height: 16.h),
                _cardBox(
                  p,
                  child: Column(
                    children: [
                      for (final k in GardenKind.values)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            children: [
                              Icon(_gardenIcon(k), size: 18.sp, color: p.accent),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(_gardenKindLabel(k, t), style: TextStyle(fontSize: 13.sp, color: p.text)),
                              ),
                              Text('${counts[k]}',
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: p.text)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                _hadithCard(p, t),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hadithCard(_P p, AppLocalizations t) => _cardBox(
        p,
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.gardenHadithTitle, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: p.text)),
            SizedBox(height: 10.h),
            Text(gardenHadith.arabic,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: ScriptureText.arabic(fontSize: 19.sp, color: p.text)),
            SizedBox(height: 10.h),
            Text(gardenHadith.english, style: TextStyle(fontSize: 13.5.sp, height: 1.5, color: p.text)),
            SizedBox(height: 8.h),
            Text(gardenHadith.reference,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: p.accent)),
            Text(gardenHadith.grading, style: TextStyle(fontSize: 11.5.sp, color: p.sub)),
            SizedBox(height: 8.h),
            Text(t.gardenHadithNote, style: TextStyle(fontSize: 12.sp, height: 1.45, color: p.sub)),
          ],
        ),
      );
}
