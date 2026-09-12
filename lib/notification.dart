import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:allah_everywhere/controllers/notifications_controller.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';

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
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.black54;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: isSearchMode
          ? SafeArea(child: _buildSearchBar(isDark, textColor))
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_outlined, color: textColor, size: 24.sp),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          t.notificationsTitle,
                          style: TextStyle(color: textColor, fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.search, color: textColor, size: 24.sp),
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
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.1), blurRadius: 8.r, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return Center(child: CircularProgressIndicator(color: accent));
                        }
                        final items = controller.search(_query);
                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              t.noNotificationsYet,
                              style: TextStyle(color: subColor, fontSize: 16.sp, fontWeight: FontWeight.w500),
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
                              isDark: isDark,
                              accent: accent,
                              textColor: textColor,
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color textColor) {
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterKeyword,
                hintStyle: TextStyle(color: subColor, fontSize: 16.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(35.0),
                  borderSide: BorderSide.none,
                ),
                fillColor: isDark ? VoidColors.cardDark : Colors.grey[200],
                filled: true,
                prefixIcon: Icon(Icons.search, color: subColor),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: () => setState(() {
              isSearchMode = false;
              _query = '';
            }),
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final String title;
  final String time;
  final bool isRead;
  final bool isDark;
  final Color accent;
  final Color textColor;

  const NotificationTile({
    required this.title,
    required this.time,
    required this.isRead,
    required this.isDark,
    required this.accent,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: isRead ? Colors.grey : accent,
            child: Icon(Icons.notifications, color: Colors.white, size: 20.sp),
          ),
          title: Text(
            title,
            style: TextStyle(fontSize: 14.sp, fontWeight: isRead ? FontWeight.normal : FontWeight.bold, color: textColor),
          ),
          subtitle: Text(time, style: TextStyle(color: isDark ? VoidColors.textDarkSecondary : Colors.grey, fontSize: 12.sp)),
        ),
        Divider(color: textColor.withOpacity(0.15)),
      ],
    );
  }
}
