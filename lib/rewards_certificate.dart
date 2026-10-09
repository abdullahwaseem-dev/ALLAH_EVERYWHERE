part of 'rewards.dart';

String certificateResultLabel(String result, AppLocalizations t) => switch (result) {
      'perfect' => t.certResultPerfect,
      'early' => t.certResultEarly,
      _ => t.certResultCompleted,
    };

/// A certificate as an image: parchment, an Islamic geometric border whose
/// style follows the result, and "MashaAllah" / "BarakAllahu feek" in Amiri.
/// Laid out in its own 360-wide space (like the share cards) so the preview
/// and the exported image match. Always light, as a printed certificate.
class CertificateCard extends StatelessWidget {
  static const size = Size(360, 480);

  final ChallengeCertificate certificate;

  const CertificateCard({super.key, required this.certificate});

  static const _ink = Color(0xFF2E2A1E);
  static const _muted = Color(0xFF6B6452);
  static const _gold = Color(0xFFB8862F);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final c = certificate;
    final dates = DateFormat.yMMMd(lang);
    final type = ChallengeType.fromName(c.challengeType);
    const amiri = TextStyle(fontFamily: 'Amiri', color: _gold, height: 1.3);
    return MediaQuery.withNoTextScaling(
      child: SizedBox.fromSize(
        size: size,
        child: Material(
          type: MaterialType.transparency,
          child: CustomPaint(
            painter: _CertificateBorderPainter(c.result),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 34, 40, 26),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: size.width - 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ما شاء الله',
                          textDirection: TextDirection.rtl,
                          style: amiri.copyWith(fontSize: 34, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(t.certTitle.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800, color: _muted)),
                      const SizedBox(height: 14),
                      Text(t.certIntro, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _muted)),
                      const SizedBox(height: 6),
                      Text(c.name.isEmpty ? '—' : c.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Amiri', fontSize: 28, fontWeight: FontWeight.w700, color: _ink, height: 1.2)),
                      const SizedBox(height: 4),
                      Text(t.certCompleted, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _muted)),
                      const SizedBox(height: 6),
                      Text(c.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink, height: 1.25)),
                      const SizedBox(height: 4),
                      Text('${challengeTypeLabel(type, t)} · ${dates.format(c.startAt)} – ${dates.format(c.completedAt)}',
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: _muted)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _gold.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(templateFor(type).icon, size: 13, color: _gold),
                            const SizedBox(width: 6),
                            Text(certificateResultLabel(c.result, t),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ink)),
                          ],
                        ),
                      ),
                      if (c.dedication.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(t.certDedicated(c.dedication),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: _ink)),
                      ],
                      const SizedBox(height: 12),
                      Text('بارك الله فيك',
                          textDirection: TextDirection.rtl,
                          style: amiri.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(t.rewardsRealReward,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: _muted)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(VoidImages.launcher, width: 18, height: 18),
                          const SizedBox(width: 6),
                          const Text(AppLinks.appName,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _muted)),
                        ],
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

/// Parchment and border. "completed": one line with stars in the corners;
/// "early": a double line; "perfect" (never missed a day): a double line
/// with a band of eight-point stars all round.
class _CertificateBorderPainter extends CustomPainter {
  final String result;

  _CertificateBorderPainter(this.result);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFFBF1), Color(0xFFF3E6C8)],
          radius: 0.9,
        ).createShader(rect),
    );
    const gold = CertificateCard._gold;
    final line = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final thin = Paint()
      ..color = gold.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final fill = Paint()..color = gold;
    canvas.drawRect(rect.deflate(12), line);
    if (result != 'completed') canvas.drawRect(rect.deflate(17), thin);
    if (result == 'perfect') {
      canvas.drawRect(rect.deflate(28), thin);
      // A band of small stars between the lines.
      const step = 16.0;
      for (var x = 22.5; x < size.width - 20; x += step) {
        canvas.drawPath(eightPointStar(Offset(x, 22.5), 3.2), fill);
        canvas.drawPath(eightPointStar(Offset(x, size.height - 22.5), 3.2), fill);
      }
      for (var y = 22.5 + step; y < size.height - 20 - step; y += step) {
        canvas.drawPath(eightPointStar(Offset(22.5, y), 3.2), fill);
        canvas.drawPath(eightPointStar(Offset(size.width - 22.5, y), 3.2), fill);
      }
    }
    final corner = result == 'perfect' ? 9.0 : 7.0;
    for (final c in [
      const Offset(12, 12),
      Offset(size.width - 12, 12),
      Offset(12, size.height - 12),
      Offset(size.width - 12, size.height - 12),
    ]) {
      canvas.drawCircle(c, corner + 2, Paint()..color = const Color(0xFFFBF3E2));
      canvas.drawPath(eightPointStar(c, corner), fill);
    }
  }

  @override
  bool shouldRepaint(_CertificateBorderPainter old) => old.result != result;
}

/// Shows a certificate with Share as image / Share as PDF.
class CertificateScreen extends StatefulWidget {
  final ChallengeCertificate certificate;

  const CertificateScreen({super.key, required this.certificate});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final _captureKey = GlobalKey();
  bool _busy = false;

  Future<Uint8List?> _png() async {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 1080 / CertificateCard.size.width);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }

  Future<void> _share(BuildContext buttonContext, {required bool asPdf}) async {
    if (_busy) return;
    final t = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final png = await _png();
      if (png == null || !buttonContext.mounted) return;
      if (!asPdf) {
        await AppShareService.shareImage(buttonContext, png);
        return;
      }
      final doc = pw.Document();
      final w = CertificateCard.size.width * 1.5, h = CertificateCard.size.height * 1.5;
      doc.addPage(pw.Page(
        pageFormat: pdf.PdfPageFormat(w, h),
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
      ));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/certificate_${widget.certificate.challengeId}.pdf');
      await file.writeAsBytes(await doc.save(), flush: true);
      if (!buttonContext.mounted) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        sharePositionOrigin: AppShareService.originFor(buttonContext),
      ));
    } catch (e) {
      VoidLogger.error('Could not share the certificate', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.challengesErrorNetwork)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _P(context);
    Widget button(String label, IconData icon, {required bool pdf, required bool filled}) => Expanded(
          child: Builder(
            builder: (buttonContext) {
              final onPressed = _busy ? null : () => _share(buttonContext, asPdf: pdf);
              final child = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17.sp),
                  SizedBox(width: 6.w),
                  Flexible(child: Text(label, style: TextStyle(fontSize: 13.sp))),
                ],
              );
              return filled
                  ? FilledButton(
                      onPressed: onPressed,
                      style: FilledButton.styleFrom(
                          backgroundColor: p.accent,
                          foregroundColor: p.bg,
                          padding: EdgeInsets.symmetric(vertical: 12.h)),
                      child: child)
                  : OutlinedButton(
                      onPressed: onPressed,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: p.text,
                          side: BorderSide(color: p.accent.withValues(alpha: 0.5)),
                          padding: EdgeInsets.symmetric(vertical: 12.h)),
                      child: child);
            },
          ),
        );
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.certTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: p.text)),
        centerTitle: true,
      ),
      body: ReadableWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
          children: [
            FittedBox(
              fit: BoxFit.contain,
              child: RepaintBoundary(
                key: _captureKey,
                child: CertificateCard(certificate: widget.certificate),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                button(t.certShareImage, Iconsax.gallery, pdf: false, filled: true),
                SizedBox(width: 10.w),
                button(t.certSharePdf, Iconsax.document, pdf: true, filled: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
