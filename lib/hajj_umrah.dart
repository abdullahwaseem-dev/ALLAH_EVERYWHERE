import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:allah_everywhere/data/hajj_umrah_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/services/hajj_service.dart';
import 'package:allah_everywhere/share_cards/share_content.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

/// Theme colours shared by the Hajj & Umrah screens.
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

/// Body text in the app language (Urdu/Arabic in their script fonts).
TextStyle _bodyStyle(String languageCode, double size, Color color, {FontWeight? weight}) {
  if (languageCode == 'ur') return ScriptureText.urdu(fontSize: size, color: color, fontWeight: weight);
  if (languageCode == 'ar') return ScriptureText.arabic(fontSize: size + 1.5.sp, color: color, fontWeight: weight);
  return TextStyle(fontSize: size, height: 1.5, color: color, fontWeight: weight);
}

/// Offline Hajj & Umrah guide: step-by-step checklists for Umrah and for
/// Hajj (8th-13th Dhul Hijjah), a Tawaf/Sa'i round counter, an editable
/// packing list, and the main places with an "Open in Maps" link.
class HajjUmrahScreen extends StatefulWidget {
  const HajjUmrahScreen({super.key});

  @override
  State<HajjUmrahScreen> createState() => _HajjUmrahScreenState();
}

class _HajjUmrahScreenState extends State<HajjUmrahScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final HajjService _service = HajjService();

  /// Bumped on reset so the tabs reload their saved state.
  int _generation = 0;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _confirmReset() async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.hajjResetTitle),
        content: Text(t.hajjResetMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.reset)),
        ],
      ),
    );
    if (ok != true) return;
    await _service.resetTrip();
    if (mounted) setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.hajjTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: p.text)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: t.reset,
            icon: Icon(Iconsax.refresh, color: p.text, size: 20.sp),
            onPressed: _confirmReset,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: p.accent,
          unselectedLabelColor: p.sub,
          indicatorColor: p.accent,
          dividerColor: Colors.transparent,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: t.hajjTabUmrah),
            Tab(text: t.hajjTabHajj),
            Tab(text: t.hajjTabPacking),
            Tab(text: t.hajjTabPlaces),
          ],
        ),
      ),
      body: ReadableWidth(
        child: Column(
          children: [
            // The scholar note stays on top of every tab.
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: p.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: p.accent.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.teacher, size: 18.sp, color: p.accent),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(t.hajjScholarNote,
                        style: _bodyStyle(languageCode, 13.sp, p.text, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                key: ValueKey(_generation),
                controller: _tabs,
                children: [
                  _GuideTab(guide: HajjGuide.umrah, service: _service),
                  _GuideTab(guide: HajjGuide.hajj, service: _service),
                  _PackingTab(service: _service),
                  const _PlacesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Umrah / Hajj checklist
// ---------------------------------------------------------------------------

class _GuideTab extends StatefulWidget {
  final HajjGuide guide;
  final HajjService service;

  const _GuideTab({required this.guide, required this.service});

  @override
  State<_GuideTab> createState() => _GuideTabState();
}

class _GuideTabState extends State<_GuideTab> with AutomaticKeepAliveClientMixin {
  late final List<HajjStep> _steps = hajjStepsFor(widget.guide);
  late Set<String> _done = widget.service.doneSteps();

  @override
  bool get wantKeepAlive => true;

  Future<void> _toggle(HajjStep step, bool done) async {
    HapticFeedback.selectionClick();
    setState(() => done ? _done.add(step.id) : _done.remove(step.id));
    await widget.service.setStepDone(step.id, done);
    if (mounted) setState(() => _done = widget.service.doneSteps());
  }

  String _dayLabel(AppLocalizations t, String day) => switch (day) {
        '8' => t.hajjDay8,
        '9' => t.hajjDay9,
        '10' => t.hajjDay10,
        '11-13' => t.hajjDay11to13,
        _ => t.hajjDayDepart,
      };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final done = _steps.where((s) => _done.contains(s.id)).length;

    final children = <Widget>[
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.hajjProgress(done, _steps.length),
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: p.text)),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: _steps.isEmpty ? 0 : done / _steps.length,
                    minHeight: 6.h,
                    color: p.accent,
                    backgroundColor: p.accent.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          FilledButton.tonalIcon(
            onPressed: () => Get.to(() => const HajjRoundCounterScreen()),
            icon: Icon(Iconsax.repeat, size: 16.sp),
            label: Text(t.hajjCounterOpen),
            style: FilledButton.styleFrom(
              backgroundColor: p.accent.withValues(alpha: 0.16),
              foregroundColor: p.text,
              textStyle: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      SizedBox(height: 8.h),
      Text(t.hajjRulingHelp, style: _bodyStyle(languageCode, 11.5.sp, p.sub)),
      SizedBox(height: 6.h),
    ];

    String? lastDay;
    for (final step in _steps) {
      if (step.day != null && step.day != lastDay) {
        lastDay = step.day;
        children.add(Padding(
          padding: EdgeInsets.only(top: 12.h, bottom: 2.h),
          child: Row(
            children: [
              Icon(Iconsax.calendar_1, size: 15.sp, color: p.accent),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(_dayLabel(t, step.day!),
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: p.accent)),
              ),
            ],
          ),
        ));
      }
      children.add(Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: _StepCard(
          step: step,
          done: _done.contains(step.id),
          onDone: (v) => _toggle(step, v),
        ),
      ));
    }

    return ListView(
      key: PageStorageKey('hajj_guide_${widget.guide.name}'),
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h + MediaQuery.paddingOf(context).bottom),
      children: children,
    );
  }
}

class _RulingChip extends StatelessWidget {
  final HajjRuling ruling;

  const _RulingChip(this.ruling);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final label = switch (ruling) {
      HajjRuling.rukn => t.hajjRulingRukn,
      HajjRuling.wajib => t.hajjRulingWajib,
      HajjRuling.sunnah => t.hajjRulingSunnah,
    };
    // Strongest ruling gets the strongest fill.
    final alpha = switch (ruling) { HajjRuling.rukn => 0.9, HajjRuling.wajib => 0.35, HajjRuling.sunnah => 0.12 };
    final onFill = ruling == HajjRuling.rukn ? p.card : p.text;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: onFill)),
    );
  }
}

class _StepCard extends StatelessWidget {
  final HajjStep step;
  final bool done;
  final ValueChanged<bool> onDone;

  const _StepCard({required this.step, required this.done, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final lang = Localizations.localeOf(context).languageCode;
    String text(String part) => hajjText('${step.id}.$part', lang);

    Widget section(IconData icon, String title, Widget body) => Padding(
          padding: EdgeInsets.only(top: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15.sp, color: p.accent),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(title,
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: p.accent)),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              body,
            ],
          ),
        );

    Widget bullets(String lines) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines.split('\n').where((l) => l.trim().isNotEmpty))
              Padding(
                padding: EdgeInsets.only(bottom: 5.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 7.h),
                      child: Container(
                        width: 5.w,
                        height: 5.w,
                        decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(child: Text(line, style: _bodyStyle(lang, 13.5.sp, p.text))),
                  ],
                ),
              ),
          ],
        );

    return Material(
      color: p.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: done ? p.accent.withValues(alpha: 0.7) : p.accent.withValues(alpha: 0.25)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('hajj_${step.id}'),
          tilePadding: EdgeInsetsDirectional.only(start: 4.w, end: 12.w),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          iconColor: p.accent,
          collapsedIconColor: p.sub,
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Checkbox(
            value: done,
            activeColor: p.accent,
            checkColor: p.card,
            side: BorderSide(color: p.sub, width: 1.5),
            onChanged: (v) => onDone(v ?? false),
            semanticLabel: t.hajjMarkDone,
          ),
          title: Text(
            text('title'),
            style: _bodyStyle(lang, 15.sp, p.text, weight: FontWeight.w700).copyWith(
              decoration: done ? TextDecoration.lineThrough : null,
              decorationColor: p.sub,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Align(alignment: AlignmentDirectional.centerStart, child: _RulingChip(step.ruling)),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            section(Iconsax.task_square, t.hajjWhatToDo, bullets(text('what'))),
            if (step.showsRestrictions)
              section(Iconsax.forbidden_2, t.hajjRestrictions, bullets(hajjText('ihram.restrictions', lang))),
            if (step.duaIds.isNotEmpty)
              section(Iconsax.book_1, t.hajjDuas, Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final id in step.duaIds)
                    if (hajjDuas[id] != null) _DuaCard(dua: hajjDuas[id]!),
                ],
              )),
            section(Iconsax.danger, t.hajjMistakes, bullets(text('mistakes'))),
            if (hajjHasText('${step.id}.note'))
              section(Iconsax.people, t.hajjMadhabNote, Text(text('note'), style: _bodyStyle(lang, 13.sp, p.text))),
            section(Iconsax.document_text, t.hajjSources,
                Text(step.sources, style: TextStyle(fontSize: 11.5.sp, height: 1.45, color: p.sub))),
          ],
        ),
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final HajjDua dua;

  const _DuaCard({required this.dua});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final lang = Localizations.localeOf(context).languageCode;

    // Quran passages (Arabic and translation) come from the `quran` package.
    final quranText = dua.quran == null ? null : ShareContent.fromQuran(dua.quran!, lang);
    final arabic = quranText?.arabic ?? dua.arabic;
    final translation = quranText != null
        ? quranText.translation
        : lang == 'en'
            ? dua.translation
            : hajjText('dua.${dua.id}', lang);
    final translationIsUrdu = quranText?.translationIsUrdu ?? lang == 'ur';
    final appTranslation = quranText == null && (lang != 'en' || dua.appTranslation);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: ScriptureText.arabic(fontSize: 20.sp, color: p.text),
          ),
          if (lang != 'ar') ...[
            SizedBox(height: 8.h),
            Text(
              dua.transliteration,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 12.5.sp, height: 1.5, fontStyle: FontStyle.italic, color: p.sub),
            ),
          ],
          if (translation.isNotEmpty && lang != 'ar') ...[
            SizedBox(height: 8.h),
            Text(
              translation,
              textAlign: TextAlign.center,
              style: translationIsUrdu
                  ? ScriptureText.urdu(fontSize: 13.5.sp, color: p.text)
                  : TextStyle(fontSize: 13.5.sp, height: 1.5, color: p.text),
            ),
          ],
          SizedBox(height: 8.h),
          Text(
            [
              '${t.hajjSources}: ${dua.source}',
              if (dua.appTransliteration && lang != 'ar') t.hajjAppTransliteration,
              if (appTranslation && lang != 'ar') t.hajjAppTranslation,
            ].join(' · '),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.sp, height: 1.45, color: p.sub),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tawaf / Sa'i round counter
// ---------------------------------------------------------------------------

/// A big tap-anywhere counter for the 7 rounds of Tawaf or Sa'i, with
/// haptics on every round. The count is saved, so it survives the app being
/// closed mid-Tawaf.
class HajjRoundCounterScreen extends StatefulWidget {
  const HajjRoundCounterScreen({super.key});

  @override
  State<HajjRoundCounterScreen> createState() => _HajjRoundCounterScreenState();
}

class _HajjRoundCounterScreenState extends State<HajjRoundCounterScreen> {
  final HajjService _service = HajjService();
  HajjCounter _which = HajjCounter.tawaf;
  late int _count = _service.counter(_which);

  bool get _complete => _count >= HajjService.rounds;

  void _set(int value) {
    setState(() => _count = value.clamp(0, HajjService.rounds));
    _service.setCounter(_which, _count);
  }

  void _tap() {
    if (_complete) {
      HapticFeedback.heavyImpact();
      return;
    }
    _set(_count + 1);
    _complete ? HapticFeedback.heavyImpact() : HapticFeedback.mediumImpact();
  }

  void _switch(HajjCounter which) => setState(() {
        _which = which;
        _count = _service.counter(which);
      });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.hajjCounterOpen, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: p.text)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ReadableWidth(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<HajjCounter>(
                  segments: [
                    ButtonSegment(value: HajjCounter.tawaf, label: Text(t.hajjCounterTawaf)),
                    ButtonSegment(value: HajjCounter.sai, label: Text(t.hajjCounterSai)),
                  ],
                  selected: {_which},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => _switch(s.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: p.accent.withValues(alpha: 0.2),
                    selectedForegroundColor: p.text,
                    foregroundColor: p.sub,
                    side: BorderSide(color: p.accent.withValues(alpha: 0.4)),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  _which == HajjCounter.tawaf ? t.hajjCounterTawafHint : t.hajjCounterSaiHint,
                  textAlign: TextAlign.center,
                  style: _bodyStyle(lang, 12.5.sp, p.sub),
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: '${t.hajjCounterTapHint}. $_count ${t.hajjCounterOf}',
                    child: Material(
                      color: p.card,
                      borderRadius: BorderRadius.circular(28.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28.r),
                        onTap: _tap,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28.r),
                            border: Border.all(color: p.accent.withValues(alpha: _complete ? 0.9 : 0.3), width: 2),
                          ),
                          padding: EdgeInsets.all(16.w),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$_count',
                                    style: TextStyle(
                                        fontSize: 120.sp, fontWeight: FontWeight.w800, color: p.accent, height: 1.1)),
                                Text(t.hajjCounterOf,
                                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: p.text)),
                                SizedBox(height: 18.h),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (var i = 0; i < HajjService.rounds; i++)
                                      Container(
                                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                                        width: 14.w,
                                        height: 14.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: i < _count ? p.accent : p.accent.withValues(alpha: 0.15),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 18.h),
                                Text(
                                  _complete ? t.hajjCounterComplete : t.hajjCounterTapHint,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: _complete ? FontWeight.w800 : FontWeight.w500,
                                    color: _complete ? p.accent : p.sub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _count == 0 ? null : () => _set(_count - 1),
                        icon: Icon(Iconsax.undo, size: 16.sp),
                        label: Text(t.hajjCounterUndo),
                        style: OutlinedButton.styleFrom(foregroundColor: p.text),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _count == 0 ? null : () => _set(0),
                        icon: Icon(Iconsax.refresh, size: 16.sp),
                        label: Text(t.reset),
                        style: OutlinedButton.styleFrom(foregroundColor: p.text),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Packing list
// ---------------------------------------------------------------------------

class _PackingTab extends StatefulWidget {
  final HajjService service;

  const _PackingTab({required this.service});

  @override
  State<_PackingTab> createState() => _PackingTabState();
}

class _PackingTabState extends State<_PackingTab> with AutomaticKeepAliveClientMixin {
  late List<PackingItem> _items = widget.service.packing();
  final TextEditingController _input = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _apply(Future<List<PackingItem>> change) async {
    final items = await change;
    if (mounted) setState(() => _items = items);
  }

  void _add() {
    if (_input.text.trim().isEmpty) return;
    _apply(widget.service.addItem(_input.text));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final lang = Localizations.localeOf(context).languageCode;
    final packed = _items.where((i) => i.packed).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
            children: [
              Text(t.hajjPacked(packed, _items.length),
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: p.text)),
              SizedBox(height: 8.h),
              if (_items.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Text(t.hajjPackingEmpty, textAlign: TextAlign.center, style: TextStyle(color: p.sub)),
                ),
              for (final item in _items)
                Padding(
                  key: ValueKey(item.id),
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: CheckboxListTile(
                    tileColor: p.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    value: item.packed,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      _apply(widget.service.setPacked(item.id, v ?? false));
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: p.accent,
                    checkColor: p.card,
                    side: BorderSide(color: p.sub, width: 1.5),
                    contentPadding: EdgeInsetsDirectional.only(start: 4.w),
                    title: Text(
                      item.label(lang),
                      style: (item.isCustom
                              ? TextStyle(fontSize: 14.sp, height: 1.4, color: p.text)
                              : _bodyStyle(lang, 14.sp, p.text))
                          .copyWith(
                        decoration: item.packed ? TextDecoration.lineThrough : null,
                        decorationColor: p.sub,
                      ),
                    ),
                    secondary: IconButton(
                      tooltip: t.hajjPackingRemove,
                      icon: Icon(Iconsax.trash, size: 18.sp, color: p.sub),
                      onPressed: () => _apply(widget.service.removeItem(item.id)),
                    ),
                  ),
                ),
              if (!widget.service.hasAllDefaults)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => _apply(widget.service.restoreDefaults()),
                    icon: Icon(Iconsax.rotate_left, size: 16.sp, color: p.accent),
                    label: Text(t.hajjPackingRestore, style: TextStyle(color: p.accent)),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 10.h),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    maxLength: 80,
                    style: TextStyle(color: p.text, fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: t.hajjPackingHint,
                      hintStyle: TextStyle(color: p.sub),
                      counterText: '',
                      isDense: true,
                      filled: true,
                      fillColor: p.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: p.accent.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: p.accent.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton.filled(
                  tooltip: t.hajjPackingAdd,
                  onPressed: _add,
                  style: IconButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.card),
                  icon: Icon(Iconsax.add, size: 20.sp),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Places
// ---------------------------------------------------------------------------

class _PlacesTab extends StatelessWidget {
  const _PlacesTab();

  /// Google Maps search URL for [place] (opens the Maps app when installed).
  static Uri mapsUri(HajjPlace place) =>
      Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': place.mapsQuery});

  Future<void> _open(BuildContext context, HajjPlace place) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    var launched = false;
    try {
      launched = await launchUrl(mapsUri(place), mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched) messenger.showSnackBar(SnackBar(content: Text(t.hajjMapsFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final lang = Localizations.localeOf(context).languageCode;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h + MediaQuery.paddingOf(context).bottom),
      children: [
        Text(t.hajjMapsNote, style: _bodyStyle(lang, 12.sp, p.sub)),
        SizedBox(height: 8.h),
        for (final place in hajjPlaces)
          Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: p.accent.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.location, size: 18.sp, color: p.accent),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(hajjText('place.${place.id}.name', lang),
                          style: _bodyStyle(lang, 15.sp, p.text, weight: FontWeight.w700)),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(hajjText('place.${place.id}.desc', lang), style: _bodyStyle(lang, 13.sp, p.text)),
                SizedBox(height: 8.h),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: () => _open(context, place),
                    icon: Icon(Iconsax.map, size: 16.sp, color: p.accent),
                    label: Text(t.hajjOpenInMaps,
                        style: TextStyle(color: p.accent, fontWeight: FontWeight.w700, fontSize: 13.sp)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
