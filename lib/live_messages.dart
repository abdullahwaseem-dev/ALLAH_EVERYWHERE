import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'chat.dart';

class LiveMessagesScreen extends StatefulWidget {
  @override
  _LiveMessagesScreenState createState() => _LiveMessagesScreenState();
}

class _LiveMessagesScreenState extends State<LiveMessagesScreen> {

  List<Message> messages = [
    Message(userName: "Jahangir", message: "Is it permissible to delay a prayer if I’m at work?", time: "11:20am"),
    Message(userName: "Abdullah", message: "Can I combine prayers during travel?", time: "10:20am"),
    Message(userName: "Jahangir", message: "Is it permissible to delay a prayer if I’m at work?", time: "09:20am"),
    Message(userName: "Abdullah", message: "What should I do if I forget a raka'ah in Salah?", time: "yesterday"),
    Message(userName: "Jahangir", message: "What are the rights of a wife in Islam?", time: "Wednesday"),
    Message(userName: "Abdullah", message: "Can I marry without my parents’ approval in Islam?", time: "Tuesday"),
    Message(userName: "Jahangir", message: "How do I calculate Zakat on my savings?", time: "Monday"),
    Message(userName: "Abdullah", message: "Are all seafood halal?", time: "Monday"),
  ];


  void _deleteMessage(int index) {
    setState(() {
      messages.removeAt(index);
    });
  }


  void _starMessage(int index) {
    setState(() {
      messages[index].isStarred = !messages[index].isStarred;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(VoidImages.details_background),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Positioned(
            top: 40.h,
            left: 16.w,
            right: 16.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
                  onPressed: () {
                    Get.back();
                  },
                ),
                Column(
                  children: [
                    Text(
                      'Live Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Image.asset(
                      VoidImages.bismillah,
                      height: 30.h,
                    ),
                  ],
                ),
                SizedBox(width: 40.w),
              ],
            ),
          ),
          Positioned(
            top: 130.h,
            left: 16.w,
            right: 16.w,
            bottom: 0,
            child: Container(
              height: MediaQuery.of(context).size.height - 100.h,
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageCard(
                    index: index,
                    userName: messages[index].userName,
                    message: messages[index].message,
                    time: messages[index].time,
                    isStarred: messages[index].isStarred,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard({
    required int index,
    required String userName,
    required String message,
    required String time,
    required bool isStarred,
  }) {
    return GestureDetector(
      onTap: () {

        Get.to(() => ChatScreen(
          userName: userName,
          avatar: 'https://example.com/avatar.jpg',
          initialMessage: message,
        ));
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6.r,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              radius: 20.r,
              child: Icon(Icons.person, color: Colors.black),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              time,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(width: 8.w),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'star') {
                  _starMessage(index);
                } else if (value == 'delete') {
                  _deleteMessage(index);
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'star',
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: isStarred ? Colors.yellow : Colors.grey,
                      ),
                      SizedBox(width: 8.w),
                      Text('Star'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8.w),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}


class Message {
  String userName;
  String message;
  String time;
  bool isStarred;

  Message({
    required this.userName,
    required this.message,
    required this.time,
    this.isStarred = false,
  });
}
