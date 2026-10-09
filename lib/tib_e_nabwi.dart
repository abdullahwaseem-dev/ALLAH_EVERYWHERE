import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/data/tib_e_nabwi_data.dart';
import 'package:allah_everywhere/data/prophetic_content.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class TibENabwi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Rebuilds when the app language changes, so the text switches at once.
    return Obx(() => _build(
        context, Get.find<LanguageController>().locale.value.languageCode));
  }

  Widget _build(BuildContext context, String languageCode) {
    final content = propheticContentFor(languageCode);
    final bodyFont = languageCode == 'ur' ? ScriptureText.urduFamily : null;
    final lineHeight = bodyFont == null ? 1.4 : 2.1;
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
        automaticallyImplyLeading: false,
        title: Text(
          content.text.tibTitle,
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
                        content.text.tibHeader,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: ScriptureText.urduFamily,
                          height: 1.8,
                        ),
                      ),
                    ),
                    Image.asset(VoidImages.tib_e_nabwi,
                        height: 100.h, width: 100.w, fit: BoxFit.contain),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                content.text.tibSubtitle,
                style: TextStyle(
                    fontSize: 14.sp,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontFamily: bodyFont),
              ),
              SizedBox(height: 4.h),
              Text(
                content.text.tibDisclaimer,
                style: TextStyle(
                    fontSize: 12.sp,
                    color: subColor,
                    fontStyle: bodyFont == null ? FontStyle.italic : null,
                    fontFamily: bodyFont,
                    height: bodyFont == null ? null : lineHeight),
              ),
              SizedBox(height: 16.h),
              for (int i = 0; i < content.tib.length; i++)
                _buildCategoryCard(context, content.tib[i], i, isDark, accent,
                    textColor, subColor, bodyFont, lineHeight),
              SizedBox(height: navBarClearance(context)),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    TibCategory category,
    int index,
    bool isDark,
    Color accent,
    Color textColor,
    Color subColor,
    String? bodyFont,
    double lineHeight,
  ) {
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
              category.title,
              style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: bodyFont),
            ),
            subtitle: Text(
              category.intro,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: subColor,
                  fontFamily: bodyFont,
                  height: bodyFont == null ? null : lineHeight),
            ),
            childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in category.items)
                _buildRemedyCard(item, isDark, accent, textColor, subColor,
                    bodyFont, lineHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemedyCard(
    TibRemedy item,
    bool isDark,
    Color accent,
    Color textColor,
    Color subColor,
    String? bodyFont,
    double lineHeight,
  ) {
    return Container(
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title,
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: bodyFont)),
          SizedBox(height: 6.h),
          Text(item.description,
              style: TextStyle(
                  fontSize: 12.5.sp,
                  color: textColor,
                  height: lineHeight,
                  fontFamily: bodyFont)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.book, size: 13.sp, color: accent),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  item.reference,
                  style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.bold,
                      color: accent,
                      fontFamily: bodyFont),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
