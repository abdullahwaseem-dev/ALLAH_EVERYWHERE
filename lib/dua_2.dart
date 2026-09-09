import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'data/dua_data.dart';
import 'duadetail.dart';

class Dua2Screen extends StatelessWidget {
  final DuaCategory category;

  const Dua2Screen({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidColors.secondary,
      appBar: AppBar(
        toolbarHeight: 60.h,
        backgroundColor: VoidColors.brown,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: VoidColors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          category.title,
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
                Icon(Icons.menu_book_outlined, color: Colors.black, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  '${category.duas.length} duas',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black),
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
                  onTap: () => Get.to(() => DuaDetailScreen(
                        dua: dua,
                        index: index + 1,
                        total: category.duas.length,
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
  final VoidCallback onTap;

  const DuaCard({Key? key, required this.number, required this.title, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 4, spreadRadius: 1, offset: Offset(0, 2)),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: Text(number, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
          ),
          title: Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400)),
          trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
          onTap: onTap,
        ),
      ),
    );
  }
}
