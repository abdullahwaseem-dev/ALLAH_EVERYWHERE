import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'data/dua_data.dart';
import 'duadetail.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

class Dua2Screen extends StatelessWidget {
  final DuaCategory category;

  const Dua2Screen({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        toolbarHeight: 60.h,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          category.title,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: textColor),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 110.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(Icons.menu_book_outlined, color: accent, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  '${category.duas.length} duas',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: category.duas.length,
              itemBuilder: (context, index) {
                final dua = category.duas[index];
                return DuaCard(
                  number: '${index + 1}',
                  title: dua.title,
                  isDark: isDark,
                  accent: accent,
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () => Get.to(() => DuaDetailScreen(
                        dua: dua,
                        index: index + 1,
                        total: category.duas.length,
                        categoryTitle: category.title,
                      )),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DuaCard extends StatelessWidget {
  final String number;
  final String title;
  final bool isDark;
  final Color accent;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onTap;

  const DuaCard({
    Key? key,
    required this.number,
    required this.title,
    required this.isDark,
    required this.accent,
    required this.cardColor,
    required this.textColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.06), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: accent.withOpacity(isDark ? 0.25 : 0.14),
            child: Text(number, style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
          ),
          title: Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400, color: textColor)),
          trailing: Icon(Icons.chevron_right, color: textColor.withOpacity(0.5)),
          onTap: onTap,
        ),
      ),
    );
  }
}
