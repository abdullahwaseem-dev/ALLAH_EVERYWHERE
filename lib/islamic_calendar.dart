import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allah_everywhere/data/islamic_events_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/services/islamic_calendar_service.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

typedef _Cal = IslamicCalendarService;

/// Colours shared by the calendar's widgets, all from the app palette.
class _Palette {
  final bool isDark;
  final Color accent;
  final Color textColor;
  final Color subColor;
  final Color cardColor;
  final Color fastColor = VoidColors.success;
  final Color forbiddenColor = VoidColors.error;

  _Palette(this.isDark)
      : accent = isDark ? VoidColors.goldDark : VoidColors.gold,
        textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep,
        subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600,
        cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;
}

/// Hijri month view with Islamic events and sunnah fasts. Swipe between
/// months; tap a day to see its events, and an event for its description
/// and source.
class IslamicCalendarScreen extends StatefulWidget {
  /// Day to open on (e.g. from a reminder notification); today if null.
  final DateTime? initialDate;

  const IslamicCalendarScreen({super.key, this.initialDate});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  late final DateTime _today;
  late DateTime _selected;
  late int _monthIndex;
  late final PageController _pageController;
  final int _adjustment = _Cal.adjustment;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final initial = widget.initialDate;
    _selected = initial == null ? _today : DateTime(initial.year, initial.month, initial.day);
    final h = _Cal.hijriOf(_selected, adjustment: _adjustment) ?? _Cal.hijriOf(_today, adjustment: _adjustment);
    _monthIndex = h == null ? _Cal.monthCount - 1 : _Cal.monthIndex(h.year, h.month).clamp(0, _Cal.monthCount - 1);
    _pageController = PageController(initialPage: _monthIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToToday() {
    final h = _Cal.hijriOf(_today, adjustment: _adjustment);
    setState(() => _selected = _today);
    if (h == null) return;
    _pageController.animateToPage(
      _Cal.monthIndex(h.year, h.month),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _turn(int delta) {
    final target = _monthIndex + delta;
    if (target < 0 || target >= _Cal.monthCount) return;
    _pageController.animateToPage(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  String _locale(BuildContext context) => Localizations.localeOf(context).languageCode;

  String _formatGregorian(DateTime d, String pattern, String locale) {
    try {
      return DateFormat(pattern, locale).format(d);
    } catch (_) {
      return DateFormat(pattern, 'en').format(d);
    }
  }

  void _showEvent(IslamicEventType type, HijriDate? onDate) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(Theme.of(context).brightness == Brightness.dark);
    final notes = <String>[
      if (debatedEvents.contains(type)) t.calendarDebatedNote,
      if (moonSightingEvents.contains(type)) t.calendarExpectedNote,
      if (type == IslamicEventType.eidFitr ||
          type == IslamicEventType.eidAdha ||
          type == IslamicEventType.tashreeq)
        t.calendarFastingForbidden,
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.cardColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(islamicEventName(t, type),
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: p.textColor)),
              if (onDate != null) ...[
                SizedBox(height: 4.h),
                Text(formatHijriDate(t, onDate), style: TextStyle(fontSize: 12.5.sp, color: p.accent)),
              ],
              if (recommendedFasts.contains(type)) ...[
                SizedBox(height: 8.h),
                _Tag(label: t.calendarSunnahFast, color: p.fastColor),
              ],
              SizedBox(height: 12.h),
              Text(islamicEventDescription(t, type),
                  style: TextStyle(fontSize: 14.sp, height: 1.5, color: p.textColor)),
              for (final note in notes) ...[
                SizedBox(height: 8.h),
                Text(note, style: TextStyle(fontSize: 12.5.sp, height: 1.45, color: p.subColor)),
              ],
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.book_1, color: p.accent, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '${t.calendarSource}: ${islamicEventSources[type]}',
                      style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: p.accent),
                    ),
                  ),
                ],
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
    final p = _Palette(Theme.of(context).brightness == Brightness.dark);
    final locale = _locale(context);
    final month = _Cal.monthAt(_monthIndex);
    final cellHeight = MediaQuery.textScalerOf(context).scale(40.h) + 10.h;
    final headerHeight = MediaQuery.textScalerOf(context).scale(16.h) + 10.h;

    return Scaffold(
      backgroundColor: p.isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.calendarTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19.sp, color: p.textColor)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: Text(t.calendarToday, style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ReadableWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, navBarClearance(context) + 24.h),
          children: [
            _buildMonthHeader(t, p, month.year, month.month, locale),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
              decoration: BoxDecoration(color: p.cardColor, borderRadius: BorderRadius.circular(18.r)),
              child: SizedBox(
                height: headerHeight + 6 * cellHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _Cal.monthCount,
                  onPageChanged: (i) => setState(() => _monthIndex = i),
                  itemBuilder: (context, index) {
                    final m = _Cal.monthAt(index);
                    return _MonthGrid(
                      year: m.year,
                      month: m.month,
                      adjustment: _adjustment,
                      today: _today,
                      selected: _selected,
                      cellHeight: cellHeight,
                      headerHeight: headerHeight,
                      palette: p,
                      locale: locale,
                      onSelect: (d) => setState(() => _selected = d),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 10.h),
            _Legend(palette: p),
            SizedBox(height: 14.h),
            _buildSelectedDay(t, p, locale),
            SizedBox(height: 14.h),
            _buildMonthEvents(t, p, month.year, month.month),
            SizedBox(height: 12.h),
            Text(
              t.calendarAdjustedNote(_adjustment > 0 ? '+$_adjustment' : '$_adjustment'),
              style: TextStyle(fontSize: 11.5.sp, height: 1.4, color: p.subColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(AppLocalizations t, _Palette p, int year, int month, String locale) {
    final first = _Cal.gregorianOf(HijriDate(year, month, 1), adjustment: _adjustment);
    final length = _Cal.monthLength(year, month);
    String range = '';
    if (first != null && length != null) {
      final last = first.add(Duration(days: length - 1));
      range = first.year == last.year
          ? '${_formatGregorian(first, 'MMM', locale)} – ${_formatGregorian(last, 'MMM y', locale)}'
          : '${_formatGregorian(first, 'MMM y', locale)} – ${_formatGregorian(last, 'MMM y', locale)}';
    }
    return Row(
      children: [
        IconButton(
          onPressed: _monthIndex > 0 ? () => _turn(-1) : null,
          icon: Icon(Icons.chevron_left, color: p.accent),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '${t.hijriMonthName('$month')} ${t.hijriYear('$year')}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700, color: p.textColor),
              ),
              if (range.isNotEmpty)
                Text(range, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, color: p.subColor)),
            ],
          ),
        ),
        IconButton(
          onPressed: _monthIndex < _Cal.monthCount - 1 ? () => _turn(1) : null,
          icon: Icon(Icons.chevron_right, color: p.accent),
        ),
      ],
    );
  }

  Widget _buildSelectedDay(AppLocalizations t, _Palette p, String locale) {
    final h = _Cal.hijriOf(_selected, adjustment: _adjustment);
    final events = h == null ? const <IslamicEventType>[] : _Cal.eventsOn(h, _selected);
    final forbidden = h != null && _Cal.isFastingForbidden(h);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: p.cardColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: p.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (h != null)
            Text(formatHijriDate(t, h), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: p.textColor)),
          Text(_formatGregorian(_selected, 'EEEE, d MMMM y', locale),
              style: TextStyle(fontSize: 12.5.sp, color: p.subColor)),
          SizedBox(height: 10.h),
          if (events.isEmpty)
            Text(t.calendarNoEvents, style: TextStyle(fontSize: 13.sp, color: p.subColor))
          else
            for (final e in events) _eventTile(t, p, e, h, null),
          if (forbidden) ...[
            SizedBox(height: 4.h),
            Text(t.calendarFastingForbidden,
                style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: p.forbiddenColor)),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthEvents(AppLocalizations t, _Palette p, int year, int month) {
    final length = _Cal.monthLength(year, month) ?? 0;
    // Each event type once, with every day of the month it falls on.
    final days = <IslamicEventType, List<int>>{};
    for (int d = 1; d <= length; d++) {
      final h = HijriDate(year, month, d);
      final g = _Cal.gregorianOf(h, adjustment: _adjustment);
      if (g == null) continue;
      for (final e in _Cal.eventsOn(h, g)) {
        days.putIfAbsent(e, () => []).add(d);
      }
    }
    final monthName = t.hijriMonthName('$month');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.calendarThisMonth, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: p.textColor)),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(color: p.cardColor, borderRadius: BorderRadius.circular(18.r)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in days.entries)
                _eventTile(
                  t,
                  p,
                  entry.key,
                  entry.value.length == 1 ? HijriDate(year, month, entry.value.single) : null,
                  '${entry.value.join(', ')} $monthName',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _eventTile(AppLocalizations t, _Palette p, IslamicEventType type, HijriDate? date, String? subtitle) {
    final color = recommendedFasts.contains(type)
        ? p.fastColor
        : (type == IslamicEventType.eidFitr || type == IslamicEventType.eidAdha || type == IslamicEventType.tashreeq)
            ? p.forbiddenColor
            : p.accent;
    return PressableTile(
      onTap: () => _showEvent(type, date),
      semanticLabel: islamicEventName(t, type),
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
        child: Row(
          children: [
            Container(width: 8.r, height: 8.r, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(islamicEventName(t, type),
                      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: p.textColor)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: 11.5.sp, color: p.subColor)),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 14.sp, color: p.subColor),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final int adjustment;
  final DateTime today;
  final DateTime selected;
  final double cellHeight;
  final double headerHeight;
  final _Palette palette;
  final String locale;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.year,
    required this.month,
    required this.adjustment,
    required this.today,
    required this.selected,
    required this.cellHeight,
    required this.headerHeight,
    required this.palette,
    required this.locale,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final firstDayIndex = material.firstDayOfWeekIndex; // 0 = Sunday
    final first = _Cal.gregorianOf(HijriDate(year, month, 1), adjustment: adjustment);
    final length = _Cal.monthLength(year, month);
    if (first == null || length == null) return const SizedBox.shrink();

    // DateTime.weekday: Mon=1..Sun=7; narrowWeekdays: Sun=0..Sat=6.
    final leading = (first.weekday % 7 - firstDayIndex + 7) % 7;
    final weekdays = [for (int i = 0; i < 7; i++) material.narrowWeekdays[(firstDayIndex + i) % 7]];

    return Column(
      children: [
        SizedBox(
          height: headerHeight,
          child: Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Center(
                    child: Text(w,
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: palette.subColor)),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: cellHeight),
            itemCount: leading + length,
            itemBuilder: (context, i) {
              if (i < leading) return const SizedBox.shrink();
              final day = i - leading + 1;
              final h = HijriDate(year, month, day);
              final g = DateTime(first.year, first.month, first.day + day - 1);
              return _DayCell(
                hijri: h,
                date: g,
                isToday: g == today,
                isSelected: g == selected,
                palette: palette,
                locale: locale,
                onTap: () => onSelect(g),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final HijriDate hijri;
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final _Palette palette;
  final String locale;
  final VoidCallback onTap;

  const _DayCell({
    required this.hijri,
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.palette,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final events = _Cal.eventsOn(hijri, date);
    final forbidden = _Cal.isFastingForbidden(hijri);
    final hasFast = events.any(recommendedFasts.contains);
    final hasEvent = events.any((e) => !recurringFasts.contains(e));
    final dots = <Color>[
      if (hasEvent) p.accent,
      if (hasFast) p.fastColor,
      if (forbidden) p.forbiddenColor,
    ];
    String gregorian;
    String fullDate;
    try {
      gregorian = date.day == 1 ? DateFormat('d MMM', locale).format(date) : '${date.day}';
      fullDate = DateFormat.yMMMMd(locale).format(date);
    } catch (_) {
      gregorian = '${date.day}';
      fullDate = DateFormat.yMMMMd('en').format(date);
    }
    final t = AppLocalizations.of(context)!;
    final mainColor = isToday ? Colors.white : p.textColor;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${formatHijriDate(t, hijri)}, $fullDate',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.all(2.r),
          decoration: BoxDecoration(
            color: isToday ? p.accent : (hasEvent ? p.accent.withValues(alpha: 0.10) : null),
            borderRadius: BorderRadius.circular(10.r),
            border: isSelected ? Border.all(color: isToday ? p.textColor : p.accent, width: 1.6) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${hijri.day}',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: mainColor, height: 1.1)),
              Text(
                gregorian,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 9.sp,
                  height: 1.1,
                  color: isToday ? Colors.white.withValues(alpha: 0.85) : p.subColor,
                ),
              ),
              SizedBox(height: 2.h),
              SizedBox(
                height: 5.r,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final c in dots)
                      Container(
                        width: 5.r,
                        height: 5.r,
                        margin: EdgeInsets.symmetric(horizontal: 1.r),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.white : c,
                          shape: BoxShape.circle,
                        ),
                      ),
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

class _Legend extends StatelessWidget {
  final _Palette palette;

  const _Legend({required this.palette});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8.r, height: 8.r, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            SizedBox(width: 5.w),
            Flexible(child: Text(label, style: TextStyle(fontSize: 11.5.sp, color: palette.subColor))),
          ],
        );
    return Wrap(
      spacing: 14.w,
      runSpacing: 6.h,
      alignment: WrapAlignment.center,
      children: [
        item(palette.accent, t.importantDatesReminder),
        item(palette.fastColor, t.calendarSunnahFast),
        item(palette.forbiddenColor, t.calendarFastingForbidden),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(label, style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
