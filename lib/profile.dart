import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:allah_everywhere/services/tasbeeh_service.dart';
import 'package:allah_everywhere/services/reading_stats_service.dart';
import 'package:allah_everywhere/services/account_service.dart';
import 'About_us.dart';
import 'login.dart';
import 'notification.dart';

class ProfileScreen extends StatelessWidget {
  Future<Map<String, dynamic>> _getUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    int tasbeehTotal = TasbeehService().lifetimeTotal;
    int hadithRead = ReadingStatsService().hadithReadCount;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        String name = data['name'] ?? 'No Name';
        String profilePicUrl = VoidImages.profile;
        // Firestore may hold a higher total synced from another device.
        tasbeehTotal = (data['tasbeehTotal'] as num?)?.toInt() ?? tasbeehTotal;
        hadithRead = (data['hadithReadCount'] as num?)?.toInt() ?? hadithRead;
        return {
          'name': name,
          'profilePicUrl': profilePicUrl,
          'tasbeehTotal': tasbeehTotal,
          'hadithRead': hadithRead,
        };
      }
    }

    return {
      'name': 'Guest',
      'profilePicUrl': VoidImages.profile,
      'tasbeehTotal': tasbeehTotal,
      'hadithRead': hadithRead,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load profile'));
          } else if (snapshot.hasData) {
            Map<String, dynamic> userProfile = snapshot.data!;

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(VoidImages.otherscreen_background),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 50.h),
                  CircleAvatar(
                    radius: 60.r,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 55.r,
                      backgroundImage: AssetImage(VoidImages.profile), // Use the placeholder image here
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    userProfile['name'] as String,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${userProfile['hadithRead']}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Hadith Read',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 50.w),
                      Column(
                        children: [
                          Text(
                            '${userProfile['tasbeehTotal']}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Tasbeeh Count',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  Expanded(
                    child: ListView(
                      physics: BouncingScrollPhysics(),
                      children: [
                        _buildMenuItem(
                          icon: Icons.account_circle_outlined,
                          text: 'About Us',
                          onTap: () {
                            Get.to(() => AboutUsScreen());
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.notifications,
                          text: 'Notification',
                          onTap: () {
                            Get.to(() => NotificationsScreen());
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.logout,
                          text: 'Log Out',
                          onTap: () {
                            _showLogoutDialog(context);
                          },
                        ),
                        if (FirebaseAuth.instance.currentUser != null)
                          _buildMenuItem(
                            icon: Icons.delete_forever,
                            text: 'Delete Account',
                            iconColor: Colors.red,
                            onTap: () => _showDeleteAccountDialog(context),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return Container(); // Default return for any unexpected case
        },
      ),

    );
  }

  Widget _buildMenuItem(
      {required IconData icon, required String text, required VoidCallback onTap, Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.blue, size: 28.sp),
      title: Text(
        text,
        style: TextStyle(fontSize: 18.sp, color: iconColor ?? Colors.black),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
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
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure you want to log out?",style: TextStyle(fontSize: 15.sp),),
          actions: [
            TextButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.remove('uid');


                await FirebaseAuth.instance.signOut();


                Get.to(() => Login());

              },
              child: Text("Yes",style: TextStyle(fontSize: 18.sp,fontWeight: FontWeight.bold),),
            ),
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text("No",style: TextStyle(fontSize: 18.sp,fontWeight: FontWeight.bold),),
            ),
          ],
        );
      },
    );
  }
}
