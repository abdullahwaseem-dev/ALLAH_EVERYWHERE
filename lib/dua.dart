import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:get/get.dart';
import 'ask_ai.dart';
import 'data/dua_data.dart';
import 'dua_2.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/ask_ai_fab.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class DuaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    return AskAiFabHost(
      category: 'Dua',
      child: Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Dua", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19.sp, color: textColor)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: ReadableWidth(child: Column(
        children: [
          Stack(
            children: [
              Image.asset(VoidImages.hands_dua, width: double.infinity, fit: BoxFit.cover, height: 180.h),
              Container(
                width: double.infinity,
                height: 180.h,
                child: Image.asset(VoidImages.overlay, width: double.infinity, fit: BoxFit.cover, height: 180.h),
              ),
              Positioned(
                bottom: 10.h,
                left: 0,
                right: 0,
                // Sized by its content (it was a fixed 95.h, which clipped
                // the cards on iPhone SE and with larger text sizes).
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                  child: IntrinsicHeight(
                    child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildCard("Guidance and Righteousness",
                          "O Allah, guide me, make me steadfast, and set my affairs right.", cardColor, textColor, subColor),
                      buildCard("Forgiveness", "O Allah, You are the Most Forgiving, so forgive me.", cardColor, textColor, subColor),
                      buildCard("Gratitude", "O Allah, I thank You for Your countless blessings.", cardColor, textColor, subColor),
                    ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Icon Menu Section
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.1), blurRadius: 8.r, offset: const Offset(0, 2)),
                ],
              ),
              child: PressableTile(
                color: cardColor,
                borderRadius: BorderRadius.circular(14.r),
                semanticLabel: "Ask AI about a Dua",
                onTap: () => Get.to(() => AskAiScreen(initialCategory: 'Dua')),
                child: Padding(
                  padding: EdgeInsets.all(11.w),
                  child: Center(
                    child: buildIconMenuItem(accent, textColor, "Ask AI about a Dua"),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("All Duas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: textColor)),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final category in duaCategories)
                          buildDuaCard(
                            title: category.title,
                            duaCount: category.duas.length,
                            cardColor: cardColor,
                            textColor: textColor,
                            subColor: subColor,
                            isDark: isDark,
                            onTap: () => Get.to(() => Dua2Screen(category: category)),
                          ),
                        SizedBox(height: 130.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      )),
    ));
  }

  Widget buildCard(String title, String subtitle, Color cardColor, Color textColor, Color subColor) {
    return Container(
      width: 300.w,
      margin: EdgeInsetsDirectional.only(end: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8.r, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: textColor),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: subColor, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget buildIconMenuItem(Color accent, Color textColor, String title) {
    return Column(
      children: [
        Icon(Icons.auto_awesome, color: accent, size: 26.h),
        SizedBox(height: 8.h),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: textColor)),
      ],
    );
  }

  Widget buildDuaCard({
    required String title,
    required int duaCount,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 6.r, offset: const Offset(0, 2)),
          ],
        ),
        child: PressableTile(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        semanticLabel: title,
        onTap: onTap,
        child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: textColor)),
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("$duaCount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: textColor)),
                    Text("Duas", style: TextStyle(fontSize: 14.sp, color: subColor)),
                  ],
                ),
                SizedBox(width: 8.w),
                Icon(Icons.chevron_right, color: subColor),
              ],
            ),
          ],
        ),
        ),
        ),
      ),
    );
  }
}
