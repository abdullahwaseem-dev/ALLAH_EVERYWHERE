import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/widgets/themed_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class _TibItem {
  final String title;
  final String description;
  final String reference;
  const _TibItem({required this.title, required this.description, required this.reference});
}

const List<_TibItem> _remedies = [
  _TibItem(
    title: 'Honey',
    description: 'Described in the Quran as containing healing for people, commonly used for digestive and general wellness.',
    reference: 'Quran 16:69, Sahih Bukhari 5684',
  ),
  _TibItem(
    title: 'Black Seed (Kalonji)',
    description: 'The Prophet (ﷺ) said it is a remedy for every disease except death.',
    reference: 'Sahih Bukhari 5688, Sahih Muslim 2215',
  ),
  _TibItem(
    title: 'Cupping (Hijama)',
    description: 'A traditional therapy the Prophet (ﷺ) recommended among the best remedies used.',
    reference: 'Sahih Bukhari 5696',
  ),
  _TibItem(
    title: 'Dates (especially Ajwa)',
    description: 'The Prophet (ﷺ) said eating seven Ajwa dates in the morning protects against harm that day.',
    reference: 'Sahih Bukhari 5445, Sahih Muslim 2047',
  ),
  _TibItem(
    title: 'Talbina',
    description: 'A barley-based dish the Prophet (ﷺ) said soothes the heart of the sick and eases grief.',
    reference: 'Sahih Bukhari 5417, Sahih Muslim 2216',
  ),
  _TibItem(
    title: 'Zamzam Water',
    description: 'The Prophet (ﷺ) said Zamzam water serves the purpose for which it is drunk.',
    reference: 'Sunan Ibn Majah 3062',
  ),
  _TibItem(
    title: 'Olive Oil',
    description: 'The Prophet (ﷺ) recommended eating and applying olive oil, describing it as from a blessed tree.',
    reference: "Jami' at-Tirmidhi 1851",
  ),
];

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
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            'تعظيم النبي',
                            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: VoidColors.white),
                          ),
                        ),
                        Spacer(),
                        Image.asset(VoidImages.tib_e_nabwi, height: 150.h, width: 150.w, fit: BoxFit.contain),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Prophetic guidance on natural remedies (Tib-e-Nabwi)',
                    style: TextStyle(fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'These are traditional remedies mentioned in authentic Hadith. They are not a substitute for medical treatment - consult a doctor for health conditions.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.black54, fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 16.h),
                  for (final item in _remedies) _buildRemedyCard(item),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemedyCard(_TibItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6.r, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 6.h),
          Text(item.description, style: TextStyle(fontSize: 13.sp, color: Colors.black87, height: 1.4)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.book, size: 14.sp, color: VoidColors.brown),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  item.reference,
                  style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: VoidColors.brown),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
