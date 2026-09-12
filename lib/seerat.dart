import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/data/seerah_data.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SeeratScreen extends StatelessWidget {
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
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          'SEERAT E NABWI',
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
                        'سیرتِ نبوی',
                        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    Image.asset(VoidImages.MUHAMMAD_2, height: 100.h, width: 100.w, fit: BoxFit.contain),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'The life of Prophet Muhammad (صلى الله عليه وسلم), from birth to his passing',
                style: TextStyle(fontSize: 14.sp, color: textColor, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16.h),
              for (int i = 0; i < seerahChapters.length; i++)
                _buildChapterCard(seerahChapters[i], i, isDark, accent, textColor, subColor),
              SizedBox(height: 110.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterCard(
    SeerahChapter chapter,
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
            '${index + 1}. ${chapter.title}',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: textColor),
          ),
          subtitle: Text(
            chapter.period,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: accent),
          ),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final paragraph in chapter.paragraphs) ...[
              Text(paragraph, style: TextStyle(fontSize: 13.sp, color: textColor, height: 1.5)),
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
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: accent),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
