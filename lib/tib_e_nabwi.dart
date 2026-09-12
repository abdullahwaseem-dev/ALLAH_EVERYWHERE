import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/data/tib_e_nabwi_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TibENabwi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Tib e Nabwi (S.A.W)',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
      ),
      body: Padding(
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
                        'تعظيم النبي',
                        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    Image.asset(VoidImages.tib_e_nabwi, height: 100.h, width: 100.w, fit: BoxFit.contain),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Prophetic guidance on health and natural remedies (Tib-e-Nabwi)',
                style: TextStyle(fontSize: 14.sp, color: textColor, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4.h),
              Text(
                'These are traditional teachings from authentic Hadith. They are not a substitute for medical treatment - consult a doctor for health conditions.',
                style: TextStyle(fontSize: 12.sp, color: subColor, fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 16.h),
              for (int i = 0; i < tibENabwiCategories.length; i++)
                _buildCategoryCard(tibENabwiCategories[i], i, isDark, accent, textColor, subColor),
              SizedBox(height: 110.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    TibCategory category,
    int index,
    bool isDark,
    Color accent,
    Color textColor,
    Color subColor,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.06), blurRadius: 6.r, offset: const Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: index == 0,
          iconColor: accent,
          collapsedIconColor: accent,
          title: Text(
            category.title,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: textColor),
          ),
          subtitle: Text(
            category.intro,
            style: TextStyle(fontSize: 12.sp, color: subColor),
          ),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in category.items) _buildRemedyCard(item, isDark, accent, textColor, subColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRemedyCard(TibRemedy item, bool isDark, Color accent, Color textColor, Color subColor) {
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
          Text(item.title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textColor)),
          SizedBox(height: 6.h),
          Text(item.description, style: TextStyle(fontSize: 12.5.sp, color: textColor, height: 1.4)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.book, size: 13.sp, color: accent),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  item.reference,
                  style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
