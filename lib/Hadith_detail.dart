import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/services/reading_stats_service.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/share_cards/share_content.dart';
import 'package:allah_everywhere/share_cards/share_studio_screen.dart';


import 'controller/HadithDetailController.dart';
import 'package:allah_everywhere/widgets/ask_ai_fab.dart';
import 'package:allah_everywhere/ask_ai.dart';
import 'package:iconsax/iconsax.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class HadithDetail extends StatefulWidget {
  final String bookSlug;
  final int chapterNumber;
  const HadithDetail({Key? key, required this.bookSlug, required this.chapterNumber}) : super(key: key);

  @override
  State<HadithDetail> createState() => _HadithDetailState();
}

class _HadithDetailState extends State<HadithDetail> {
  final HadithDetailController _controller = Get.put(HadithDetailController());

  @override
  void initState() {
    super.initState();
    _controller.fetchHadiths(widget.bookSlug, widget.chapterNumber);
    ReadingStatsService().incrementHadithRead();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;

    return AskAiFabHost(
      category: 'Hadith',
      questionBuilder: () => _controller.chapterName.value.isEmpty
          ? null
          : AppLocalizations.of(context)!.askAiExplainHadithChapter(_controller.chapterName.value),
      child: Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: ReadableWidth(child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  VoidBackButton(color: Colors.white),
                  Expanded(
                    child: Obx(() {
                      return Column(
                        children: [
                          Text(
                            _controller.chapterName.value,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Image.asset(
                            VoidImages.bismillah,
                            height: 30.h,
                            fit: BoxFit.contain,
                            color: Colors.white,
                          ),
                        ],
                      );
                    }),
                  ),
                  SizedBox(width: 48.w),
                ],
              ),
            ),
            // Scrollable Body
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return Center(child: CircularProgressIndicator(color: accent));
                }

                if (_controller.errorMessage.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16.sp, color: Colors.red),
                        ),
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: () => _controller.fetchHadiths(widget.bookSlug, widget.chapterNumber),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Built lazily: some chapters hold 150+ long hadiths, and
                // laying them all out up front made the screen stall.
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 110.h),
                  itemCount: _controller.hadithData.length,
                  itemBuilder: (context, index) {
                    final hadith = _controller.hadithData[index];
                    final book = hadith['book'];
                    return HadithCard(
                      arabicText: hadith['hadithArabic'] ?? '',
                      urduText: hadith['hadithUrdu'] ?? '',
                      englishText: hadith['hadithEnglish'] ?? '',
                      hadithNumber: hadith['hadithNumber']?.toString() ?? '',
                      bookName: (book is Map ? book['bookName'] as String? : null) ?? 'Unknown Book',
                      narrationSource: hadith['urduNarrator'] ?? '',
                    );
                  },
                );
              }),
            ),
          ],
        ),
      )),
    ));
  }
}
class HadithCard extends StatelessWidget {
  final String arabicText;
  final String urduText;
  final String englishText;
  final String hadithNumber;
  final String bookName;
  final String narrationSource;

  const HadithCard({
    required this.arabicText,
    required this.urduText,
    required this.englishText,
    required this.hadithNumber,
    required this.bookName,
    required this.narrationSource,
  });

  void _openShareStudio() {
    final lang = Get.isRegistered<LanguageController>()
        ? Get.find<LanguageController>().locale.value.languageCode
        : 'en';
    Get.to(() => ShareStudioScreen(
          initialContent: ShareContent.hadith(
            arabic: arabicText,
            english: englishText,
            urdu: urduText,
            reference: '$bookName $hadithNumber',
            languageCode: lang,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade700;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final divider = Divider(height: 22.h, color: textColor.withValues(alpha: 0.08));
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Hadith #$hadithNumber',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: accent),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    bookName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.sp, fontStyle: FontStyle.italic, color: subColor),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.to(() => AskAiScreen(
                        initialCategory: 'Hadith',
                        initialQuestion: AppLocalizations.of(context)!.askAiExplainHadith(bookName, hadithNumber),
                      )),
                  tooltip: AppLocalizations.of(context)!.askAiAboutHadith,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Iconsax.magic_star, size: 20.sp, color: accent),
                ),
                IconButton(
                  onPressed: _openShareStudio,
                  tooltip: 'Share as image',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.ios_share, size: 20.sp, color: accent),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            if (arabicText.trim().isNotEmpty)
              Text(
                arabicText.trim(),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: ScriptureText.arabic(fontSize: 20.sp, color: textColor),
              ),
            if (urduText.trim().isNotEmpty) ...[
              divider,
              Text(
                urduText.trim(),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: ScriptureText.urdu(fontSize: 15.5.sp, color: textColor),
              ),
            ],
            if (englishText.trim().isNotEmpty) ...[
              divider,
              Text(
                englishText.trim(),
                style: TextStyle(fontSize: 14.5.sp, height: 1.55, color: textColor.withValues(alpha: 0.9)),
              ),
            ],
            if (narrationSource.trim().isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                narrationSource.trim(),
                textDirection: TextDirection.rtl,
                style: ScriptureText.urdu(fontSize: 11.5.sp, color: subColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
