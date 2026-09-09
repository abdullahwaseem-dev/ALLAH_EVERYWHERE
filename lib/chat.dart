import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatScreen extends StatelessWidget {
  final String userName;
  final String avatar;
  final String initialMessage;

  const ChatScreen({
    required this.userName,
    required this.avatar,
    required this.initialMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF1C7B2), Color(0xFFB19F95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(avatar),
              radius: 20.r,
            ),
            SizedBox(width: 10.w),
            Text(
              userName,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'delete') {

              } else if (value == 'search') {

              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8.w),
                    Text('Delete Chat'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.black),
                    SizedBox(width: 8.w),
                    Text('Search'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: VoidColors.secondary, // Background color
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildMessageBubble(
                    sender: true,
                    message: initialMessage,
                    time: '12:00 PM',
                  ),
                  // Add more message bubbles here as needed
                ],
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required bool sender,
    required String message,
    required String time,
  }) {
    return Align(
      alignment: sender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: sender ? Color(0xFF373E4E) : Color(0xFF7A8194),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment:
          sender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 14.sp,color:VoidColors.white),
            ),
            SizedBox(height: 4.h),
            Text(
              time,
              style: TextStyle(fontSize: 10.sp, color: VoidColors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Positioned(
      bottom: 16.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Color(0xFF3D4354),
          borderRadius: BorderRadius.circular(30.r), // Fully rounded corners
          boxShadow: [
            BoxShadow(
              color: Color(0xFF3D4354),
              blurRadius: 8.r,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                // Add your camera icon logic here
              },
              child: Icon(
                Icons.camera_alt,
                color: Color(0xFF9398A7),
              ),
            ),
            SizedBox(width: 8.w), // Optional: Adds some space between the icon and the text
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: VoidColors.white),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Color(0xFF9398A7)),
              onPressed: () {
                // Implement send message logic
              },
            ),
          ],
        ),
      ),
    );
  }


}
