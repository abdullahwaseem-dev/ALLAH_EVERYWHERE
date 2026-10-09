import 'package:allah_everywhere/surah.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'controller/QuranController.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/ask_ai_fab.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/mushaf.dart';
import 'package:allah_everywhere/services/mushaf_service.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:iconsax/iconsax.dart';

class QuranScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final QuranController controller = Get.put(QuranController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    return AskAiFabHost(
      category: 'Quran',
      child: Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          'Quran',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: ReadableWidth(child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        // Slivers instead of a shrinkWrap ListView inside a scroll view, so
        // only the visible surahs are built (114 rows were built up front).
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Last Read Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [VoidColors.cardDark, VoidColors.oliveDeep]
                        : [VoidColors.oliveDeep, VoidColors.dustyRose],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last Read',
                            style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                          ),
                          SizedBox(height: 4.h),
                          Obx(() {
                            if (controller.isLoading.value) {
                              return Text('Loading...', style: TextStyle(color: Colors.white));
                            }
                            return Text(
                              controller.lastReadSurahName.value.isNotEmpty
                                  ? controller.lastReadSurahName.value
                                  : 'الفاتحة',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }),
                          SizedBox(height: 8.h),
                          ElevatedButton(
                            onPressed: () {
                              Get.to(() => SurahScreen(
                                    surahName: controller.lastReadSurahName.value,
                                    surahId: controller.lastReadSurahId.value,
                                    initialAyah: controller.lastReadAyah.value,
                                  ));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Continue', style: TextStyle(fontSize: 12.sp, color: Colors.white)),
                                Icon(Icons.arrow_forward, size: 14.sp, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(VoidImages.quran_majeed, height: 100.h, width: 100.w, fit: BoxFit.contain),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              _buildViewToggle(context, controller, accent, textColor, cardColor),
              Obx(() => controller.mushafView.value
                  ? _buildContinueMushaf(context, controller, accent, textColor, cardColor)
                  : const SizedBox.shrink()),
              SizedBox(height: 12.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: TextField(
                  onChanged: (query) => controller.searchSurah(query),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: subColor),
                    hintText: 'Search For Quran',
                    hintStyle: TextStyle(fontSize: 14.sp, color: subColor),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
              ),
            ),

              // Surah List
              Obx(() {
                if (controller.isLoading.value) {
                  return SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: accent)));
                }

                if (controller.errorMessage.isNotEmpty) {
                  return SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Column(
                      children: [
                        Text(
                          controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.sp, color: Colors.red),
                        ),
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: controller.fetchSurahs,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ));
                }

                return SliverList.builder(
                  itemCount: controller.filteredSurahList.length,
                  itemBuilder: (context, index) {
                    final surah = controller.filteredSurahList[index];
                    final int surahNumber = surah['surahNumber'];

                    return buildSurahTile(
                      surah['surahName']!,
                      surah['surahNameArabic']!,
                      surah['surahNameTranslation']!,
                      surah['totalAyah'].toString(),
                      surahNumber,
                      isDark,
                      accent,
                      textColor,
                      subColor,
                      () async {
                        if (controller.mushafView.value) {
                          await Get.to(() => MushafScreen(initialPage: MushafService.pageForSurah(surahNumber)));
                          controller.refreshLastMushafPage();
                          return;
                        }
                        controller.updateLastReadSurah(surah['surahName'], surahNumber, 1);
                        Get.to(() => SurahScreen(
                              surahName: surah['surahName'],
                              surahId: surahNumber,
                            ));
                      },
                    );
                  },
                );
              }),
              SliverToBoxAdapter(child: SizedBox(height: 110.h)),
          ],
        ),
      )),
    ));
  }

  /// "Surah view / Mushaf view" switch.
  Widget _buildViewToggle(BuildContext context, QuranController controller, Color accent, Color textColor, Color cardColor) {
    final t = AppLocalizations.of(context)!;
    Widget option(String label, IconData icon, bool mushaf) => Expanded(
          child: Obx(() {
            final selected = controller.mushafView.value == mushaf;
            return Semantics(
              button: true,
              selected: selected,
              child: GestureDetector(
                onTap: () => controller.setMushafView(mushaf),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: selected ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16.sp, color: selected ? Colors.white : textColor),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14.r)),
      child: Row(
        children: [
          option(t.quranSurahView, Iconsax.task_square, false),
          option(t.quranMushafView, Iconsax.book_1, true),
        ],
      ),
    );
  }

  /// "Continue from page X" (or open at page 1 the first time).
  Widget _buildContinueMushaf(
      BuildContext context, QuranController controller, Color accent, Color textColor, Color cardColor) {
    final t = AppLocalizations.of(context)!;
    final last = controller.lastMushafPage.value;
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: PressableTile(
        onTap: () async {
          await Get.to(() => MushafScreen(initialPage: last ?? 1));
          controller.refreshLastMushafPage();
        },
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        semanticLabel: last == null ? t.mushafOpen : t.mushafContinue('$last'),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(Iconsax.book_saved, color: accent, size: 20.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  last == null ? t.mushafOpen : t.mushafContinue('$last'),
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: textColor),
                ),
              ),
              Icon(Iconsax.arrow_right_3, size: 14.sp, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSurahTile(
    String surahName,
    String arabicName,
    String translation,
    String totalAyah,
    int serialNumber,
    bool isDark,
    Color accent,
    Color textColor,
    Color subColor,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        PressableTile(
          onTap: onTap,
          semanticLabel: surahName,
          child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: accent.withOpacity(isDark ? 0.25 : 0.14),
                child: Text(
                  '$serialNumber',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: accent),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surahName,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Text(
                      '$translation ($totalAyah)',
                      style: TextStyle(fontSize: 12.sp, color: subColor),
                    ),
                  ],
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  arabicName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'NotoNaskhArabic',
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
        Divider(
          thickness: 1.h,
          color: textColor.withOpacity(0.08),
          height: 16.h,
        ),
      ],
    );
  }
}
