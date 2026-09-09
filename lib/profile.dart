import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'About_us.dart';
import 'login.dart';
import 'notification.dart';

class ProfileScreen extends StatelessWidget {
  Future<Map<String, String>> _getUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        String name = userDoc['name'] ?? 'No Name';
        String profilePicUrl = VoidImages.profile;
        return {'name': name, 'profilePicUrl': profilePicUrl};
      }
    }

    return {'name': 'Guest', 'profilePicUrl': VoidImages.profile};
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
      body: FutureBuilder<Map<String, String>>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load profile'));
          } else if (snapshot.hasData) {
            Map<String, String> userProfile = snapshot.data!;

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
                    userProfile['name']!,  // Display user name as fetched from Firestore
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
                            '47',
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
                            '27',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Masjid',
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
                            '656',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Tasbah',
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
                          icon: Icons.favorite,
                          text: 'Your Favorite',
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          icon: Icons.person_add,
                          text: 'Invite Your Friends',
                          onTap: () {},
                        ),
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
      {required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue, size: 28.sp),
      title: Text(
        text,
        style: TextStyle(fontSize: 18.sp, color: Colors.black),
      ),
      onTap: onTap,
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
