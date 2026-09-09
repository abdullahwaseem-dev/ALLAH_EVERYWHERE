import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'data/dua_data.dart';

class DuaDetailScreen extends StatelessWidget {
  final DuaItem dua;
  final int index;
  final int total;

  const DuaDetailScreen({
    Key? key,
    required this.dua,
    required this.index,
    required this.total,
  }) : super(key: key);

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
          dua.title,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$index/$total', style: TextStyle(fontSize: 14.sp, color: Colors.black)),
                SizedBox(width: 8.w),
                Expanded(
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : index / total,
                    backgroundColor: Colors.black12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              dua.title,
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            SizedBox(height: 20.h),
            Text(
              dua.arabic,
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w400, color: Colors.black, height: 1.5),
            ),
            SizedBox(height: 20.h),
            Text(
              dua.transliteration,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400, color: Colors.black87, height: 1.5),
            ),
            SizedBox(height: 20.h),
            Text(
              dua.translation,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400, color: Colors.black87, height: 1.5),
            ),
            SizedBox(height: 30.h),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.book, color: VoidColors.brown, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      dua.reference,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: VoidColors.brown),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
