import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/data/seerah_data.dart';
import 'package:allah_everywhere/data/prophetic_content.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class SeeratScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Rebuilds when the app language changes, so the text switches at once.
    return Obx(() => _build(
        context, Get.find<LanguageController>().locale.value.languageCode));
  }

  Widget _build(BuildContext context, String languageCode) {
    final content = propheticContentFor(languageCode);
    final bodyFont = languageCode == 'ur' ? ScriptureText.urduFamily : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor =
        isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          content.text.seeratTitle,
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
      ),
      body: ReadableWidth(child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      child: Text(
                        content.text.seeratHeader,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: ScriptureText.urduFamily,
                          height: 1.8,
                        ),
                      ),
                    ),
                    Image.asset(VoidImages.MUHAMMAD_2,
                        height: 100.h, width: 100.w, fit: BoxFit.contain),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                content.text.seeratSubtitle,
                style: TextStyle(
                    fontSize: 14.sp,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontFamily: bodyFont,
                    height: bodyFont == null ? null : 2.1),
              ),
              SizedBox(height: 16.h),
              for (int i = 0; i < content.seerah.length; i++)
                _buildChapterCard(context, content.seerah[i], i, isDark, accent,
                    textColor, subColor, bodyFont),
              SizedBox(height: 110.h),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildChapterCard(
    BuildContext context,
    SeerahChapter chapter,
    int index,
    bool isDark,
    Color accent,
    Color textColor,
    Color subColor,
    String? bodyFont,
  ) {
    // Nastaliq sits taller than Latin script, so Urdu needs more leading.
    final lineHeight = bodyFont == null ? 1.5 : 2.1;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 6.r,
              offset: const Offset(0, 2)),
        ],
      ),
      // Transparent Material so the tile's ink draws above this card's
      // colour (without it Flutter reports the splash as invisible), and the
      // app theme is extended - not replaced - just to hide the dividers.
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: index == 0,
            iconColor: accent,
            collapsedIconColor: accent,
            title: Text(
              '${index + 1}. ${chapter.title}',
              style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: bodyFont),
            ),
            subtitle: Text(
              chapter.period,
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: accent,
                  fontFamily: bodyFont),
            ),
            childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final paragraph in chapter.paragraphs) ...[
                Text(paragraph,
                    style: TextStyle(
                        fontSize: 13.sp,
                        color: textColor,
                        height: lineHeight,
                        fontFamily: bodyFont)),
                SizedBox(height: 10.h),
              ],
              if (chapter.reference != null)
                Row(
                  children: [
                    Icon(Icons.book, size: 14.sp, color: accent),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        chapter.reference!,
                        style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: accent,
                            fontFamily: bodyFont),
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
}
