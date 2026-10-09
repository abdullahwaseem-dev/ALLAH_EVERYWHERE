import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class _FaqEntry {
  final String question;
  final String answer;

  const _FaqEntry(this.question, this.answer);
}

const List<_FaqEntry> _faqEntries = [
  _FaqEntry(
    'How accurate are the prayer times?',
    'Prayer times are calculated from your device\'s location using standard astronomical formulas. '
        'You can change the calculation method and madhab (for Asr) from Settings > Prayer Timing if the '
        'default doesn\'t match your local mosque.',
  ),
  _FaqEntry(
    'The Qibla compass looks off - what should I do?',
    'Move your phone in a figure-8 motion to calibrate its compass sensor - most direction issues come from '
        'the phone\'s magnetometer needing calibration, or from being near metal objects or magnets. Make sure '
        'location permission is granted so your position can be used to calculate the bearing to the Kaaba.',
  ),
  _FaqEntry(
    'Where do the Hadith come from?',
    'Hadith are sourced from Sahih Bukhari, Sahih Muslim, Jami\' Al-Tirmidhi, Sunan Abu Dawood, Sunan '
        'Ibn-e-Majah, Sunan An-Nasa\'i, Mishkat Al-Masabih, Musnad Ahmad, and Al-Silsila Sahiha.',
  ),
  _FaqEntry(
    'Is the "Ask AI" feature a substitute for a scholar?',
    'No. Ask AI is an AI model grounded in the Quran and authentic Hadith, and it cites references when it '
        'can. For significant personal rulings (divorce, inheritance, major financial matters), always confirm '
        'with a qualified local scholar who knows your full situation.',
  ),
  _FaqEntry(
    'Do I need an account to use the app?',
    'No. Most features work as a guest, with your data (bookmarks, Ask AI history) stored locally on your '
        'device. Signing in syncs that data to your account instead so it isn\'t lost if you reinstall.',
  ),
  _FaqEntry(
    'Does the app work offline?',
    'The Quran, Duas, prayer times, and Qibla compass work offline. Hadith and Ask AI need an internet '
        'connection since they fetch from an external source.',
  ),
  _FaqEntry(
    'Is the app really free?',
    'Yes. There are no subscriptions, paywalls, or in-app purchases. There is a single small banner ad to '
        'help keep the app running.',
  ),
  _FaqEntry(
    'How do I change the app language?',
    'Go to Settings > Language to choose from the supported languages.',
  ),
  _FaqEntry(
    'I found a bug or have a suggestion - how do I reach you?',
    'Use the "Support the Developer" option in Settings, which opens an email, or reach out directly at '
        'maw112266@gmail.com.',
  ),
];

class HelpFaqScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        title: Text(
          'Help & FAQ',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: textColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const VoidBackButton(),
      ),
      body: ReadableWidth(child: SafeArea(
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: _faqEntries.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final entry = _faqEntries[index];
            return _FaqTile(entry: entry, accent: accent, textColor: textColor, subColor: subColor, isDark: isDark);
          },
        ),
      )),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _FaqEntry entry;
  final Color accent;
  final Color textColor;
  final Color subColor;
  final bool isDark;

  const _FaqTile({
    required this.entry,
    required this.accent,
    required this.textColor,
    required this.subColor,
    required this.isDark,
  });

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? VoidColors.cardDark : VoidColors.cardLight,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(widget.isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PressableTile(
            borderRadius: BorderRadius.circular(14.r),
            semanticLabel: widget.entry.question,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              child: Row(
                children: [
                  Icon(Iconsax.message_question, color: widget.accent, size: 18.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.entry.question,
                      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: widget.textColor),
                    ),
                  ),
                  Icon(
                    _expanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                    size: 16.sp,
                    color: widget.subColor,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Text(
                widget.entry.answer,
                style: TextStyle(fontSize: 12.5.sp, color: widget.subColor, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}
