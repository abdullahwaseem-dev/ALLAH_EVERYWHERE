import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/hifz_practice.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/services/hifz_plan.dart';
import 'package:allah_everywhere/services/hifz_service.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

/// Hifz overview: ayahs memorized, Juz Amma progress, today's spaced-
/// repetition reviews, and every surah's progress.
class HifzDashboardScreen extends StatefulWidget {
  const HifzDashboardScreen({super.key});

  @override
  State<HifzDashboardScreen> createState() => _HifzDashboardScreenState();
}

class _HifzDashboardScreenState extends State<HifzDashboardScreen> {
  final HifzService _hifz = HifzService();
  late HifzProgress _progress = _hifz.load();

  @override
  void initState() {
    super.initState();
    HifzService.changes.addListener(_reload);
    // Device copy shows at once; the cloud merge (if signed in) follows.
    _hifz.sync();
  }

  @override
  void dispose() {
    HifzService.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => _progress = _hifz.load());
  }

  void _open(int surah, int from, int to) =>
      Get.to(() => HifzPracticeScreen(surahId: surah, from: from, to: to));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    final total = totalMemorized(_progress);
    final juzDone = juzAmmaMemorized(_progress);
    final juzTotal = juzAmmaAyahCount;
    final reviews = groupReviewRanges(dueForReview(_progress, DateTime.now()), maxLength: HifzSettings.maxRangeLength);

    Widget sectionTitle(String text) => Padding(
          padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
          child: Text(text, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: textColor)),
        );

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.hifzTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: textColor)),
        centerTitle: true,
      ),
      body: ReadableWidth(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
              sliver: SliverList.list(
                children: [
                  Container(
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [VoidColors.cardDark, VoidColors.oliveDeep]
                            : [VoidColors.oliveDeep, VoidColors.dustyRose],
                      ),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Iconsax.medal_star, color: VoidColors.goldDark, size: 22.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                t.hifzMemorizedTotal('$total'),
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        Text(t.hifzJuzAmma,
                            style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: Colors.white70)),
                        SizedBox(height: 6.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: juzTotal == 0 ? 0 : juzDone / juzTotal,
                            minHeight: 8.h,
                            color: VoidColors.goldDark,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${t.hifzProgressOf('$juzDone', '$juzTotal')} · ${_percent(juzDone, juzTotal)}',
                          style: TextStyle(fontSize: 11.5.sp, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  sectionTitle(t.hifzReviewToday),
                  if (reviews.isEmpty)
                    Text(t.hifzReviewEmpty, style: TextStyle(fontSize: 13.sp, color: subColor))
                  else
                    for (final r in reviews)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: PressableTile(
                          onTap: () => _open(r.surah, r.from, r.to),
                          semanticLabel: '${quran.getSurahName(r.surah)} ${t.hifzAyahRange('${r.from}', '${r.to}')}',
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                            child: Row(
                              children: [
                                Icon(Iconsax.repeat, color: accent, size: 18.sp),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    '${quran.getSurahName(r.surah)} · ${t.hifzAyahRange('${r.from}', '${r.to}')}',
                                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: textColor),
                                  ),
                                ),
                                Icon(Iconsax.arrow_right_3, size: 14.sp, color: subColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                  sectionTitle(t.hifzSurahs),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, navBarClearance(context) + 24.h),
              sliver: SliverList.builder(
                itemCount: quran.totalSurahCount,
                itemBuilder: (context, i) {
                  final surah = i + 1;
                  final count = quran.getVerseCount(surah);
                  final done = memorizedIn(_progress, surah);
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: PressableTile(
                      onTap: () => _open(surah, 1, count.clamp(1, 5)),
                      semanticLabel: '${quran.getSurahName(surah)}, ${_percent(done, count)}',
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28.w,
                              child: Text('$surah', style: TextStyle(fontSize: 12.sp, color: subColor)),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(quran.getSurahName(surah),
                                      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: textColor)),
                                  SizedBox(height: 5.h),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3.r),
                                    child: LinearProgressIndicator(
                                      value: done / count,
                                      minHeight: 4.h,
                                      color: accent,
                                      backgroundColor: textColor.withValues(alpha: 0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(_percent(done, count),
                                style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: accent)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _percent(int done, int total) => total == 0 ? '0%' : '${(done * 100 / total).round()}%';
}
