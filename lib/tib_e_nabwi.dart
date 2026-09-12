import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/widgets/themed_background.dart';
import 'package:allah_everywhere/data/tib_e_nabwi_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TibENabwi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Tib e Nabwi (S.A.W)',
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
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              'تعظيم النبي',
                              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: VoidColors.white),
                            ),
                          ),
                        ),
                        Image.asset(VoidImages.tib_e_nabwi, height: 150.h, width: 150.w, fit: BoxFit.contain),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Prophetic guidance on health and natural remedies (Tib-e-Nabwi)',
                    style: TextStyle(fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'These are traditional teachings from authentic Hadith. They are not a substitute for medical treatment - consult a doctor for health conditions.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.black54, fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 16.h),
                  for (int i = 0; i < tibENabwiCategories.length; i++) _buildCategoryCard(tibENabwiCategories[i], i),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(TibCategory category, int index) {
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
            category.title,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            category.intro,
            style: TextStyle(fontSize: 12.sp, color: Colors.black54),
          ),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final item in category.items) _buildRemedyCard(item)],
        ),
      ),
    );
  }

  Widget _buildRemedyCard(TibRemedy item) {
    return Container(
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: VoidColors.secondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 6.h),
          Text(item.description, style: TextStyle(fontSize: 12.5.sp, color: Colors.black87, height: 1.4)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.book, size: 13.sp, color: VoidColors.brown),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  item.reference,
                  style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: VoidColors.brown),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
