import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/services/tasbeeh_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/reward_cosmetics.dart';

const List<int> _targetOptions = [7, 33, 99, 100];

// Target 7 is for counting Tawaf / Sa'i rounds during Umrah and Hajj.
const int _tawafTarget = 7;

// Keyed by the stable IDs in tasbeehBeadIds - the colour itself is only
// presentation, so it is never what gets stored.
// A getter, so the gold bead follows the app's accent theme.
Map<String, Color> get _beadColors => {
  'gold': VoidColors.gold,
  'olive': VoidColors.oliveDeep,
  'green': Colors.green,
  'red': Colors.red,
  'purple': Colors.purple,
  'orange': Colors.orange,
};

class TasbeehScreen extends StatefulWidget {
  @override
  _TasbeehScreenState createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> with SingleTickerProviderStateMixin {
  final TasbeehService _service = TasbeehService();
  final TasbeehCounterStore _store = TasbeehCounterStore();
  late Map<String, TasbeehCounter> _counters;
  late String _selectedId;
  int _unsyncedTaps = 0;

  late final AnimationController _pulseController;

  TasbeehCounter get _current => _counters[_selectedId]!;
  Color get beadColor => _beadColors[_selectedId]!;

  @override
  void initState() {
    super.initState();
    _counters = _store.loadAll();
    _selectedId = _store.selectedBeadId;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
  }

  @override
  void dispose() {
    _syncPendingTaps();
    _pulseController.dispose();
    super.dispose();
  }

  void _syncPendingTaps() {
    if (_unsyncedTaps > 0) {
      _service.addToLifetimeTotal(_unsyncedTaps);
      _unsyncedTaps = 0;
    }
  }

  void _updateCurrent(TasbeehCounter counter) {
    setState(() => _counters[_selectedId] = counter);
    _store.save(_selectedId, counter);
  }

  void _increment() {
    HapticFeedback.lightImpact();
    _pulseController.forward(from: 0).then((_) => _pulseController.reverse());
    final counter = _current;
    final count = counter.count + 1;
    final lapDone = count % counter.target == 0;
    _unsyncedTaps++;
    _updateCurrent(counter.copyWith(count: count, laps: lapDone ? counter.laps + 1 : counter.laps));
    if (lapDone) {
      if (counter.target == _tawafTarget) {
        _signalSevenRounds();
      } else {
        HapticFeedback.mediumImpact();
      }
      _syncPendingTaps();
    }
  }

  /// Stronger than a normal lap so it is felt mid-Tawaf without looking at
  /// the phone. The system click follows the device's silent / touch-sound
  /// settings, so it stays quiet where the user has muted the phone.
  Future<void> _signalSevenRounds() async {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
    await Future.delayed(const Duration(milliseconds: 180));
    HapticFeedback.vibrate();
  }

  Future<bool> _confirm(String title, String message) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.reset, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void resetTasbeeh() async {
    final t = AppLocalizations.of(context)!;
    if (!await _confirm(t.resetCounterTitle, t.resetCounterMessage) || !mounted) return;
    _syncPendingTaps();
    _updateCurrent(_current.copyWith(count: 0, laps: 0));
  }

  void _resetAll() async {
    final t = AppLocalizations.of(context)!;
    if (!await _confirm(t.resetAllTitle, t.resetAllMessage)) return;
    _syncPendingTaps();
    await _store.resetAll();
    if (mounted) setState(() => _counters = _store.loadAll());
  }

  void _setTarget(int value) {
    _updateCurrent(_current.copyWith(target: value));
  }

  void _pickCustomTarget() async {
    final controller = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.customTarget),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 500'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: Text(AppLocalizations.of(context)!.set),
          ),
        ],
      ),
    );
    if (value != null && value > 0) _setTarget(value);
  }

  void _selectBead(String beadId) {
    if (beadId == _selectedId) return;
    _syncPendingTaps();
    setState(() => _selectedId = beadId);
    _store.saveSelectedBeadId(beadId);
  }

  void _renameBead(String beadId) async {
    _selectBead(beadId);
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _counters[beadId]!.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.nameCounter),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: t.nameCounterHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(t.save),
          ),
        ],
      ),
    );
    // An empty name clears it; cancel (null) leaves it unchanged.
    if (name == null || !mounted) return;
    final counter = _counters[beadId]!.copyWith(name: name);
    setState(() => _counters[beadId] = counter);
    _store.save(beadId, counter);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final counter = _current;
    final tasbeehCount = counter.count;
    final target = counter.target;
    final lapCount = counter.laps;
    final progress = (tasbeehCount % target) / target;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: ReadableWidth(child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                children: [
                  // Mirrors the menu button's width so the title stays centred.
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      t.tasbeehTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: textColor),
                    color: cardColor,
                    onSelected: (_) => _resetAll(),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'resetAll',
                        child: Text(t.resetAll, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.w,
              children: [
                ..._targetOptions.map((opt) => ChoiceChip(
                      label: Text('$opt'),
                      selected: target == opt,
                      selectedColor: accent,
                      backgroundColor: cardColor,
                      labelStyle: TextStyle(color: target == opt ? Colors.white : textColor),
                      onSelected: (_) => _setTarget(opt),
                    )),
                ChoiceChip(
                  label: Text(_targetOptions.contains(target) ? t.customTarget : '${t.customTarget} ($target)'),
                  selected: !_targetOptions.contains(target),
                  selectedColor: accent,
                  backgroundColor: cardColor,
                  labelStyle: TextStyle(color: !_targetOptions.contains(target) ? Colors.white : textColor),
                  onSelected: (_) => _pickCustomTarget(),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _increment,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) => Transform.scale(
                      scale: 1 + _pulseController.value,
                      child: child,
                    ),
                    child: Container(
                      width: 220.w,
                      height: 220.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardColor,
                        gradient: beadGradient(beadColor, cardColor),
                        boxShadow: [
                          BoxShadow(color: beadColor.withOpacity(0.3), blurRadius: 24, spreadRadius: 4),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 220.w,
                            height: 220.w,
                            child: CircularProgressIndicator(
                              value: progress == 0 && tasbeehCount > 0 ? 1 : progress,
                              strokeWidth: 8,
                              backgroundColor: beadColor.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation(beadColor),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$tasbeehCount',
                                style: TextStyle(
                                  fontSize: 56.sp,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '${tasbeehCount % target} / $target',
                                // Numbers read "0 / 33" in RTL too (bidi
                                // reordering showed "33 / 0" in Urdu/Arabic).
                                textDirection: TextDirection.ltr,
                                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                              ),
                              if (counter.name.isNotEmpty)
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 160.w),
                                  child: Text(
                                    counter.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: beadColor),
                                  ),
                                ),
                              if (target == _tawafTarget)
                                Text(
                                  t.tawafSaiRounds,
                                  style: TextStyle(fontSize: 11.sp, color: subColor),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              '${t.tapToCount} ${t.lapsCompleted}: $lapCount',
              style: TextStyle(fontSize: 13.sp, color: isDark ? VoidColors.textDarkSecondary : Colors.grey.shade700),
            ),
            // Includes morning/evening adhkar; taps not yet synced are added
            // so the number moves with every tap.
            ValueListenableBuilder<int>(
              valueListenable: TasbeehService.changes,
              builder: (context, _, __) => Text(
                t.tasbeehTodayTotal('${_service.todayTotal + _unsyncedTaps}'),
                style: TextStyle(fontSize: 12.sp, color: subColor),
              ),
            ),
            SizedBox(height: 12.h),
            TextButton.icon(
              onPressed: resetTasbeeh,
              icon: const Icon(Icons.refresh, color: Colors.red),
              label: Text(t.reset, style: TextStyle(color: Colors.red, fontSize: 14.sp)),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Column(
                children: [
                  Text(t.longPressToName, style: TextStyle(fontSize: 11.sp, color: subColor)),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final (i, id) in tasbeehBeadIds.indexed)
                        _ColorDot(
                          color: _beadColors[id]!,
                          count: _counters[id]!.count,
                          selected: id == _selectedId,
                          label: _counters[id]!.name.isNotEmpty ? _counters[id]!.name : t.tasbeehCounterNumber(i + 1),
                          ringColor: textColor,
                          onTap: () => _selectBead(id),
                          onLongPress: () => _renameBead(id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final int count;
  final bool selected;
  final String label;
  final Color ringColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ColorDot({
    required this.color,
    required this.count,
    required this.selected,
    required this.label,
    required this.ringColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeText = isDark ? VoidColors.cardDark : VoidColors.cardLight;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          // 48 x 48 tap target around the 36px dot.
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: selected
                        ? Border.all(color: ringColor, width: 3)
                        : Border.all(color: Colors.grey.shade300),
                  ),
                ),
                if (count > 0)
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: ringColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        count > 999 ? '999+' : '$count',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: badgeText),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
