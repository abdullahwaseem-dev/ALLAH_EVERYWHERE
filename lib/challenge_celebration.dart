part of 'challenges.dart';

/// Shown when the user reaches 100%: a calm glow and a few sparkles (no
/// confetti storm), a dua, and the shareable summary.
class ChallengeCelebrationScreen extends StatefulWidget {
  final Challenge challenge;
  final List<ChallengeParticipant> members;
  final ChallengeService? service;

  const ChallengeCelebrationScreen({super.key, required this.challenge, this.members = const [], this.service});

  @override
  State<ChallengeCelebrationScreen> createState() => _ChallengeCelebrationScreenState();
}

class _ChallengeCelebrationScreenState extends State<ChallengeCelebrationScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _anim.value = 1;
      } else {
        _anim.forward();
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final badge = CurvedAnimation(parent: _anim, curve: const Interval(0, 0.45, curve: Curves.easeOutBack));
    final text = CurvedAnimation(parent: _anim, curve: const Interval(0.3, 0.75, curve: Curves.easeOut));
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: ReadableWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 220.w,
                    height: 220.w,
                    child: AnimatedBuilder(
                      animation: _anim,
                      builder: (context, child) => CustomPaint(
                        painter: _GlowPainter(_anim.value, p.accent),
                        child: Center(child: Transform.scale(scale: badge.value, child: child)),
                      ),
                      child: Container(
                        width: 96.w,
                        height: 96.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.accent,
                          boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.4), blurRadius: 24)],
                        ),
                        child: Icon(Iconsax.medal_star, color: p.bg, size: 46.sp),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  FadeTransition(
                    opacity: text,
                    child: Column(
                      children: [
                        Text(t.challengesCelebrationTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w800, color: p.text)),
                        SizedBox(height: 10.h),
                        Text(t.challengesCelebrationBody(widget.challenge.title),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15.sp, height: 1.5, color: p.sub)),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),
                  _primaryButton(
                    p,
                    t.challengesShareResult,
                    () => showChallengeSummary(context, widget.challenge, widget.members, service: widget.service),
                    icon: Iconsax.share,
                  ),
                  SizedBox(height: 14.h),
                  Text(t.challengesCertificateSoon,
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, height: 1.4, color: p.sub)),
                  TextButton.icon(
                    onPressed: () => Get.to(() => const RewardsScreen()),
                    icon: Icon(Iconsax.award, size: 17.sp, color: p.accent),
                    label: Text(t.rewardsView, style: TextStyle(fontSize: 14.sp, color: p.accent)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t.challengesBackToChallenge, style: TextStyle(fontSize: 14.sp, color: p.accent)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft radial glow that opens up, and small four-point sparkles that
/// drift outwards and fade.
class _GlowPainter extends CustomPainter {
  final double t;
  final Color color;

  _GlowPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final open = Curves.easeOut.transform(t.clamp(0.0, 1.0));
    canvas.drawCircle(
      center,
      radius * (0.45 + 0.55 * open),
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: 0.32 * open), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final fade = math.sin(math.pi * t.clamp(0.0, 1.0));
    if (fade <= 0) return;
    final paint = Paint()..color = color.withValues(alpha: 0.85 * fade);
    const count = 12;
    for (var i = 0; i < count; i++) {
      final angle = i * 2 * math.pi / count + 0.26;
      final distance = radius * (0.35 + 0.55 * open) * (i.isEven ? 1 : 0.8);
      final at = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final s = (i.isEven ? 5.0 : 3.5) * (0.6 + 0.4 * fade);
      canvas.drawPath(
        Path()
          ..moveTo(at.dx, at.dy - s)
          ..lineTo(at.dx + s * 0.3, at.dy - s * 0.3)
          ..lineTo(at.dx + s, at.dy)
          ..lineTo(at.dx + s * 0.3, at.dy + s * 0.3)
          ..lineTo(at.dx, at.dy + s)
          ..lineTo(at.dx - s * 0.3, at.dy + s * 0.3)
          ..lineTo(at.dx - s, at.dy)
          ..lineTo(at.dx - s * 0.3, at.dy - s * 0.3)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t || old.color != color;
}

/// Opens a preview of the summary card with a Share button.
Future<void> showChallengeSummary(BuildContext context, Challenge c, List<ChallengeParticipant> members,
    {ChallengeService? service}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _Palette(context).card,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
    builder: (_) => _SummarySheet(challenge: c, members: members, service: service),
  );
}

class _SummarySheet extends StatefulWidget {
  final Challenge challenge;
  final List<ChallengeParticipant> members;
  final ChallengeService? service;

  const _SummarySheet({required this.challenge, required this.members, this.service});

  @override
  State<_SummarySheet> createState() => _SummarySheetState();
}

class _SummarySheetState extends State<_SummarySheet> {
  final _captureKey = GlobalKey();
  late final Stream<List<ChallengeParticipant>>? _live = widget.service?.participants(widget.challenge.id);
  bool _sharing = false;

  Future<void> _share(BuildContext buttonContext) async {
    if (_sharing) return;
    final t = AppLocalizations.of(context)!;
    setState(() => _sharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Card not laid out');
      final image = await boundary.toImage(pixelRatio: 1080 / ChallengeSummaryCard.size.width);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('PNG encoding failed');
      if (!buttonContext.mounted) return;
      final ok = await AppShareService.shareImage(buttonContext, bytes.buffer.asUint8List());
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.challengesErrorNetwork)));
      }
    } catch (e) {
      VoidLogger.error('Failed to share the challenge summary', e);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2.r)),
              ),
              SizedBox(height: 12.h),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: RepaintBoundary(
                    key: _captureKey,
                    child: StreamBuilder<List<ChallengeParticipant>>(
                      stream: _live,
                      initialData: widget.members,
                      builder: (context, snap) =>
                          ChallengeSummaryCard(challenge: widget.challenge, members: snap.data ?? widget.members),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Builder(
                builder: (buttonContext) => _primaryButton(p, t.challengesShareResult, () => _share(buttonContext),
                    icon: Iconsax.share, busy: _sharing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The end-of-challenge image, in the style of the share cards: a painted
/// background, a panel with the result, and the app footer. Only
/// percentages are shown, whatever each member's privacy setting.
class ChallengeSummaryCard extends StatelessWidget {
  static const size = Size(360, 450);
  static const _maxRows = 5;

  final Challenge challenge;
  final List<ChallengeParticipant> members;

  const ChallengeSummaryCard({super.key, required this.challenge, required this.members});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = shareBackgrounds.firstWhere((b) => b.id == (dark ? 'd_emerald_stars' : 'l_sand_stars'));
    final panel = dark ? const Color(0xE6121210) : const Color(0xF2FFFFFF);
    final textColor = dark ? VoidColors.textDarkPrimary : const Color(0xFF1F1E17);
    final subColor = dark ? VoidColors.textDarkSecondary : const Color(0xFF6B6A5E);
    final accent = dark ? VoidColors.goldDark : VoidColors.gold;
    final footerColor = dark ? Colors.white : VoidColors.oliveDeep;
    final c = challenge;
    final sorted = ChallengeService.sortLeaderboard([...members]);
    final done = sorted.where((m) => m.completedAt != null || m.percent >= 100).length;
    final dates = DateFormat.yMMMd(lang);
    final range = '${dates.format(c.startAt)} – ${dates.format(c.endAt.subtract(const Duration(minutes: 1)))}';

    return MediaQuery.withNoTextScaling(
      child: SizedBox.fromSize(
        size: size,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShareBackgroundView(background: background),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: size.width - 40,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                              decoration: BoxDecoration(
                                color: panel,
                                borderRadius: BorderRadius.circular(24),
                                border: dark ? Border.all(color: accent.withValues(alpha: 0.35)) : null,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: dark ? 0.35 : 0.12),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8)),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration:
                                            BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.15)),
                                        child: Icon(templateFor(c.type).icon, color: accent, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                                            Text(range, style: TextStyle(fontSize: 11, color: subColor)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (c.intention.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text('“${c.intention}”',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12, height: 1.4, fontStyle: FontStyle.italic, color: textColor)),
                                  ],
                                  const SizedBox(height: 12),
                                  Center(
                                      child: Container(
                                          width: 44, height: 1.5, color: accent.withValues(alpha: 0.7))),
                                  const SizedBox(height: 10),
                                  Text(t.challengesSummaryCompleted('$done', '${sorted.length}'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accent)),
                                  const SizedBox(height: 8),
                                  for (final (i, m) in sorted.take(_maxRows).indexed)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 22,
                                            child: Text('${i + 1}',
                                                style: TextStyle(
                                                    fontSize: 12, fontWeight: FontWeight.w700, color: subColor)),
                                          ),
                                          Expanded(
                                            child: Text(m.displayName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                                          ),
                                          if (m.completedAt != null || m.percent >= 100)
                                            Padding(
                                              padding: const EdgeInsetsDirectional.only(end: 6),
                                              child: Icon(Icons.check_circle, size: 14, color: accent),
                                            ),
                                          Text('${m.percent.floor()}%',
                                              style: TextStyle(
                                                  fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
                                        ],
                                      ),
                                    ),
                                  if (sorted.length > _maxRows)
                                    Text('+${sorted.length - _maxRows}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 12, color: subColor)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                        Text(AppLinks.appName,
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: footerColor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(ShareStrings(lang).download,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10.5, fontWeight: FontWeight.w500, color: footerColor.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
