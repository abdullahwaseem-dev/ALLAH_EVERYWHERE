import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/controllers/prayer_times_controller.dart';
import 'package:allah_everywhere/data/adhkar_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/services/adhkar_service.dart';
import 'package:allah_everywhere/share_cards/share_content.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

/// Morning (after Fajr) and evening (after Asr) adhkar from Hisn al-Muslim:
/// one dhikr per page with a tap-to-count button. Opens on the set that fits
/// the current time, per today's prayer times.
class AdhkarScreen extends StatefulWidget {
  /// Set to open on (e.g. from a reminder); chosen by the time of day if null.
  final AdhkarTime? initialTime;

  const AdhkarScreen({super.key, this.initialTime});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: _initialTime().index);
  }

  AdhkarTime _initialTime() {
    final given = widget.initialTime;
    if (given != null) return given;
    DateTime? fajr;
    DateTime? asr;
    if (Get.isRegistered<PrayerTimesController>()) {
      final times = Get.find<PrayerTimesController>().prayerDateTimes.value;
      fajr = times['Fajr'];
      asr = times['Asr'];
    }
    return AdhkarService.suggestedTime(DateTime.now(), fajr: fajr, asr: asr);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;

    Widget tab(String label, String hint) => Tab(
          height: MediaQuery.textScalerOf(context).scale(48.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
              Text(hint, style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w400)),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.adhkarTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: textColor)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: accent,
          unselectedLabelColor: subColor,
          indicatorColor: accent,
          dividerColor: Colors.transparent,
          tabs: [
            tab(t.adhkarMorning, t.adhkarMorningHint),
            tab(t.adhkarEvening, t.adhkarEveningHint),
          ],
        ),
      ),
      body: ReadableWidth(
        child: TabBarView(
          controller: _tabs,
          children: const [
            _AdhkarSession(time: AdhkarTime.morning),
            _AdhkarSession(time: AdhkarTime.evening),
          ],
        ),
      ),
    );
  }
}

class _AdhkarSession extends StatefulWidget {
  final AdhkarTime time;

  const _AdhkarSession({required this.time});

  @override
  State<_AdhkarSession> createState() => _AdhkarSessionState();
}

class _AdhkarSessionState extends State<_AdhkarSession> with AutomaticKeepAliveClientMixin {
  final AdhkarService _service = AdhkarService();
  late final List<Dhikr> _adhkar = adhkarFor(widget.time);
  late AdhkarProgress _progress;
  late PageController _pages;
  late int _page;
  late bool _finished;

  /// Repetitions not yet added to the Tasbeeh totals; flushed per dhikr.
  int _unsynced = 0;
  Timer? _advance;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _progress = _service.progress(widget.time);
    final first = _progress.firstIncomplete(_adhkar);
    _finished = first >= _adhkar.length;
    _page = _finished ? 0 : first;
    _pages = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _advance?.cancel();
    _flush();
    _pages.dispose();
    super.dispose();
  }

  void _flush() {
    if (_unsynced > 0) {
      _service.addToTasbeehTotals(_unsynced);
      _unsynced = 0;
    }
  }

  void _count() {
    final dhikr = _adhkar[_page];
    if (_progress.isComplete(dhikr)) {
      _goToNext();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _progress = _progress.withCount(dhikr, _progress.doneOf(dhikr) + 1));
    _service.saveProgress(widget.time, _progress);
    _unsynced++;
    if (!_progress.isComplete(dhikr)) return;

    HapticFeedback.mediumImpact();
    _flush();
    if (_progress.firstIncomplete(_adhkar) >= _adhkar.length) {
      _service.markCompletedToday(widget.time);
      _advance = Timer(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _finished = true);
      });
    } else {
      _advance = Timer(const Duration(milliseconds: 450), _goToNext);
    }
  }

  /// The next unfinished dhikr after this one (wrapping to earlier ones the
  /// user skipped past).
  void _goToNext() {
    if (!mounted) return;
    var next = -1;
    for (int i = 1; i <= _adhkar.length; i++) {
      final j = (_page + i) % _adhkar.length;
      if (!_progress.isComplete(_adhkar[j])) {
        next = j;
        break;
      }
    }
    if (next == -1) return;
    _pages.animateToPage(next, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  void _startOver() {
    _advance?.cancel();
    final fresh = AdhkarProgress(date: AdhkarService.dateKey(DateTime.now()));
    _service.saveProgress(widget.time, fresh);
    setState(() {
      _progress = fresh;
      _finished = false;
      _page = 0;
      _pages.dispose();
      _pages = PageController();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    if (_finished) return _completion(t, accent, textColor, subColor);

    final completed = _progress.completedCount(_adhkar);
    final dhikr = _adhkar[_page];
    final remaining = _progress.remainingOf(dhikr);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 8.w, 0),
          child: Row(
            children: [
              Text(
                t.adhkarProgress('${_page + 1}', '${_adhkar.length}'),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: textColor),
              ),
              const Spacer(),
              if (_service.isCompletedToday(widget.time))
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 4.w),
                  child: Row(
                    children: [
                      Icon(Iconsax.tick_circle, size: 14.sp, color: accent),
                      SizedBox(width: 4.w),
                      Text(t.adhkarCompletedToday, style: TextStyle(fontSize: 11.5.sp, color: accent)),
                    ],
                  ),
                ),
              IconButton(
                tooltip: t.adhkarSource,
                icon: Icon(Iconsax.info_circle, size: 18.sp, color: subColor),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text(t.adhkarSourceNote),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(t.adhkarDone)),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: t.adhkarStartOver,
                icon: Icon(Iconsax.refresh, size: 18.sp, color: subColor),
                onPressed: completed == 0 ? null : _startOver,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: completed / _adhkar.length,
              minHeight: 6.h,
              color: accent,
              backgroundColor: textColor.withValues(alpha: 0.1),
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: _adhkar.length,
            onPageChanged: (i) {
              _advance?.cancel();
              setState(() => _page = i);
            },
            itemBuilder: (context, i) => _DhikrPage(
              dhikr: _adhkar[i],
              accent: accent,
              textColor: textColor,
              subColor: subColor,
              cardColor: cardColor,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 6.h, bottom: navBarClearance(context) + 6.h),
          child: _CountButton(
            remaining: remaining,
            repeat: dhikr.repeat,
            accent: accent,
            textColor: textColor,
            onTap: _count,
          ),
        ),
      ],
    );
  }

  Widget _completion(AppLocalizations t, Color accent, Color textColor, Color subColor) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(Iconsax.tick_circle, size: 56.sp, color: accent),
            ),
            SizedBox(height: 18.h),
            Text(
              widget.time == AdhkarTime.morning ? t.adhkarMorningCompleted : t.adhkarEveningCompleted,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: textColor),
            ),
            SizedBox(height: 8.h),
            Text(
              t.adhkarCompletedBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, height: 1.5, color: subColor),
            ),
            SizedBox(height: 24.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _startOver,
                  icon: Icon(Iconsax.refresh, color: accent, size: 18.sp),
                  label: Text(t.adhkarStartOver, style: TextStyle(color: accent)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: accent)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
                  child: Text(t.adhkarDone),
                ),
              ],
            ),
            SizedBox(height: navBarClearance(context)),
          ],
        ),
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  final int remaining;
  final int repeat;
  final Color accent;
  final Color textColor;
  final VoidCallback onTap;

  const _CountButton({
    required this.remaining,
    required this.repeat,
    required this.accent,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final done = remaining == 0;
    final size = 112.r;
    return Semantics(
      button: true,
      label: done ? t.adhkarDone : '${t.adhkarRemaining('$remaining')}, ${t.adhkarTapToCount}',
      excludeSemantics: true,
      child: Material(
        color: done ? accent.withValues(alpha: 0.15) : accent,
        shape: const CircleBorder(),
        elevation: done ? 0 : 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Padding(
              padding: EdgeInsets.all(10.r),
              child: FittedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: done
                      ? [Icon(Iconsax.tick_circle, size: 40, color: accent)]
                      : [
                          Text(
                            '$remaining',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          Text(
                            repeat > 1 ? '/ $repeat' : t.adhkarTapToCount,
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DhikrPage extends StatelessWidget {
  final Dhikr dhikr;
  final Color accent;
  final Color textColor;
  final Color subColor;
  final Color cardColor;

  const _DhikrPage({
    required this.dhikr,
    required this.accent,
    required this.textColor,
    required this.subColor,
    required this.cardColor,
  });

  /// Arabic and translation; Quran passages come from the `quran` package.
  ({String arabic, String? translation, bool translationIsUrdu}) _texts(String languageCode) {
    if (!dhikr.isQuran) {
      return (
        arabic: dhikr.arabic,
        translation: dhikrTranslation(dhikr, languageCode),
        translationIsUrdu: languageCode == 'ur',
      );
    }
    final passages = dhikr.quran.map((ref) => ShareContent.fromQuran(ref, languageCode)).toList();
    final arabic = [
      if (dhikr.quranPrefix.isNotEmpty) dhikr.quranPrefix,
      for (final p in passages) dhikr.basmalaBeforeEach ? '${quran.basmala}\n${p.arabic}' : p.arabic,
    ].join('\n\n');
    final translations = passages.map((p) => p.translation).where((s) => s.isNotEmpty).toList();
    return (
      arabic: arabic,
      translation: translations.isEmpty ? null : translations.join('\n\n'),
      translationIsUrdu: passages.first.translationIsUrdu,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final texts = _texts(languageCode);
    final virtue = dhikrVirtue(dhikr, languageCode);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      t.adhkarRecite('${dhikr.repeat}'),
                      style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: accent),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  texts.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: ScriptureText.arabic(fontSize: 21.sp, color: textColor),
                ),
                if (dhikr.transliteration.isNotEmpty && languageCode != 'ar') ...[
                  SizedBox(height: 10.h),
                  Text(
                    dhikr.transliteration,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 13.sp, height: 1.5, fontStyle: FontStyle.italic, color: subColor),
                  ),
                ],
                if (texts.translation != null) ...[
                  SizedBox(height: 10.h),
                  Text(
                    texts.translation!,
                    textAlign: TextAlign.center,
                    style: texts.translationIsUrdu
                        ? ScriptureText.urdu(fontSize: 14.sp, color: textColor)
                        : TextStyle(fontSize: 14.sp, height: 1.5, color: textColor),
                  ),
                ],
              ],
            ),
          ),
          if (virtue != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.star_1, size: 15.sp, color: accent),
                      SizedBox(width: 6.w),
                      Text(t.adhkarVirtue,
                          style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: accent)),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    virtue,
                    style: languageCode == 'ur'
                        ? ScriptureText.urdu(fontSize: 13.sp, color: textColor)
                        : languageCode == 'ar'
                            ? ScriptureText.arabic(fontSize: 15.sp, color: textColor)
                            : TextStyle(fontSize: 13.sp, height: 1.5, color: textColor),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Iconsax.book_1, size: 14.sp, color: subColor),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  '${t.adhkarSource}: Hisn al-Muslim · ${dhikr.reference}',
                  style: TextStyle(fontSize: 11.5.sp, height: 1.45, color: subColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
