// import 'package:flutter/material.dart';
// import 'package:get/route_manager.dart';
//
// class VoidHelperFunctions {
//
//   static void showSnackBar (String message){
//     ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(content: Text(message)));
//   }
//
//   static void showAlert (String title, String message){
//     showDialog(context: Get.context!, builder: (BuildContext context){
//       return AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))
//         ],
//       );
//     });
//   }
//
//   static void navigateToScreen (BuildContext context, Widget screen) {
//     Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
//   }
//
//   static String truncateString (String text, int maxLength) {
//     if (text.length <= maxLength){
//       return text;
//     }
//     else {
//       return '${text.substring(0,maxLength)}...';
//     }
//   }
//
//   static bool isDarkMode (BuildContext context) {
//     return Theme.of(context).brightness == Brightness.dark;
//   }
//
//   static String getTimeAgo(String timestampString) {
//     try{
//       DateTime postTime = DateTime.parse(timestampString);
//       DateTime now = DateTime.now();
//       Duration difference = now.difference(postTime);
//
//       if (difference.inDays >= 365) {
//         int years = (difference.inDays / 365).floor();
//         return years.toString() + (years > 1 ? " years ago" : " year ago");
//       } else if (difference.inDays >= 30) {
//         int months = (difference.inDays / 30).floor();  // Approximation for months
//         return months.toString() + (months > 1 ? " months ago" : " month ago");
//       } else if (difference.inDays >= 1) {
//         return difference.inDays.toString() + (difference.inDays > 1 ? " days ago" : " day ago");
//       } else if (difference.inHours >= 1) {
//         return difference.inHours.toString() + (difference.inHours > 1 ? " hours ago" : " hour ago");
//       } else if (difference.inMinutes >= 1) {
//         return difference.inMinutes.toString() + (difference.inMinutes > 1 ? " minutes ago" : " minute ago");
//       } else if (difference.inSeconds >= 1) {
//         return difference.inSeconds.toString() + (difference.inSeconds > 1 ? " seconds ago" : " second ago");
//       } else {
//         return "Just now";
//       }
//     }
//     catch (e){
//       return "invalid date";
//     }
//   }
//
//
// }