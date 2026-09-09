import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart'; // Your image path

class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Container
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(VoidImages.otherscreen_background),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Search Bar and Content
          SafeArea(
            child: Column(
              children: [
                // App Bar with Back Icon and Search Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black, size: 24.sp),
                        onPressed: () => Navigator.pop(context),
                      ),

                      // Search Bar
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.w), // Space between back button and search bar
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Enter your keyword',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 16.sp),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(35.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.grey[200],
                              filled: true, // Enable background fill
                              prefixIcon: Icon(Icons.search, color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),

                // Placeholder for other search content
                Expanded(
                  child: Center(
                    child: Text(
                      'Search content here...',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
