import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/widgets/themed_background.dart';
import 'package:allah_everywhere/data/seerah_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SeeratScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'SEERAT E NABWI',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ThemedBackground(lightImagePath: VoidImages.quran_background),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 90.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      image: DecorationImage(image: AssetImage(VoidImages.quran_banner), fit: BoxFit.fill),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            'سیرتِ نبوی',
                            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: VoidColors.white),
                          ),
                        ),
                        Spacer(),
                        Image.asset(VoidImages.MUHAMMAD_2, height: 150.h, width: 150.w, fit: BoxFit.contain),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'The life of Prophet Muhammad (صلى الله عليه وسلم), from birth to his passing',
                    style: TextStyle(fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16.h),
                  for (int i = 0; i < seerahChapters.length; i++) _buildChapterCard(seerahChapters[i], i),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(SeerahChapter chapter, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6.r, offset: Offset(0, 2))],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: index == 0,
          title: Text(
            '${index + 1}. ${chapter.title}',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            chapter.period,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: VoidColors.brown),
          ),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final paragraph in chapter.paragraphs) ...[
              Text(paragraph, style: TextStyle(fontSize: 13.sp, color: Colors.black87, height: 1.5)),
              SizedBox(height: 10.h),
            ],
            if (chapter.reference != null)
              Row(
                children: [
                  Icon(Icons.book, size: 14.sp, color: VoidColors.brown),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      chapter.reference!,
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: VoidColors.brown),
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
