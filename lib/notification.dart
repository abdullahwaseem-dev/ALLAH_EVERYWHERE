import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool showToday = true;
  bool isSearchMode = false;

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

          // Search Mode
          if (isSearchMode)
            _buildSearchBar()
          else
            SafeArea(
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black, size: 24.sp),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search, color: Colors.black, size: 24.sp),
                          onPressed: () => setState(() {
                            isSearchMode = true;
                          }),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),


                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8.r,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with Tabs
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => showToday = true),
                                child: Text(
                                  'Today',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    decoration: showToday ? TextDecoration.underline : null,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => showToday = false),
                                child: Row(
                                  children: [
                                    Text(
                                      'Recommended',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        decoration: !showToday ? TextDecoration.underline : null,
                                      ),
                                    ),
                                    if (showToday || !showToday)
                                      Container(
                                        margin: EdgeInsets.only(left: 4.w),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        child: Text(
                                          '130',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),

                          // Notifications List
                          if (showToday)
                            Expanded(
                              child: ListView(
                                children: [
                                  NotificationTile(
                                    avatar: Icons.person,
                                    title:
                                    'The Hadith you were looking for has been found! Tap to read the full narration and context.',
                                    time: '9:01am',
                                  ),
                                  NotificationTile(
                                    avatar: Icons.person,
                                    title:
                                    'A new update for [specific Islamic book] is now available! Tap to explore.',
                                    time: '9:01am',
                                  ),
                                  NotificationTile(
                                    avatar: Icons.person,
                                    title:
                                    'Your question about [specific Fiqh issue] has been answered! Check the app for detailed guidance.',
                                    time: '9:01am',
                                  ),
                                  Text(
                                    'Yesterday',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  NotificationTile(
                                    avatar: Icons.person,
                                    title:
                                    'The Tafseer for the verse you inquired about has been provided.',
                                    time: '9:01am',
                                  ),
                                  NotificationTile(
                                    avatar: Icons.person,
                                    title:
                                    'The ruling on [specific issue] has been given by our Ulema. Open the app for the full response.',
                                    time: '9:01am',
                                  ),
                                  //Divider(),
                                  // This Week Section
                                  Text(
                                    'This week',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  NotificationTile(
                                    avatar: Icons.person,
                                    title:
                                    'Indeed, with hardship comes ease." - Quran 94:6. Remember this during challenging times.',
                                    time: '9:01am',
                                  ),
                                ],
                              ),
                            )
                          else
                            Center(
                              child: Text(
                                'Nothing to show',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
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


  Widget _buildSearchBar() {
    return SafeArea(
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
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
              SizedBox(width: 8.w),
              IconButton(
                icon: Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  setState(() {
                    isSearchMode = false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class NotificationTile extends StatelessWidget {
  final IconData avatar;
  final String title;
  final String time;

  const NotificationTile({
    required this.avatar,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            child: Icon(avatar, color: Colors.white, size: 20.sp),
            backgroundColor: Colors.blue,
          ),
          title: Text(
            title,
            style: TextStyle(fontSize: 14.sp),
          ),
          subtitle: Text(time, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
        ),
        Divider(
          color: VoidColors.black.withOpacity(0.3),
        ),
      ],
    );
  }
}
