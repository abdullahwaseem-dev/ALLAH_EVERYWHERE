import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:allah_everywhere/services/tasbeeh_service.dart';
import 'package:allah_everywhere/services/reading_stats_service.dart';
import 'package:allah_everywhere/services/account_service.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'About_us.dart';
import 'bookmarks_screen.dart';
import 'login.dart';
import 'notification.dart';
import 'editprofilescreen.dart';

class _ProfileData {
  final String name;
  final String? profilePicUrl;
  final int tasbeehTotal;
  final int hadithRead;

  _ProfileData({
    required this.name,
    required this.profilePicUrl,
    required this.tasbeehTotal,
    required this.hadithRead,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _getUserProfile();
  }

  Future<_ProfileData> _refresh() async {
    final future = _getUserProfile();
    setState(() => _profileFuture = future);
    return future;
  }

  Future<_ProfileData> _getUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    int tasbeehTotal = TasbeehService().lifetimeTotal;
    int hadithRead = ReadingStatsService().hadithReadCount;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] as String? ?? 'No Name';
        final profilePicUrl = data['profilePicture'] as String?;
        // Firestore may hold a higher total synced from another device.
        tasbeehTotal = (data['tasbeehTotal'] as num?)?.toInt() ?? tasbeehTotal;
        hadithRead = (data['hadithReadCount'] as num?)?.toInt() ?? hadithRead;
        return _ProfileData(
          name: name,
          profilePicUrl: (profilePicUrl != null && profilePicUrl.isNotEmpty) ? profilePicUrl : null,
          tasbeehTotal: tasbeehTotal,
          hadithRead: hadithRead,
        );
      }
    }

    return _ProfileData(
      name: 'Guest',
      profilePicUrl: null,
      tasbeehTotal: tasbeehTotal,
      hadithRead: hadithRead,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        title: Text(
          t.profileTitle,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: textColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<_ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accent));
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load profile', style: TextStyle(color: textColor)));
          } else if (snapshot.hasData) {
            final userProfile = snapshot.data!;

            return RefreshIndicator(
              onRefresh: _refresh,
              color: accent,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 24.h),
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent, width: 2.5)),
                      child: CircleAvatar(
                        radius: 52.r,
                        backgroundColor: isDark ? VoidColors.cardDark : VoidColors.cardLight,
                        backgroundImage: userProfile.profilePicUrl != null
                            ? NetworkImage(userProfile.profilePicUrl!)
                            : AssetImage(VoidImages.profile) as ImageProvider,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    userProfile.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          isDark: isDark,
                          accent: accent,
                          textColor: textColor,
                          subColor: subColor,
                          icon: Iconsax.book_1,
                          value: '${userProfile.hadithRead}',
                          label: t.hadithRead,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _StatCard(
                          isDark: isDark,
                          accent: accent,
                          textColor: textColor,
                          subColor: subColor,
                          icon: Iconsax.activity,
                          value: '${userProfile.tasbeehTotal}',
                          label: t.tasbeehCount,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    decoration: BoxDecoration(
                      color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Iconsax.bookmark,
                          text: t.bookmarks,
                          textColor: textColor,
                          onTap: () => Get.to(() => const BookmarksScreen()),
                        ),
                        _buildMenuItem(
                          icon: Iconsax.edit,
                          text: t.editProfile,
                          textColor: textColor,
                          onTap: () async {
                            await Get.to(() => EditProfileScreen());
                            _refresh();
                          },
                        ),
                        _buildMenuItem(
                          icon: Iconsax.info_circle,
                          text: t.aboutUs,
                          textColor: textColor,
                          onTap: () {
                            Get.to(() => AboutUsScreen());
                          },
                        ),
                        _buildMenuItem(
                          icon: Iconsax.notification,
                          text: t.notification,
                          textColor: textColor,
                          onTap: () {
                            Get.to(() => NotificationsScreen());
                          },
                        ),
                        _buildMenuItem(
                          icon: Iconsax.logout,
                          text: t.logOut,
                          textColor: textColor,
                          onTap: () {
                            _showLogoutDialog(context);
                          },
                        ),
                        if (FirebaseAuth.instance.currentUser != null)
                          _buildMenuItem(
                            icon: Iconsax.trash,
                            text: t.deleteAccount,
                            textColor: Colors.red,
                            isLast: true,
                            onTap: () => _showDeleteAccountDialog(context),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 130.h),
                ],
              ),
            );
          }
          return Container(); // Default return for any unexpected case
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required Color textColor,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: isLast
            ? null
            : BoxDecoration(border: Border(bottom: BorderSide(color: textColor.withOpacity(0.08)))),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 20.sp),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(text, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: textColor)),
            ),
            Icon(Iconsax.arrow_right_3, size: 14.sp, color: textColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete your account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your account and profile data. This cannot be undone. Enter your password to confirm.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: t.password),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await AccountService().deleteAccount(currentPassword: passwordController.text);
                  Get.offAll(() => Login());
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not delete account: $e')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.logOutConfirm,style: TextStyle(fontSize: 15.sp),),
          actions: [
            TextButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.remove('uid');


                await FirebaseAuth.instance.signOut();


                Get.to(() => Login());

              },
              child: Text(t.yes,style: TextStyle(fontSize: 18.sp,fontWeight: FontWeight.bold),),
            ),
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text(t.no,style: TextStyle(fontSize: 18.sp,fontWeight: FontWeight.bold),),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final Color textColor;
  final Color subColor;
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.isDark,
    required this.accent,
    required this.textColor,
    required this.subColor,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDark ? VoidColors.cardDark : VoidColors.cardLight,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 20.sp),
          SizedBox(height: 8.h),
          Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor)),
          SizedBox(height: 2.h),
          Text(label, style: TextStyle(fontSize: 11.sp, color: subColor)),
        ],
      ),
    );
  }
}
