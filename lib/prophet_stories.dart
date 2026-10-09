import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/models/prophet_story.dart';
import 'package:allah_everywhere/seerat.dart';
import 'package:allah_everywhere/services/bookmark_service.dart';
import 'package:allah_everywhere/services/prophet_stories_service.dart';
import 'package:allah_everywhere/services/quran_audio_service.dart';
import 'package:allah_everywhere/surah.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

/// Theme colours shared by the Prophets' Stories screens.
class _Palette {
  final Color accent, text, sub, card, bg;

  _Palette(BuildContext context)
      : accent = _dark(context) ? VoidColors.goldDark : VoidColors.gold,
        text = _dark(context) ? VoidColors.textDarkPrimary : VoidColors.oliveDeep,
        sub = _dark(context) ? VoidColors.textDarkSecondary : VoidColors.textSecondary,
        card = _dark(context) ? VoidColors.cardDark : VoidColors.cardLight,
        bg = _dark(context) ? VoidColors.bgDark : VoidColors.bgLight;

  static bool _dark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
}

bool _isRtl(String languageCode) => languageCode == 'ar' || languageCode == 'ur';

TextDirection _directionOf(String languageCode) => _isRtl(languageCode) ? TextDirection.rtl : TextDirection.ltr;

/// Text in [languageCode] (Urdu and Arabic in their script fonts), scaled by
/// the reader's text size setting.
TextStyle _bodyStyle(String languageCode, double size, Color color, {FontWeight? weight, double scale = 1}) {
  final s = size * scale;
  if (languageCode == 'ur') return ScriptureText.urdu(fontSize: s, color: color, fontWeight: weight);
  if (languageCode == 'ar') return ScriptureText.arabic(fontSize: s + 1.5.sp, color: color, fontWeight: weight);
  return TextStyle(fontSize: s, height: 1.6, color: color, fontWeight: weight);
}

/// A Prophet's name in the app language with the honorific after it:
/// ﷺ for Muhammad, (AS) / عليه السلام for the others.
String prophetDisplayName(ProphetIndexEntry entry, String languageCode, AppLocalizations t) =>
    '${entry.nameIn(languageCode)} ${entry.isFinalMessenger ? 'ﷺ' : t.storiesHonorific}';

/// The `quran` package translation for the app language. It has no German
/// or Hindi edition, so those fall back to English (as in the Surah reader);
/// Arabic shows no translation.
quran.Translation? _quranTranslation(String languageCode) {
  switch (languageCode) {
    case 'ar':
      return null;
    case 'ur':
      return quran.Translation.urdu;
    case 'zh':
      return quran.Translation.chinese;
    case 'fr':
      return quran.Translation.frHamidullah;
    case 'tr':
      return quran.Translation.trSaheeh;
    default:
      return quran.Translation.enSaheeh;
  }
}

/// The 'Under review' tag on unreviewed stories - debug builds only.
class _ReviewTag extends StatelessWidget {
  const _ReviewTag();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: VoidColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: VoidColors.warning.withValues(alpha: 0.5)),
      ),
      child: Text(t.storiesUnderReview,
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: VoidColors.warning)),
    );
  }
}

/// An eight-pointed star (two overlapping squares) drawn in the corner of a
/// timeline card - geometric decoration, never images of people.
class _StarPainter extends CustomPainter {
  final Color color;

  _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    for (final ring in [r, r * 0.62]) {
      for (final angle in [0.0, math.pi / 4]) {
        final path = Path();
        for (var i = 0; i < 4; i++) {
          final a = angle + i * math.pi / 2;
          final p = center + Offset(math.cos(a), math.sin(a)) * ring;
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path..close(), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

class _TimelineData {
  final List<ProphetIndexEntry> entries;
  final Map<String, ProphetStory> stories;

  const _TimelineData(this.entries, this.stories);
}

/// The 25 Prophets named in the Quran as a timeline, Adam (AS) at the top
/// to Muhammad ﷺ at the bottom. Prophets without a story yet show
/// "Coming soon"; Muhammad ﷺ links to the Seerah section.
/// Home's "Story of the day" card: one Prophet a day, with the story's title
/// and summary in the app language. Shows nothing until the story has
/// loaded, or if it cannot be loaded, so Home never shows an error here.
class StoryOfTheDayCard extends StatefulWidget {
  /// Space around the card, applied only when it is shown.
  final EdgeInsetsGeometry padding;

  const StoryOfTheDayCard({super.key, this.padding = EdgeInsets.zero});

  @override
  State<StoryOfTheDayCard> createState() => _StoryOfTheDayCardState();
}

class _StoryOfTheDayCardState extends State<StoryOfTheDayCard> {
  final ProphetStoriesService _service = ProphetStoriesService();
  Future<(ProphetIndexEntry, ProphetStory)?>? _data;
  String? _languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = Localizations.localeOf(context).languageCode;
    if (code != _languageCode) {
      _languageCode = code;
      _data = _load(code);
    }
  }

  Future<(ProphetIndexEntry, ProphetStory)?> _load(String languageCode) async {
    final entry = ProphetStoriesService.storyOfTheDay(await _service.loadIndex(), DateTime.now());
    if (entry == null) return null;
    final story = await _service.loadStory(entry, languageCode);
    return story == null ? null : (entry, story);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final lang = _languageCode ?? 'en';
    return FutureBuilder<(ProphetIndexEntry, ProphetStory)?>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        final (entry, story) = data;
        final name = prophetDisplayName(entry, lang, t);
        return Padding(
          padding: widget.padding,
          child: PressableTile(
            onTap: () => Get.to(() => ProphetStoryReaderScreen(entry: entry)),
            semanticLabel: '${t.storiesOfTheDay}: $name, ${story.title}',
            color: p.card,
            borderRadius: BorderRadius.circular(18.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: p.accent.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.archive_book, size: 16.sp, color: p.accent),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(t.storiesOfTheDay,
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: p.accent)),
                      ),
                      Icon(Icons.chevron_right, size: 18.sp, color: p.sub),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(name, style: _bodyStyle(lang, 16.sp, p.text, weight: FontWeight.w700)),
                  Text(story.title,
                      textDirection: _directionOf(story.language),
                      style: _bodyStyle(story.language, 13.sp, p.accent, weight: FontWeight.w600)),
                  SizedBox(height: 6.h),
                  Text(story.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textDirection: _directionOf(story.language),
                      style: _bodyStyle(story.language, 13.sp, p.sub)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProphetStoriesScreen extends StatefulWidget {
  const ProphetStoriesScreen({super.key});

  @override
  State<ProphetStoriesScreen> createState() => _ProphetStoriesScreenState();
}

class _ProphetStoriesScreenState extends State<ProphetStoriesScreen> {
  final ProphetStoriesService _service = ProphetStoriesService();
  Future<_TimelineData>? _data;
  String? _languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = Localizations.localeOf(context).languageCode;
    if (code != _languageCode) {
      _languageCode = code;
      _data = _load(code);
    }
  }

  Future<_TimelineData> _load(String languageCode) async {
    final entries = await _service.loadIndex();
    final stories = <String, ProphetStory>{};
    for (final entry in entries.where((e) => e.hasStory)) {
      final story = await _service.loadStory(entry, languageCode);
      if (story != null) stories[entry.id] = story;
    }
    return _TimelineData(entries, stories);
  }

  Future<void> _open(ProphetIndexEntry entry, {int chapter = 0, double offset = 0}) async {
    if (entry.isFinalMessenger && !entry.hasStory) {
      await Get.to(() => SeeratScreen());
    } else {
      await Get.to(() => ProphetStoryReaderScreen(entry: entry, initialChapter: chapter, initialOffset: offset));
    }
    // Progress (read chapters, last position) may have changed.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final lang = _languageCode ?? 'en';

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.storiesTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: p.text)),
        centerTitle: true,
      ),
      body: ReadableWidth(
        child: FutureBuilder<_TimelineData>(
          future: _data,
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data == null) {
              return Center(child: CircularProgressIndicator(color: p.accent));
            }
            if (data.entries.isEmpty) {
              return Center(child: Text(t.storiesLoadFailed, style: TextStyle(fontSize: 14.sp, color: p.sub)));
            }
            final last = _service.lastPosition();
            final lastEntry = last == null ? null : data.entries.where((e) => e.id == last.prophetId).firstOrNull;
            final lastStory = lastEntry == null ? null : data.stories[lastEntry.id];
            return ListView(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
              children: [
                Text(t.storiesSubtitle, style: _bodyStyle(lang, 14.sp, p.sub, weight: FontWeight.w600)),
                SizedBox(height: 12.h),
                if (last != null && lastEntry != null && lastStory != null && last.chapter < lastStory.chapters.length)
                  _continueCard(context, p, t, lang, lastEntry, lastStory, last),
                for (int i = 0; i < data.entries.length; i++) _timelineRow(context, p, t, lang, data, i),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _continueCard(BuildContext context, _Palette p, AppLocalizations t, String lang, ProphetIndexEntry entry,
      ProphetStory story, StoryPosition last) {
    final chapter = story.chapters[last.chapter];
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: PressableTile(
        onTap: () => _open(entry, chapter: last.chapter, offset: last.offset),
        semanticLabel: '${t.storiesContinue}: ${prophetDisplayName(entry, lang, t)}, ${chapter.title}',
        color: p.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Icon(Iconsax.book, color: p.accent, size: 24.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.storiesContinue,
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: p.accent)),
                    SizedBox(height: 2.h),
                    Text(prophetDisplayName(entry, lang, t),
                        style: _bodyStyle(lang, 15.sp, p.text, weight: FontWeight.w700)),
                    Text(chapter.title,
                        textDirection: _directionOf(story.language), style: _bodyStyle(story.language, 13.sp, p.sub)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p.sub),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timelineRow(BuildContext context, _Palette p, AppLocalizations t, String lang, _TimelineData data, int i) {
    final entry = data.entries[i];
    final story = data.stories[entry.id];
    final isFirst = i == 0;
    final isLast = i == data.entries.length - 1;
    final available = story != null || entry.isFinalMessenger;
    final read = story == null ? 0 : _service.readCount(story.chapters.map((c) => c.id));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The rail: a line through every Prophet, with his number on it.
          SizedBox(
            width: 34.w,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  top: isFirst ? 22.h : 0,
                  bottom: isLast ? null : 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 2,
                      height: isLast ? 22.h : double.infinity,
                      color: p.accent.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Container(
                    width: 26.w,
                    height: 26.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: available ? p.accent : p.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.accent, width: 1.5),
                    ),
                    child: Text(
                      '${entry.order}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: available ? p.card : p.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: PressableTile(
                onTap: available ? () => _open(entry) : null,
                semanticLabel: prophetDisplayName(entry, lang, t),
                color: p.card,
                borderRadius: BorderRadius.circular(16.r),
                child: Stack(
                  children: [
                    PositionedDirectional(
                      top: -14.w,
                      end: -14.w,
                      child: SizedBox(
                        width: 72.w,
                        height: 72.w,
                        child: CustomPaint(painter: _StarPainter(p.accent.withValues(alpha: 0.18))),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(14.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.arabicName} ${entry.isFinalMessenger ? 'ﷺ' : 'عليه السلام'}',
                            textDirection: TextDirection.rtl,
                            style: ScriptureText.arabic(fontSize: 22.sp, color: p.accent, fontWeight: FontWeight.w700),
                          ),
                          if (lang != 'ar')
                            Text(prophetDisplayName(entry, lang, t),
                                style: _bodyStyle(lang, 15.sp, p.text, weight: FontWeight.w700)),
                          if (story != null) ...[
                            SizedBox(height: 2.h),
                            Text(story.title,
                                textDirection: _directionOf(story.language),
                                style: _bodyStyle(story.language, 12.5.sp, p.sub)),
                            SizedBox(height: 8.h),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: story.chapters.isEmpty ? 0 : read / story.chapters.length,
                                minHeight: 5.h,
                                color: p.accent,
                                backgroundColor: p.accent.withValues(alpha: 0.15),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(t.storiesChaptersRead(read, story.chapters.length),
                                style: _bodyStyle(lang, 11.5.sp, p.sub)),
                            if (kDebugMode && !story.reviewed) ...[
                              SizedBox(height: 6.h),
                              const _ReviewTag(),
                            ],
                          ] else if (entry.isFinalMessenger) ...[
                            SizedBox(height: 6.h),
                            Row(
                              children: [
                                Icon(Iconsax.book_square, size: 16.sp, color: p.accent),
                                SizedBox(width: 6.w),
                                Flexible(
                                  child: Text(t.storiesReadSeerah,
                                      style: _bodyStyle(lang, 13.sp, p.accent, weight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ] else ...[
                            SizedBox(height: 4.h),
                            Text(t.storiesComingSoon, style: _bodyStyle(lang, 12.sp, p.sub)),
                          ],
                          if (entry.orderUncertain) ...[
                            SizedBox(height: 6.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Iconsax.info_circle, size: 14.sp, color: p.sub),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(t.storiesOrderUncertain, style: _bodyStyle(lang, 11.sp, p.sub)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reader
// ---------------------------------------------------------------------------

/// Reads one Prophet's story chapter by chapter: Quran passages (Arabic from
/// the `quran` package, translation in the app language, playable), hadith
/// with references, a Lessons card, then the next chapter or Prophet.
/// Remembers the position, marks chapters read, and supports bookmarks,
/// text size and a Kids mode.
class ProphetStoryReaderScreen extends StatefulWidget {
  final ProphetIndexEntry entry;
  final int initialChapter;
  final double initialOffset;

  const ProphetStoryReaderScreen({super.key, required this.entry, this.initialChapter = 0, this.initialOffset = 0});

  @override
  State<ProphetStoryReaderScreen> createState() => _ProphetStoryReaderScreenState();
}

class _ProphetStoryReaderScreenState extends State<ProphetStoryReaderScreen> {
  final ProphetStoriesService _service = ProphetStoriesService();
  final BookmarkService _bookmarks = BookmarkService();
  final ScrollController _scroll = ScrollController();

  Future<ProphetStory?>? _story;
  ProphetStory? _loaded;
  ProphetIndexEntry? _next;
  String? _languageCode;
  late int _chapter = widget.initialChapter;
  late double _textScale = _service.textScale;
  late bool _kidsMode = _service.kidsMode;
  bool _bookmarked = false;

  /// "surah:start-end" of the Quran passage playing / loading, if any.
  String? _playingKey;
  String? _loadingKey;
  StreamSubscription<bool>? _playingSub;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    try {
      _playingSub = QuranAudioService.handler.playingStream.listen((playing) {
        if (!playing && _playingKey != null && mounted) setState(() => _playingKey = null);
      });
    } catch (_) {
      // Audio isn't initialised (e.g. in tests); the play buttons report it.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = Localizations.localeOf(context).languageCode;
    if (code != _languageCode) {
      _languageCode = code;
      _story = _load(code);
    }
  }

  Future<ProphetStory?> _load(String languageCode) async {
    final story = await _service.loadStory(widget.entry, languageCode);
    _next = await _service.nextProphet(widget.entry);
    if (story != null) {
      _loaded = story;
      _chapter = _chapter.clamp(0, story.chapters.length - 1);
      await _refreshBookmark();
      _restoreOffset(widget.initialOffset);
    }
    return story;
  }

  @override
  void dispose() {
    _savePosition();
    _playingSub?.cancel();
    if (_playingKey != null || _loadingKey != null) {
      try {
        QuranAudioService.handler.stop();
      } catch (_) {}
    }
    _scroll.dispose();
    super.dispose();
  }

  void _restoreOffset(double offset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
    });
  }

  void _savePosition() {
    final story = _loaded;
    if (story == null) return;
    _service.savePosition(StoryPosition(
      prophetId: widget.entry.id,
      chapter: _chapter,
      offset: _scroll.hasClients ? _scroll.offset : 0,
    ));
  }

  void _onScroll() {
    final story = _loaded;
    if (story == null || !_scroll.hasClients) return;
    // Reaching the end of a chapter (the Lessons card) counts as reading it.
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 40) {
      final id = story.chapters[_chapter].id;
      if (!_service.isChapterRead(id)) _service.markChapterRead(id);
    }
  }

  Future<void> _goToChapter(int index) async {
    final story = _loaded;
    if (story == null) return;
    if (index > _chapter) await _service.markChapterRead(story.chapters[_chapter].id);
    setState(() => _chapter = index.clamp(0, story.chapters.length - 1));
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _savePosition();
    await _refreshBookmark();
  }

  Future<void> _openNextProphet() async {
    final story = _loaded;
    final next = _next;
    if (story != null) await _service.markChapterRead(story.chapters[_chapter].id);
    if (next == null) return;
    if (next.isFinalMessenger && !next.hasStory) {
      await Get.off(() => SeeratScreen());
    } else {
      await Get.off(() => ProphetStoryReaderScreen(entry: next));
    }
  }

  String get _bookmarkRef => '${widget.entry.id}|$_chapter';

  Future<void> _refreshBookmark() async {
    final marked = await _bookmarks.isBookmarked(BookmarkType.prophetStory, _bookmarkRef);
    if (mounted) setState(() => _bookmarked = marked);
  }

  Future<void> _toggleBookmark() async {
    final story = _loaded;
    if (story == null) return;
    final t = AppLocalizations.of(context)!;
    try {
      final marked = await _bookmarks.toggle(
        BookmarkType.prophetStory,
        _bookmarkRef,
        prophetDisplayName(widget.entry, _languageCode ?? 'en', t),
        story.chapters[_chapter].title,
      );
      if (mounted) setState(() => _bookmarked = marked);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.bookmarkUpdateFailed)));
    }
  }

  Future<void> _togglePlay(QuranStoryBlock block) async {
    final t = AppLocalizations.of(context)!;
    final key = '${block.surah}:${block.ayahStart}-${block.ayahEnd}';
    try {
      final handler = QuranAudioService.handler;
      if (_playingKey == key) {
        await handler.stop();
        if (mounted) setState(() => _playingKey = null);
        return;
      }
      setState(() => _loadingKey = key);
      await handler.loadAyahRange(block.surah, block.ayahStart, block.ayahEnd,
          reciterId: QuranAudioService.selectedReciterId);
      if (!mounted) return;
      setState(() {
        _loadingKey = null;
        _playingKey = key;
      });
      unawaited(handler.play());
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingKey = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.storiesAudioFailed)));
    }
  }

  void _openInQuran(QuranStoryBlock block) {
    Get.to(() => SurahScreen(
          surahName: quran.getSurahName(block.surah),
          surahId: block.surah,
          initialAyah: block.ayahStart,
        ));
  }

  void _showSettings() {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.storiesTextSize, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: p.text)),
                Row(
                  children: [
                    Text('A', style: TextStyle(fontSize: 13.sp, color: p.sub)),
                    Expanded(
                      child: Slider(
                        value: _textScale,
                        min: ProphetStoriesService.minTextScale,
                        max: ProphetStoriesService.maxTextScale,
                        divisions: 15,
                        activeColor: p.accent,
                        label: '${(_textScale * 100).round()}%',
                        onChanged: (v) {
                          setSheet(() {});
                          setState(() => _textScale = v);
                          _service.setTextScale(v);
                        },
                      ),
                    ),
                    Text('A', style: TextStyle(fontSize: 22.sp, color: p.sub)),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: p.accent,
                  secondary: Icon(Iconsax.happyemoji, color: p.accent),
                  title: Text(t.storiesKidsMode, style: TextStyle(fontSize: 15.sp, color: p.text)),
                  value: _kidsMode,
                  onChanged: (v) {
                    setSheet(() {});
                    setState(() => _kidsMode = v);
                    _service.setKidsMode(v);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChapters(ProphetStory story) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.card,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                child: Text(t.storiesChapters,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: p.text)),
              ),
              for (int i = 0; i < story.chapters.length; i++)
                ListTile(
                  selected: i == _chapter,
                  selectedTileColor: p.accent.withValues(alpha: 0.10),
                  leading:
                      Text('${i + 1}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: p.accent)),
                  title: Text(story.chapters[i].title,
                      textDirection: _directionOf(story.language), style: _bodyStyle(story.language, 14.sp, p.text)),
                  trailing: _service.isChapterRead(story.chapters[i].id)
                      ? Icon(Iconsax.tick_circle,
                          color: p.accent, size: 20.sp, semanticLabel: t.storiesChapterReadLabel)
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _goToChapter(i);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final lang = _languageCode ?? 'en';

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          prophetDisplayName(widget.entry, lang, t),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: p.text),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _bookmarked ? t.bookmarked : t.bookmark,
            icon: Icon(_bookmarked ? Iconsax.bookmark_2 : Iconsax.bookmark, color: p.accent, size: 21.sp),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            tooltip: t.storiesTextSize,
            icon: Icon(Iconsax.setting_4, color: p.text, size: 21.sp),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: ReadableWidth(
        child: FutureBuilder<ProphetStory?>(
          future: _story,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(child: CircularProgressIndicator(color: p.accent));
            }
            final story = snapshot.data;
            if (story == null || story.chapters.isEmpty) {
              return Center(child: Text(t.storiesLoadFailed, style: TextStyle(fontSize: 14.sp, color: p.sub)));
            }
            return _reader(context, p, t, lang, story);
          },
        ),
      ),
    );
  }

  Widget _reader(BuildContext context, _Palette p, AppLocalizations t, String lang, ProphetStory story) {
    final chapter = story.chapters[_chapter];
    final storyLang = story.language;
    final dir = _directionOf(storyLang);
    final paragraphs = _kidsMode && chapter.kidsParagraphs.isNotEmpty ? chapter.kidsParagraphs : chapter.paragraphs;

    Widget paragraph(String text) => Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: Text(text,
              textDirection: dir, style: _bodyStyle(storyLang, (_kidsMode ? 17 : 15.5).sp, p.text, scale: _textScale)),
        );

    final body = <Widget>[];
    if (_kidsMode) {
      // The kids telling is shorter, so its paragraphs don't line up with the
      // blocks' positions: show the story, then the Quran passages.
      body.addAll(paragraphs.map(paragraph));
      for (final block in chapter.blocks.whereType<QuranStoryBlock>()) {
        body.add(_block(context, p, t, lang, story, block));
      }
    } else {
      for (int i = 0; i < paragraphs.length; i++) {
        body.add(paragraph(paragraphs[i]));
        for (final block in chapter.blocksAfter(i)) {
          body.add(_block(context, p, t, lang, story, block));
        }
      }
    }

    return Column(
      children: [
        // Chapter progress, which also opens the chapter list.
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => _showChapters(story),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.menu_1, size: 16.sp, color: p.accent),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(t.storiesChapterOf(_chapter + 1, story.chapters.length),
                            style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: p.accent)),
                      ),
                      Text(t.storiesChapters, style: TextStyle(fontSize: 12.sp, color: p.sub)),
                      Icon(Icons.expand_more, size: 18.sp, color: p.sub),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: (_chapter + 1) / story.chapters.length,
                      minHeight: 4.h,
                      color: p.accent,
                      backgroundColor: p.accent.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
            children: [
              if (_chapter == 0) _header(context, p, t, lang, story),
              if (story.language != lang) _englishOnlyBanner(p, t, lang),
              Text(chapter.title,
                  textDirection: dir,
                  style: _bodyStyle(storyLang, 21.sp, p.text, weight: FontWeight.w700, scale: _textScale)),
              SizedBox(height: 12.h),
              ...body,
              SizedBox(height: 6.h),
              _lessonsCard(p, t, lang, story, chapter),
              SizedBox(height: 18.h),
              _navigation(p, t, lang, story),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, _Palette p, AppLocalizations t, String lang, ProphetStory story) {
    final entry = widget.entry;
    final storyLang = story.language;
    final dir = _directionOf(storyLang);

    Widget fact(IconData icon, String label, String value) => Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16.sp, color: Colors.white70),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: _bodyStyle(lang, 11.sp, Colors.white70, weight: FontWeight.w700)),
                    Text(value, textDirection: dir, style: _bodyStyle(storyLang, 13.sp, Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        );

    final places =
        story.places.map((pl) => pl.approximate ? '${pl.name} (${t.storiesApproximate})' : pl.name).join('\n');

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [VoidColors.cardDark, VoidColors.oliveDeep]
                    : [VoidColors.oliveDeep, VoidColors.oliveDeepLight],
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${entry.arabicName} ${entry.isFinalMessenger ? 'ﷺ' : 'عليه السلام'}',
                        textDirection: TextDirection.rtl,
                        style: ScriptureText.arabic(
                            fontSize: 30.sp, color: VoidColors.goldDark, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (kDebugMode && !story.reviewed) const _ReviewTag(),
                  ],
                ),
                if (lang != 'ar')
                  Text(prophetDisplayName(entry, lang, t),
                      style: _bodyStyle(lang, 17.sp, Colors.white, weight: FontWeight.w700)),
                Text(story.title, textDirection: dir, style: _bodyStyle(storyLang, 13.sp, VoidColors.goldDark)),
                SizedBox(height: 10.h),
                Text(story.summary, textDirection: dir, style: _bodyStyle(storyLang, 13.5.sp, Colors.white)),
                fact(Iconsax.people, t.storiesSentTo, story.sentTo),
                fact(Iconsax.clock, t.storiesEra, story.era),
                if (places.isNotEmpty) fact(Iconsax.location, t.storiesPlaces, places),
                if (entry.timesNamed != null)
                  Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Text(t.storiesNamedInQuran(entry.timesNamed!),
                        style: _bodyStyle(lang, 12.sp, VoidColors.goldDark, weight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          if (story.notes.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 12.h),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16.r)),
              child: Material(
                type: MaterialType.transparency,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Icon(Iconsax.teacher, color: p.accent, size: 20.sp),
                    iconColor: p.accent,
                    collapsedIconColor: p.accent,
                    title:
                        Text(t.storiesScholarsDiffer, style: _bodyStyle(lang, 14.sp, p.text, weight: FontWeight.w700)),
                    childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final note in story.notes)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Text('• $note', textDirection: dir, style: _bodyStyle(storyLang, 13.sp, p.text)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _englishOnlyBanner(_Palette p, AppLocalizations t, String lang) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Iconsax.language_square, size: 18.sp, color: p.accent),
          SizedBox(width: 8.w),
          Expanded(child: Text(t.storiesEnglishOnly, style: _bodyStyle(lang, 12.5.sp, p.text))),
        ],
      ),
    );
  }

  Widget _block(
      BuildContext context, _Palette p, AppLocalizations t, String lang, ProphetStory story, StoryBlock block) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: switch (block) {
        QuranStoryBlock() => _quranBlock(p, t, lang, block),
        HadithStoryBlock() => _hadithBlock(p, t, lang, story, block),
        NarrationNoteBlock() => _narrationNote(p, t, lang, story, block),
      },
    );
  }

  Widget _quranBlock(_Palette p, AppLocalizations t, String lang, QuranStoryBlock block) {
    final ayat = [for (int a = block.ayahStart; a <= block.ayahEnd; a++) a];
    final arabic = ayat.map((a) => quran.getVerse(block.surah, a, verseEndSymbol: true)).join(' ');
    final translation = _quranTranslation(lang);
    final translated = translation == null
        ? null
        : ayat.map((a) => quran.getVerseTranslation(block.surah, a, translation: translation)).join(' ');
    // Hindi and German fall back to the English translation.
    final translationLang = translation == quran.Translation.enSaheeh ? 'en' : lang;
    final range = block.ayahStart == block.ayahEnd ? '${block.ayahStart}' : '${block.ayahStart}-${block.ayahEnd}';
    final surahName = lang == 'ar' ? quran.getSurahNameArabic(block.surah) : quran.getSurahName(block.surah);
    final key = '${block.surah}:${block.ayahStart}-${block.ayahEnd}';
    final playing = _playingKey == key;
    final loading = _loadingKey == key;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 6.h),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: p.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Iconsax.book_1, size: 16.sp, color: p.accent),
              SizedBox(width: 6.w),
              Expanded(
                child: Text('$surahName ${block.surah}:$range',
                    style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: p.accent)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: ScriptureText.arabic(fontSize: 21.sp * _textScale, color: p.text),
          ),
          if (translated != null) ...[
            SizedBox(height: 8.h),
            Text(translated,
                textDirection: _directionOf(translationLang),
                style: _bodyStyle(translationLang, 13.5.sp, p.sub, scale: _textScale)),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: loading ? null : () => _togglePlay(block),
                icon: loading
                    ? SizedBox(
                        width: 16.sp, height: 16.sp, child: CircularProgressIndicator(strokeWidth: 2, color: p.accent))
                    : Icon(playing ? Iconsax.stop_circle : Iconsax.play_circle, color: p.accent, size: 20.sp),
                label: Text(playing ? t.storiesStop : t.storiesPlay,
                    style: TextStyle(fontSize: 12.5.sp, color: p.accent, fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: () => _openInQuran(block),
                icon: Icon(Iconsax.export_3, color: p.accent, size: 18.sp),
                label: Text(t.storiesOpenInQuran,
                    style: TextStyle(fontSize: 12.5.sp, color: p.accent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hadithBlock(_Palette p, AppLocalizations t, String lang, ProphetStory story, HadithStoryBlock block) {
    final dir = _directionOf(story.language);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: BorderDirectional(start: BorderSide(color: p.accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.quote_down, size: 16.sp, color: p.accent),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(t.storiesNarratedBy(block.narrator),
                    textDirection: dir, style: _bodyStyle(story.language, 12.sp, p.accent, weight: FontWeight.w700)),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(block.translation,
              textDirection: dir, style: _bodyStyle(story.language, 14.sp, p.text, scale: _textScale)),
          SizedBox(height: 8.h),
          Text('${block.collection == 'muslim' ? t.storiesMuslim : t.storiesBukhari} ${block.number}',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: p.accent)),
          if (block.shortened) Text(t.storiesShortened, style: _bodyStyle(lang, 11.sp, p.sub)),
        ],
      ),
    );
  }

  Widget _narrationNote(_Palette p, AppLocalizations t, String lang, ProphetStory story, NarrationNoteBlock block) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: VoidColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: VoidColors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Iconsax.warning_2, size: 18.sp, color: VoidColors.warning),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(block.text,
                    textDirection: _directionOf(story.language),
                    style: _bodyStyle(story.language, 13.sp, p.text, scale: _textScale)),
                SizedBox(height: 4.h),
                Text(t.storiesNarrationNote, style: _bodyStyle(lang, 12.sp, p.sub, weight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonsCard(_Palette p, AppLocalizations t, String lang, ProphetStory story, StoryChapter chapter) {
    if (chapter.lessons.isEmpty) return const SizedBox.shrink();
    final dir = _directionOf(story.language);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.lamp_on, size: 20.sp, color: p.accent),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(t.storiesLessons, style: _bodyStyle(lang, 16.sp, p.text, weight: FontWeight.w700)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          for (final lesson in chapter.lessons)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 3.h),
                    child: Icon(Iconsax.tick_circle, size: 16.sp, color: p.accent),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(lesson,
                        textDirection: dir, style: _bodyStyle(story.language, 14.sp, p.text, scale: _textScale)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _navigation(_Palette p, AppLocalizations t, String lang, ProphetStory story) {
    final isLast = _chapter == story.chapters.length - 1;
    final next = _next;
    final nextAvailable = next != null && (next.hasStory || next.isFinalMessenger);
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: p.accent,
      foregroundColor: p.card,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
    );

    // The Prophet Muhammad's story is a short overview; his full life is
    // in the Seerah section.
    final seerahLink = isLast && widget.entry.isFinalMessenger;

    return Row(
      children: [
        if (_chapter > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _goToChapter(_chapter - 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.accent,
                side: BorderSide(color: p.accent),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              icon: const Icon(Icons.chevron_left),
              label: Text(t.storiesPreviousChapter, maxLines: 2, textAlign: TextAlign.center),
            ),
          ),
        if (_chapter > 0) SizedBox(width: 10.w),
        Expanded(
          child: seerahLink
              ? FilledButton.icon(
                  onPressed: () => Get.to(() => SeeratScreen()),
                  style: buttonStyle,
                  icon: const Icon(Iconsax.book_square),
                  label: Text(t.storiesReadSeerah, maxLines: 2, textAlign: TextAlign.center),
                )
              : !isLast
                  ? FilledButton.icon(
                      onPressed: () => _goToChapter(_chapter + 1),
                      style: buttonStyle,
                      icon: const Icon(Icons.chevron_right),
                      label: Text(t.storiesNextChapter, maxLines: 2, textAlign: TextAlign.center),
                    )
                  : next == null
                      ? const SizedBox.shrink()
                      : FilledButton(
                          onPressed: nextAvailable ? _openNextProphet : null,
                          style: buttonStyle,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(t.storiesNextProphet, style: TextStyle(fontSize: 12.sp)),
                              Text(
                                nextAvailable
                                    ? prophetDisplayName(next, lang, t)
                                    : '${prophetDisplayName(next, lang, t)} · ${t.storiesComingSoon}',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }
}
