import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'duadetail.dart';

class Dua2Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidColors.secondary,
      appBar: AppBar(
        toolbarHeight: 60.h,
        backgroundColor: VoidColors.brown,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: VoidColors.black,
            size: 20.sp,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Clothes',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            Row(

              children: [
                buildOption(
                  context,
                  title: 'All Duas',
                  icon: Icons.menu_book_outlined,
                  isSelected: true,
                ),
                SizedBox(width: 60.w),
                GestureDetector(
                  onTap: (){
                    Get.to(()=>DuaDetailScreen());
                  },
                  child: buildOption(
                    context,
                    title: 'My Favorites',
                    icon: Icons.bookmark_outline,
                    isSelected: false,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                DuaCard(number: '1', title: 'Before removing clothes'),
                DuaCard(number: '2', title: 'When wearing new clothes'),
                DuaCard(number: '3', title: 'After wearing Clothes'),
                DuaCard(
                    number: '4', title: 'To be said to someone wearing new clothes'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOption(BuildContext context,
      {required String title, required IconData icon, required bool isSelected}) {
    return Row(
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.black : Colors.grey,
          size: 20.sp,
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }
}

class DuaCard extends StatelessWidget {
  final String number;
  final String title;

  const DuaCard({
    required this.number,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: Text(
              number,
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
          onTap: () {},
        ),
      ),
    );
  }
}
