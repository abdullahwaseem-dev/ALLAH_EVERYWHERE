import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/widgets/themed_background.dart';
import 'package:allah_everywhere/controllers/notifications_controller.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsController controller =
      Get.isRegistered<NotificationsController>() ? Get.find() : Get.put(NotificationsController());
  bool isSearchMode = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ThemedBackground(lightImagePath: VoidImages.otherscreen_background, fit: BoxFit.cover),
          if (isSearchMode)
            _buildSearchBar()
          else
            SafeArea(
              child: Column(
                children: [
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
                          style: TextStyle(color: Colors.black, fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.search, color: Colors.black, size: 24.sp),
                          onPressed: () => setState(() => isSearchMode = true),
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
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8.r, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final items = controller.search(_query);
                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              'No notifications yet',
                              style: TextStyle(color: Colors.black54, fontSize: 16.sp, fontWeight: FontWeight.w500),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final n = items[index];
                            return NotificationTile(
                              title: n.title,
                              time: DateFormat('MMM d, hh:mm a').format(n.createdAt),
                              isRead: n.isRead,
                            );
                          },
                        );
                      }),
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
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Enter your keyword',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(35.0),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Colors.grey[200],
                    filled: true,
                    prefixIcon: Icon(Icons.search, color: Colors.black),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                icon: Icon(Icons.close, color: Colors.black),
                onPressed: () => setState(() {
                  isSearchMode = false;
                  _query = '';
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final String title;
  final String time;
  final bool isRead;

  const NotificationTile({required this.title, required this.time, required this.isRead});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: isRead ? Colors.grey : Colors.blue,
            child: Icon(Icons.notifications, color: Colors.white, size: 20.sp),
          ),
          title: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
          subtitle: Text(time, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
        ),
        Divider(color: VoidColors.black.withOpacity(0.3)),
      ],
    );
  }
}
