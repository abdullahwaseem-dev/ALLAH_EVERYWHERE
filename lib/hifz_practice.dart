import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/challenge_auto_progress.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/services/hifz_audio_cache.dart';
import 'package:allah_everywhere/services/hifz_plan.dart';
import 'package:allah_everywhere/services/hifz_service.dart';
import 'package:allah_everywhere/services/hifz_words.dart';
import 'package:allah_everywhere/services/quran_audio_service.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

/// Hifz practice for one ayah range: repeat-play with the chosen reciter
/// (queued in the background audio handler, so it keeps going with the
/// screen locked), "test yourself" word hiding, and Remembered / Need
/// practice marking.
class HifzPracticeScreen extends StatefulWidget {
  final int surahId;
  final int from;
  final int to;

  HifzPracticeScreen({super.key, required this.surahId, int from = 1, int? to})
      : from = from.clamp(1, quran.getVerseCount(surahId)),
        to = (to ?? from + 4).clamp(
          from.clamp(1, quran.getVerseCount(surahId)),
          (from + HifzSettings.maxRangeLength - 1).clamp(1, quran.getVerseCount(surahId)),
        );

  @override
  State<HifzPracticeScreen> createState() => _HifzPracticeScreenState();
}

class _HifzPracticeScreenState extends State<HifzPracticeScreen> {
  final HifzService _hifz = HifzService();
  late int _from = widget.from;
  late int _to = widget.to;
  HifzSettings _settings = HifzSettings.fromMap(HifzService.storedSettings);
  late Map<int, AyahRecord> _records;

  HideLevel _hide = HideLevel.none;
  final Map<int, Set<int>> _revealed = {};

  bool _playing = false;
  HifzStep? _step;
  (int, int)? _download; // (done, total) while downloading
  String? _error;

  /// What the loaded session was built from; a different key means the next
  /// Play rebuilds the session.
  String? _loadedKey;

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<HifzStep?>? _stepSub;

  int get _verseCount => quran.getVerseCount(widget.surahId);
  String get _reciterId => QuranAudioService.selectedReciterId;
  String get _sessionKey => '${widget.surahId}|$_from|$_to|$_reciterId|${_settings.toMap()}';

  @override
  void initState() {
    super.initState();
    _records = _hifz.load()[widget.surahId] ?? {};
    HifzService.changes.addListener(_reloadRecords);
    final handler = QuranAudioService.handler;
    // Pick up a session for this surah that's still playing (e.g. reopened).
    if (handler.hasHifzSession && handler.hifzSurahId == widget.surahId) {
      _playing = handler.isPlaying;
      _step = handler.currentHifzStep;
    }
    _playingSub = handler.playingStream.listen((p) {
      if (mounted) setState(() => _playing = p && _ownsSession);
    });
    _stepSub = handler.hifzStepStream.listen((s) {
      if (mounted && _ownsSession) setState(() => _step = s);
    });
  }

  bool get _ownsSession {
    final h = QuranAudioService.handler;
    return h.hasHifzSession && h.hifzSurahId == widget.surahId;
  }

  void _reloadRecords() {
    if (mounted) setState(() => _records = _hifz.load()[widget.surahId] ?? {});
  }

  @override
  void dispose() {
    HifzService.changes.removeListener(_reloadRecords);
    _playingSub?.cancel();
    _stepSub?.cancel();
    ChallengeAutoProgress.flush();
    super.dispose();
  }

  Future<void> _play() async {
    final handler = QuranAudioService.handler;
    if (_ownsSession && _loadedKey == _sessionKey && handler.processingState != ProcessingState.idle) {
      await handler.play();
      return;
    }
    setState(() {
      _error = null;
      _download = (0, _to - _from + 1);
    });
    try {
      final files = await HifzAudioCache.ensure(
        surahId: widget.surahId,
        from: _from,
        to: _to,
        reciterId: _reciterId,
        onProgress: (done, total) {
          if (mounted) setState(() => _download = (done, total));
        },
      );
      if (!mounted) return;
      await handler.loadHifzSession(
        surahId: widget.surahId,
        surahName: quran.getSurahName(widget.surahId),
        reciterId: _reciterId,
        ayahFiles: files,
        steps: buildHifzPlan(from: _from, to: _to, settings: _settings),
        settings: _settings,
      );
      _loadedKey = _sessionKey;
      if (mounted) setState(() => _download = null);
      await handler.play();
    } catch (e) {
      VoidLogger.error('Could not start Hifz session', e);
      if (mounted) {
        setState(() {
          _download = null;
          _error = AppLocalizations.of(context)!.hifzAudioFailed;
        });
      }
    }
  }

  Future<void> _pause() => QuranAudioService.handler.pause();

  Future<void> _stop() async {
    await QuranAudioService.handler.stop();
    if (mounted) setState(() => _step = null);
  }

  void _updateSettings(HifzSettings s) {
    setState(() => _settings = s.clamped());
    HifzService.saveSettings(_settings.toMap());
  }

  void _setRange(int from, int to) {
    setState(() {
      _from = from;
      _to = to.clamp(from, (from + HifzSettings.maxRangeLength - 1).clamp(from, _verseCount));
      _revealed.clear();
    });
  }

  Future<void> _mark(int ayah, bool remembered) async {
    HapticFeedback.selectionClick();
    if (remembered) ChallengeAutoProgress.noteAyahMemorized(widget.surahId, ayah);
    await _hifz.mark(widget.surahId, ayah, remembered: remembered);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;
    final p = _Palette(accent, textColor, subColor, cardColor);

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: Column(
          children: [
            Text(t.hifzMode, style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, color: textColor)),
            Text(
              '${quran.getSurahName(widget.surahId)} · ${quran.getSurahNameArabic(widget.surahId)}',
              style: TextStyle(fontSize: 12.sp, color: subColor),
            ),
          ],
        ),
      ),
      body: ReadableWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, navBarClearance(context) + 24.h),
          children: [
            _card(p, [
              Row(
                children: [
                  Expanded(child: _rangePicker(t.hifzFrom, _from, 1, _verseCount, (v) => _setRange(v, _to < v ? v : _to), p)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _rangePicker(t.hifzTo, _to, _from,
                        (_from + HifzSettings.maxRangeLength - 1).clamp(_from, _verseCount), (v) => _setRange(_from, v), p),
                  ),
                ],
              ),
              Text(t.hifzRangeLimit('${HifzSettings.maxRangeLength}'), style: TextStyle(fontSize: 11.sp, color: subColor)),
            ]),
            _card(p, [
              _slider(t.hifzRepeatEach, t.hifzTimes('${_settings.repeatEachAyah}'), _settings.repeatEachAyah.toDouble(),
                  HifzSettings.minRepeat, HifzSettings.maxRepeat, (v) => _updateSettings(_settings.copyWith(repeatEachAyah: v.round())), p),
              _slider(t.hifzRounds, t.hifzTimes('${_settings.rounds}'), _settings.rounds.toDouble(), HifzSettings.minRounds,
                  HifzSettings.maxRounds, (v) => _updateSettings(_settings.copyWith(rounds: v.round())), p),
              _slider(t.hifzGap, t.hifzSeconds('${_settings.gapSeconds}'), _settings.gapSeconds.toDouble(),
                  HifzSettings.minGapSeconds, HifzSettings.maxGapSeconds, (v) => _updateSettings(_settings.copyWith(gapSeconds: v.round())), p),
              _slider(t.hifzSpeed, '${_settings.speed.toStringAsFixed(2)}×', _settings.speed, HifzSettings.minSpeed,
                  HifzSettings.maxSpeed, (v) => _updateSettings(_settings.copyWith(speed: (v * 20).round() / 20)), p,
                  divisions: 10),
              if (_ownsSession && _loadedKey != null && _loadedKey != _sessionKey)
                Text(t.hifzSettingsApplyNext, style: TextStyle(fontSize: 11.5.sp, color: accent)),
            ]),
            _playerBar(t, p),
            SizedBox(height: 14.h),
            Text(t.hifzTestYourself, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: textColor)),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                for (final (level, label) in [
                  (HideLevel.none, t.hideNone),
                  (HideLevel.firstLetters, t.hideFirstLetters),
                  (HideLevel.everyOther, t.hideEveryOther),
                  (HideLevel.all, t.hideAll),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _hide == level,
                    onSelected: (_) => setState(() {
                      _hide = level;
                      _revealed.clear();
                    }),
                    selectedColor: accent,
                    backgroundColor: cardColor,
                    showCheckmark: false,
                    labelStyle: TextStyle(fontSize: 12.sp, color: _hide == level ? Colors.white : textColor),
                    side: BorderSide(color: accent.withValues(alpha: 0.35)),
                  ),
              ],
            ),
            if (_hide != HideLevel.none) ...[
              SizedBox(height: 6.h),
              Text(t.hifzTapToReveal, style: TextStyle(fontSize: 11.5.sp, color: subColor)),
            ],
            SizedBox(height: 10.h),
            for (int ayah = _from; ayah <= _to; ayah++) _ayahCard(t, ayah, p),
          ],
        ),
      ),
    );
  }

  Widget _card(_Palette p, List<Widget> children) => Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18.r)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  Widget _rangePicker(String label, int value, int min, int max, ValueChanged<int> onChanged, _Palette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, color: p.sub)),
        DropdownButton<int>(
          value: value.clamp(min, max),
          isExpanded: true,
          dropdownColor: p.card,
          style: TextStyle(fontSize: 14.sp, color: p.text),
          items: [for (int i = min; i <= max; i++) DropdownMenuItem(value: i, child: Text('$i'))],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _slider(String label, String valueText, double value, num min, num max, ValueChanged<double> onChanged,
      _Palette p,
      {int? divisions}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: p.text))),
            Text(valueText, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: p.accent)),
          ],
        ),
        Slider(
          value: value.clamp(min.toDouble(), max.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions ?? (max - min).toInt(),
          activeColor: p.accent,
          label: valueText,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _playerBar(AppLocalizations t, _Palette p) {
    final step = _ownsSession ? _step : null;
    final s = _settings;
    String? status;
    if (_download != null) {
      status = t.hifzDownloading('${_download!.$1}', '${_download!.$2}');
    } else if (step != null) {
      status = t.hifzNowPlaying('${step.highlightedAyah}', '${step.repeat}', '${s.repeatEachAyah}', '${step.round}', '${s.rounds}');
    }
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [VoidColors.oliveDeep, p.accent.withValues(alpha: 0.9)]),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: [
          if (status != null)
            Text(status, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: Colors.white)),
          if (_error != null)
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: Colors.white)),
          if (status != null || _error != null) SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_download != null)
                SizedBox(width: 44.r, height: 44.r, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else
                _roundButton(
                  icon: _playing ? Iconsax.pause : Iconsax.play,
                  label: _playing ? t.hifzPause : t.hifzPlay,
                  onTap: _playing ? _pause : _play,
                  filled: true,
                ),
              SizedBox(width: 20.w),
              _roundButton(
                icon: Iconsax.stop,
                label: t.hifzStop,
                onTap: _ownsSession && (_playing || _step != null) ? _stop : null,
                filled: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundButton({required IconData icon, required String label, required VoidCallback? onTap, required bool filled}) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 32.r,
        child: Container(
          width: filled ? 52.r : 44.r,
          height: filled ? 52.r : 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Colors.white : Colors.transparent,
            border: filled ? null : Border.all(color: Colors.white.withValues(alpha: onTap == null ? 0.4 : 0.8), width: 1.5),
          ),
          child: Icon(
            icon,
            size: filled ? 26.sp : 20.sp,
            color: filled ? VoidColors.oliveDeep : Colors.white.withValues(alpha: onTap == null ? 0.4 : 1),
          ),
        ),
      ),
    );
  }

  Widget _ayahCard(AppLocalizations t, int ayah, _Palette p) {
    final current = _ownsSession && _step?.highlightedAyah == ayah;
    final record = _records[ayah];
    final words = splitAyah(quran.getVerse(widget.surahId, ayah));
    final revealed = _revealed[ayah] ?? const <int>{};
    var wordIndex = 0;
    String? nextReview;
    if (record != null) {
      try {
        nextReview = DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
            .format(DateTime.parse(record.nextReview));
      } catch (_) {
        nextReview = record.nextReview;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: current ? p.accent.withValues(alpha: 0.14) : p.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: current ? p.accent : p.accent.withValues(alpha: 0.2), width: current ? 1.6 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final word in words)
                  () {
                    final index = word.isMark ? -1 : wordIndex++;
                    final shown = revealed.contains(index) ? word.text : visibleText(word, index, _hide);
                    final style = ScriptureText.arabic(fontSize: 21.sp, color: p.text);
                    if (shown != null && (shown == word.text || word.isMark)) return Text(shown, style: style);
                    // Hidden or first-letter-only: tap to reveal.
                    return GestureDetector(
                      onTap: () => setState(() => _revealed.putIfAbsent(ayah, () => {}).add(index)),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border(bottom: BorderSide(color: p.accent, width: 1.5)),
                        ),
                        child: shown != null
                            ? Text(shown, style: style)
                            // Keep the word's width so the line doesn't reflow.
                            : Text(word.text, style: style.copyWith(color: Colors.transparent)),
                      ),
                    );
                  }(),
                Text(quran.getVerseEndSymbol(ayah), style: ScriptureText.arabic(fontSize: 19.sp, color: p.accent)),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _markButton(t.hifzRemembered, Iconsax.tick_circle,
                    record?.status == HifzStatus.remembered, () => _mark(ayah, true), p),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _markButton(t.hifzNeedPractice, Iconsax.refresh,
                    record?.status == HifzStatus.needsPractice, () => _mark(ayah, false), p),
              ),
            ],
          ),
          if (nextReview != null) ...[
            SizedBox(height: 6.h),
            Text(t.hifzNextReview(nextReview), style: TextStyle(fontSize: 11.sp, color: p.sub)),
          ],
        ],
      ),
    );
  }

  Widget _markButton(String label, IconData icon, bool selected, VoidCallback onTap, _Palette p) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16.sp, color: selected ? Colors.white : p.accent),
      label: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.sp, color: selected ? Colors.white : p.text)),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? p.accent : Colors.transparent,
        side: BorderSide(color: p.accent.withValues(alpha: 0.6)),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      ),
    );
  }
}

class _Palette {
  final Color accent;
  final Color text;
  final Color sub;
  final Color card;

  const _Palette(this.accent, this.text, this.sub, this.card);
}
