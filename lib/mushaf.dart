import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/challenge_auto_progress.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/services/bookmark_service.dart';
import 'package:allah_everywhere/services/mushaf_service.dart';
import 'package:allah_everywhere/services/quran_audio_service.dart';
import 'package:allah_everywhere/share_cards/mood_data.dart' show QuranRef;
import 'package:allah_everywhere/share_cards/share_content.dart';
import 'package:allah_everywhere/share_cards/share_studio_screen.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/reward_cosmetics.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

/// Page colours for the chosen background.
class _PageColors {
  final Color paper;
  final Color ink;
  final Color accent;
  final Color muted;

  const _PageColors(this.paper, this.ink, this.accent, this.muted);

  factory _PageColors.of(MushafBackground bg, bool isDark) {
    final resolved = bg == MushafBackground.auto ? (isDark ? MushafBackground.night : MushafBackground.white) : bg;
    switch (resolved) {
      case MushafBackground.night:
        return _PageColors(VoidColors.mushafNight, VoidColors.mushafNightInk, VoidColors.goldDark,
            VoidColors.mushafNightInk.withValues(alpha: 0.6));
      case MushafBackground.sepia:
        return _PageColors(VoidColors.mushafSepia, VoidColors.mushafSepiaInk, VoidColors.gold,
            VoidColors.mushafSepiaInk.withValues(alpha: 0.6));
      case MushafBackground.white:
      case MushafBackground.auto:
        return _PageColors(VoidColors.mushafWhite, VoidColors.mushafWhiteInk, VoidColors.gold,
            VoidColors.mushafWhiteInk.withValues(alpha: 0.55));
    }
  }
}

/// The Quran page by page (Madani Mushaf, 604 pages), turning right-to-left.
/// Long-press an ayah for its translation, audio, bookmark and share.
class MushafScreen extends StatefulWidget {
  final int initialPage;

  const MushafScreen({super.key, this.initialPage = 1});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final BookmarkService _bookmarks = BookmarkService();
  late final PageController _pages;
  late int _page = widget.initialPage.clamp(1, MushafService.pageCount);
  double _fontScale = MushafService.fontScale;
  MushafBackground _background = MushafService.background;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: _page - 1);
    MushafService.setLastPage(_page);
    ChallengeAutoProgress.notePage(_page);
    _loadBookmark();
  }

  @override
  void dispose() {
    _pages.dispose();
    ChallengeAutoProgress.flush();
    super.dispose();
  }

  Future<void> _loadBookmark() async {
    final page = _page;
    final marked = await _bookmarks.isBookmarked(BookmarkType.mushafPage, '$page');
    if (mounted && page == _page) setState(() => _bookmarked = marked);
  }

  void _onPageChanged(int index) {
    setState(() {
      _page = index + 1;
      _bookmarked = false;
    });
    MushafService.setLastPage(_page);
    ChallengeAutoProgress.notePage(_page);
    _loadBookmark();
  }

  void _goTo(int page) {
    _pages.jumpToPage(page.clamp(1, MushafService.pageCount) - 1);
  }

  Future<void> _toggleBookmark({int? page, String? subtitle}) async {
    final t = AppLocalizations.of(context)!;
    final p = page ?? _page;
    final first = MushafService.segments(p).first;
    HapticFeedback.lightImpact();
    final marked = await _bookmarks.toggle(
      BookmarkType.mushafPage,
      '$p',
      t.mushafPageN('$p'),
      subtitle ?? '${quran.getSurahName(first.surah)} · ${t.mushafJuzN('${MushafService.juzOfPage(p)}')}',
    );
    if (mounted && p == _page) setState(() => _bookmarked = marked);
  }

  String _language() => Localizations.localeOf(context).languageCode;

  Future<void> _playFrom(int surah, int ayah) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final handler = QuranAudioService.handler;
    try {
      await handler.loadSurah(surah, startAtAyah: ayah, reciterId: QuranAudioService.selectedReciterId);
      await handler.play();
      messenger.showSnackBar(SnackBar(
        content: Text(t.mushafPlaying(quran.getSurahName(surah), '$ayah')),
        action: SnackBarAction(label: t.hifzStop, onPressed: () => handler.stop()),
        duration: const Duration(seconds: 6),
      ));
    } catch (e) {
      VoidLogger.error('Mushaf: could not play from $surah:$ayah', e);
      messenger.showSnackBar(SnackBar(content: Text(t.mushafAudioFailed)));
    }
  }

  void _showAyah(int surah, int ayah, _PageColors c) {
    final t = AppLocalizations.of(context)!;
    final lang = _language();
    final content = ShareContent.fromQuran(QuranRef(surah, ayah), lang);
    final page = MushafService.pageOf(surah, ayah);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.8),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.mushafAyahTitle(quran.getSurahName(surah), '$ayah'),
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: c.accent),
                ),
                SizedBox(height: 10.h),
                Text(
                  content.arabic,
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  style: ScriptureText.arabic(fontSize: 21.sp, color: c.ink),
                ),
                if (content.translation.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Text(
                    content.translation,
                    textDirection: content.translationIsUrdu ? TextDirection.rtl : null,
                    style: content.translationIsUrdu
                        ? ScriptureText.urdu(fontSize: 14.sp, color: c.ink)
                        : TextStyle(fontSize: 14.sp, height: 1.5, color: c.ink),
                  ),
                ],
                SizedBox(height: 16.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  alignment: WrapAlignment.center,
                  children: [
                    _sheetAction(Iconsax.play, t.mushafPlayFromAyah, c, () {
                      Navigator.pop(sheet);
                      _playFrom(surah, ayah);
                    }),
                    _sheetAction(Iconsax.archive_add, t.mushafBookmarkPage, c, () {
                      Navigator.pop(sheet);
                      _toggleBookmark(page: page, subtitle: t.mushafAyahTitle(quran.getSurahName(surah), '$ayah'));
                    }),
                    _sheetAction(Iconsax.share, t.share, c, () {
                      Navigator.pop(sheet);
                      Get.to(() => ShareStudioScreen(initialContent: content));
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetAction(IconData icon, String label, _PageColors c, VoidCallback onTap) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18.sp, color: c.accent),
        label: Text(label, style: TextStyle(fontSize: 12.5.sp, color: c.ink)),
        style: OutlinedButton.styleFrom(side: BorderSide(color: c.accent.withValues(alpha: 0.6))),
      );

  void _showJump(_PageColors c) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
      builder: (sheet) => _JumpSheet(
        colors: c,
        onGo: (page) {
          Navigator.pop(sheet);
          _goTo(page);
        },
      ),
    );
  }

  void _showSettings() {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheet) {
          final c = _PageColors.of(_background, isDark);
          void update(VoidCallback change) {
            setState(change);
            setSheet(() {});
          }

          return Container(
            color: c.paper,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.mushafSettings,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: c.ink)),
                    SizedBox(height: 12.h),
                    Text(t.mushafTextSize, style: TextStyle(fontSize: 13.sp, color: c.ink)),
                    Slider(
                      value: _fontScale,
                      min: MushafService.minFontScale,
                      max: MushafService.maxFontScale,
                      divisions: 8,
                      activeColor: c.accent,
                      label: '${(_fontScale * 100).round()}%',
                      onChanged: (v) {
                        update(() => _fontScale = v);
                        MushafService.setFontScale(v);
                      },
                    ),
                    Text(t.mushafBackground, style: TextStyle(fontSize: 13.sp, color: c.ink)),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: [
                        for (final (bg, label) in [
                          (MushafBackground.auto, t.mushafBgAuto),
                          (MushafBackground.white, t.mushafBgWhite),
                          (MushafBackground.sepia, t.mushafBgSepia),
                          (MushafBackground.night, t.mushafBgNight),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _background == bg,
                            onSelected: (_) {
                              update(() => _background = bg);
                              MushafService.setBackground(bg);
                            },
                            selectedColor: c.accent,
                            backgroundColor: c.paper,
                            showCheckmark: false,
                            labelStyle: TextStyle(fontSize: 12.sp, color: _background == bg ? Colors.white : c.ink),
                            side: BorderSide(color: c.accent.withValues(alpha: 0.4)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = _PageColors.of(_background, isDark);
    final first = MushafService.segments(_page).first;

    return Scaffold(
      backgroundColor: c.paper,
      appBar: AppBar(
        backgroundColor: c.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: Text(
          quran.getSurahName(first.surah),
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: c.ink),
        ),
        actions: [
          IconButton(
            tooltip: _bookmarked ? t.mushafRemoveBookmark : t.mushafBookmarkPage,
            icon: Icon(_bookmarked ? Icons.bookmark : Icons.bookmark_outline, color: c.accent),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            tooltip: t.mushafGoTo,
            icon: Icon(Iconsax.search_normal_1, color: c.accent, size: 20.sp),
            onPressed: () => _showJump(c),
          ),
          IconButton(
            tooltip: t.mushafSettings,
            icon: Icon(Iconsax.setting_4, color: c.accent, size: 20.sp),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        // A Mushaf turns right-to-left whatever the app language: page 2 is
        // to the left of page 1.
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: PageView.builder(
            controller: _pages,
            itemCount: MushafService.pageCount,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => ReadableWidth(
              child: _MushafPage(
                page: index + 1,
                colors: c,
                fontScale: _fontScale,
                onLongPressAyah: (s, a) => _showAyah(s, a, c),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MushafPage extends StatefulWidget {
  final int page;
  final _PageColors colors;
  final double fontScale;
  final void Function(int surah, int ayah) onLongPressAyah;

  const _MushafPage({
    required this.page,
    required this.colors,
    required this.fontScale,
    required this.onLongPressAyah,
  });

  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  late final List<PageSegment> _segments = MushafService.segments(widget.page);
  (int, int)? _pressed;

  // Long-press is detected per text block, then mapped to the ayah under the
  // finger by character position. (Per-span recognizers only fire when the
  // finger is on a glyph's own bounds, which misses the generous Mushaf line
  // spacing - about half of every line.)
  late final List<GlobalKey> _textKeys = [for (final _ in _segments) GlobalKey()];

  /// Character offset where each ayah's text ends, per segment.
  List<int> _ayahEnds(PageSegment seg) {
    var offset = 0;
    return [
      for (int a = seg.start; a <= seg.end; a++) offset += _ayahText(seg.surah, a).length + _endText(a).length,
    ];
  }

  static String _ayahText(int surah, int ayah) => '${quran.getVerse(surah, ayah)} ';
  static String _endText(int ayah) => '${quran.getVerseEndSymbol(ayah)} ';

  // --- Fit the page to the screen, like a printed Mushaf page --------------

  static const double _minFit = 14, _maxFit = 30;
  static const double _lineHeight = 2.0;
  (double, double, double)? _fitKey;
  double _fitSize = 20;

  static TextStyle _arabic(double size, Color color, {FontWeight? weight}) =>
      ScriptureText.arabic(fontSize: size, color: color, fontWeight: weight).copyWith(height: _lineHeight);

  static String _surahTitle(int surah) => 'سُورَةُ ${quran.getSurahNameArabic(surah)}';

  TextSpan _blockSpan(PageSegment seg, TextStyle text, Color accent, {bool highlight = true}) => TextSpan(
        children: [
          for (int a = seg.start; a <= seg.end; a++)
            TextSpan(
              text: _ayahText(seg.surah, a),
              style: highlight && _pressed == (seg.surah, a)
                  ? text.copyWith(backgroundColor: accent.withValues(alpha: 0.25))
                  : null,
              children: [TextSpan(text: _endText(a), style: text.copyWith(color: accent))],
            ),
        ],
      );

  /// Height of the page's content at font [size] in [width].
  double _contentHeight(double size, double width, TextScaler scaler) {
    double measure(InlineSpan span, TextStyle style, TextAlign align) {
      final painter = TextPainter(
        text: TextSpan(style: style, children: [span]),
        textAlign: align,
        textDirection: TextDirection.rtl,
        textScaler: scaler,
      )..layout(maxWidth: width);
      final h = painter.height;
      painter.dispose();
      return h;
    }

    final text = _arabic(size, Colors.black);
    var total = 0.0;
    for (final seg in _segments) {
      if (seg.startsSurah) {
        // Frame: margins 2 x 8, padding 2 x 3 + 2 x 4, borders ~4.
        total += 16.h +
            6.r +
            8.h +
            4 +
            measure(TextSpan(text: _surahTitle(seg.surah)), _arabic(size * 0.9, Colors.black, weight: FontWeight.w700),
                TextAlign.center);
      }
      if (seg.showsBismillah) total += 4.h + measure(const TextSpan(text: quran.basmala), text, TextAlign.center);
      total += measure(_blockSpan(seg, text, Colors.black, highlight: false), text, TextAlign.justify);
    }
    return total;
  }

  /// Largest font size (within [_minFit]..[_maxFit]) at which the page fits.
  double _fittedFontSize(double width, double height, TextScaler scaler) {
    final key = (width, height, scaler.scale(10));
    if (_fitKey == key) return _fitSize;
    var lo = _minFit, hi = _maxFit;
    if (_contentHeight(lo, width, scaler) > height) {
      hi = lo; // can't fit even at the minimum: stay readable and scroll
    } else {
      for (int i = 0; i < 9; i++) {
        final mid = (lo + hi) / 2;
        if (_contentHeight(mid, width, scaler) <= height) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      hi = lo;
    }
    _fitKey = key;
    _fitSize = hi;
    return hi;
  }

  Future<void> _onLongPress(int segmentIndex, LongPressStartDetails details) async {
    final paragraph = _textKeys[segmentIndex].currentContext?.findRenderObject();
    if (paragraph is! RenderParagraph) return;
    final position = paragraph.getPositionForOffset(paragraph.globalToLocal(details.globalPosition));
    final seg = _segments[segmentIndex];
    final ends = _ayahEnds(seg);
    final index = ends.indexWhere((end) => position.offset < end);
    final ayah = seg.start + (index == -1 ? ends.length - 1 : index);
    HapticFeedback.mediumImpact();
    setState(() => _pressed = (seg.surah, ayah));
    widget.onLongPressAyah(seg.surah, ayah);
    // Clear the highlight once the sheet has had time to open over it.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _pressed = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = widget.colors;

    return Column(
      children: [
        // Header: surah of the page and its Juz, like a printed Mushaf.
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, 2.h, 18.w, 4.h),
          child: Row(
            children: [
              Text(
                quran.getSurahNameArabic(_segments.first.surah),
                style: ScriptureText.arabic(fontSize: 13.sp, color: c.muted),
              ),
              const Spacer(),
              Text(
                t.mushafJuzN('${MushafService.juzOfPage(widget.page)}'),
                style: TextStyle(fontSize: 12.sp, color: c.muted),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 0.8, color: c.accent.withValues(alpha: 0.4), indent: 18.w, endIndent: 18.w),
        Expanded(
          child: MushafPageFrame(
            color: c.accent,
            child: LayoutBuilder(
            builder: (context, constraints) {
              final hPad = 18.w, vPad = 10.h;
              // Fit the page to the screen; the text-size setting scales up
              // from there (larger text then scrolls within the page).
              final fitted = _fittedFontSize(
                constraints.maxWidth - 2 * hPad,
                constraints.maxHeight - 2 * vPad,
                MediaQuery.textScalerOf(context),
              );
              final fontSize = fitted * widget.fontScale;
              final text = _arabic(fontSize, c.ink);
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, seg) in _segments.indexed) ...[
                      if (seg.startsSurah)
                        _SurahHeader(
                            title: _surahTitle(seg.surah),
                            colors: c,
                            style: _arabic(fontSize * 0.9, c.ink, weight: FontWeight.w700)),
                      if (seg.showsBismillah)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Text(quran.basmala, textAlign: TextAlign.center, style: text),
                        ),
                      GestureDetector(
                        onLongPressStart: (d) => _onLongPress(i, d),
                        child: Text.rich(
                          key: _textKeys[i],
                          _blockSpan(seg, text, c.accent),
                          style: text,
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 2.h, bottom: 6.h),
          child: Text('${widget.page}', style: TextStyle(fontSize: 12.sp, color: c.muted)),
        ),
      ],
    );
  }
}

/// The framed title that opens a surah, as in a printed Mushaf.
class _SurahHeader extends StatelessWidget {
  final String title;
  final _PageColors colors;
  final TextStyle style;

  const _SurahHeader({required this.title, required this.colors, required this.style});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        border: Border.all(color: c.accent, width: 1.2),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: 0.12),
          border: Border.all(color: c.accent.withValues(alpha: 0.6), width: 0.8),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(title, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: style),
      ),
    );
  }
}

/// Go to a page, Juz, Hizb or surah. Owns its text field's controller, so the
/// controller lives exactly as long as the sheet (including its closing
/// animation).
class _JumpSheet extends StatefulWidget {
  final _PageColors colors;
  final ValueChanged<int> onGo;

  const _JumpSheet({required this.colors, required this.onGo});

  @override
  State<_JumpSheet> createState() => _JumpSheetState();
}

class _JumpSheetState extends State<_JumpSheet> {
  final TextEditingController _pageField = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pageField.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations t) {
    final p = int.tryParse(_pageField.text.trim());
    if (p == null || p < 1 || p > MushafService.pageCount) {
      setState(() => _error = t.mushafPageRange);
    } else {
      widget.onGo(p);
    }
  }

  Widget _numberGrid(int count, int Function(int) pageFor) {
    final c = widget.colors;
    return GridView.builder(
      padding: EdgeInsets.all(12.w),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 64.r,
        mainAxisSpacing: 8.r,
        crossAxisSpacing: 8.r,
      ),
      itemCount: count,
      itemBuilder: (_, i) => InkWell(
        onTap: () => widget.onGo(pageFor(i + 1)),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: c.accent.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text('${i + 1}', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: c.ink)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = widget.colors;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: Text(t.mushafGoTo, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: c.ink)),
            ),
            TabBar(
              labelColor: c.accent,
              unselectedLabelColor: c.muted,
              indicatorColor: c.accent,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: t.mushafJumpPage),
                Tab(text: t.mushafJumpJuz),
                Tab(text: t.mushafJumpHizb),
                Tab(text: t.mushafJumpSurah),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      children: [
                        TextField(
                          controller: _pageField,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textInputAction: TextInputAction.go,
                          onSubmitted: (_) => _submit(t),
                          style: TextStyle(fontSize: 18.sp, color: c.ink),
                          decoration: InputDecoration(hintText: '1 - ${MushafService.pageCount}', errorText: _error),
                        ),
                        SizedBox(height: 14.h),
                        ElevatedButton(
                          onPressed: () => _submit(t),
                          style: ElevatedButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
                          child: Text(t.mushafGo),
                        ),
                      ],
                    ),
                  ),
                  _numberGrid(30, MushafService.pageForJuz),
                  _numberGrid(60, MushafService.pageForHizb),
                  ListView.builder(
                    itemCount: quran.totalSurahCount,
                    itemBuilder: (_, i) => ListTile(
                      onTap: () => widget.onGo(MushafService.pageForSurah(i + 1)),
                      leading: Text('${i + 1}', style: TextStyle(fontSize: 13.sp, color: c.muted)),
                      title: Text(quran.getSurahName(i + 1), style: TextStyle(fontSize: 14.sp, color: c.ink)),
                      trailing: Text(
                        quran.getSurahNameArabic(i + 1),
                        style: ScriptureText.arabic(fontSize: 16.sp, color: c.ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
