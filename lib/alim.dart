import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'live_messages.dart';
import 'masail&issues.dart';

class AlimScreen extends StatelessWidget {
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
          'Alim',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Image.asset(
            width: double.infinity,
            VoidImages.quran_background,
            fit: BoxFit.fill,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 90.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The already implemented banner
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(VoidImages.quran_banner),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            children: [
                              Text(
                                'Last Read',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: VoidColors.white,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'عَالِم',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: VoidColors.white,
                                ),
                              ),
                              Text(
                                'Masail and Issues',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: VoidColors.white,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: VoidColors.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 14.sp,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Image.asset(
                          VoidImages.alim_name,
                          height: 150.h,
                          width: 120.w,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Welcome section
                  Text(
                    'Welcome to Ask an Alim',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your Trusted Guide in Islamic Wisdom',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  ..._buildMenuOptions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuOptions() {
    final menuItems = [
      {
        'title': 'Masail and Issues',
        'icon': VoidImages.masail,
        'colors': [Color(0xFFD9D9D9), Color(0xFFA1729B)],
        'route': () => Get.to(() => MasailAndIssues()),
      },
      {
        'title': 'Live Questions',
        'icon': VoidImages.live_questions,
        'colors': [Color(0xFF8FA134), Color(0xFFA9BF3C)],
        'route': () => Get.to(() => LiveMessagesScreen()),
      },
      {
        'title': 'Recent Fatwas',
        'icon': VoidImages.fatwa,
        'colors': [Color(0xFFE4D3A3), Color(0xFF8C8360)]
      },
      {
        'title': 'Daily/Weekly Islamic Tips',
        'icon': VoidImages.islamic_tips,
        'colors': [Color(0xFF779FC1), Color(0xFF384B5B)]
      },
      {
        'title': 'Saved Questions',
        'icon': VoidImages.saved_questions,
        'colors': [Color(0xFFFF7BAC), Color(0xFFDB8289)]
      },
    ];

    return menuItems.map((item) {
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: item['colors'] as List<Color>,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 16.w),
            leading: Image.asset(
              item['icon'] as String,
              height: 100.h,
              width: 55.w,
              fit: BoxFit.fill,
            ),
            title: Text(
              item['title'] as String,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            trailing: Icon(
              Icons.play_circle_fill,
              size: 30.sp,
              color: Colors.white,
            ),
            onTap: item['title'] == 'Masail and Issues'
                ? () => Get.to(() => MasailAndIssues())
                : item['title'] == 'Live Questions'
                ? () => Get.to(() => LiveMessagesScreen())
                : () {},
            // Handle other cases
          ),
        ),
      );
    }).toList();
  }



}


