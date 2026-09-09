import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class _SeeratEvent {
  final String year;
  final String title;
  final String description;
  const _SeeratEvent({required this.year, required this.title, required this.description});
}

const List<_SeeratEvent> _timeline = [
  _SeeratEvent(
    year: '570 CE',
    title: 'Birth in Makkah',
    description: 'Prophet Muhammad (peace be upon him) was born in Makkah in the Year of the Elephant.',
  ),
  _SeeratEvent(
    year: '610 CE',
    title: 'First Revelation',
    description:
        'At age 40, in the Cave of Hira, the angel Jibril (Gabriel) brought the first verses of the Quran, beginning with "Iqra" (Read).',
  ),
  _SeeratEvent(
    year: '613 CE',
    title: 'Public Preaching Begins',
    description: 'After three years of private invitation, the message of Islam was proclaimed publicly in Makkah.',
  ),
  _SeeratEvent(
    year: '622 CE',
    title: 'The Hijrah (Migration to Madinah)',
    description:
        'Facing persecution, the Prophet and his companions migrated to Madinah. This migration marks the start of the Islamic calendar.',
  ),
  _SeeratEvent(
    year: '624 CE',
    title: 'Battle of Badr',
    description: 'The first major battle between the Muslims of Madinah and the Quraysh of Makkah.',
  ),
  _SeeratEvent(
    year: '628 CE',
    title: 'Treaty of Hudaybiyyah',
    description: 'A peace treaty with the Quraysh that allowed Islam to spread rapidly across Arabia.',
  ),
  _SeeratEvent(
    year: '630 CE',
    title: 'Conquest of Makkah',
    description: 'Makkah was peacefully retaken, and the Kaaba was cleared of idols and rededicated to the worship of Allah alone.',
  ),
  _SeeratEvent(
    year: '632 CE',
    title: 'The Farewell Sermon',
    description:
        'Delivered at Arafah during his final pilgrimage, summarizing the core principles of Islam - justice, equality, and the sanctity of life.',
  ),
  _SeeratEvent(
    year: '632 CE',
    title: 'Passing in Madinah',
    description: 'The Prophet passed away in Madinah, leaving behind the Quran and his Sunnah as guidance.',
  ),
];

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
          Image.asset(width: double.infinity, VoidImages.quran_background, fit: BoxFit.fill),
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
                    'A brief timeline of the life of Prophet Muhammad (صلى الله عليه وسلم)',
                    style: TextStyle(fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16.h),
                  for (final event in _timeline) _buildEventCard(event),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(_SeeratEvent event) {
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
          Text(event.year, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: VoidColors.brown)),
          SizedBox(height: 4.h),
          Text(event.title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 6.h),
          Text(event.description, style: TextStyle(fontSize: 13.sp, color: Colors.black87, height: 1.4)),
        ],
      ),
    );
  }
}
