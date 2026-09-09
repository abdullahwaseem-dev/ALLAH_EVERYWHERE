// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
//
// class VoidFormatter {
//   static String formatDate(DateTime? date) {
//     date ??= DateTime.now();
//     return DateFormat('dd-MMM-yyyy').format(date);
//   }
//
//   static String formatDateString(String formattedDate) {
//     DateFormat inputFormat = DateFormat('yyyy-MM-dd');
//     DateFormat outputFormat = DateFormat('d MMM');
//
//     DateTime dateTime = inputFormat.parse(formattedDate);
//     String formattedString = outputFormat.format(dateTime);
//
//     return formattedString;
//   }
//
//   /// Parses a formatted date string and calculates the age.
//   static int calculateAgeFromFormattedDate(String formattedDate) {
//     DateFormat dateFormat = DateFormat('yyyy-MM-dd');
//     DateTime birthDate = dateFormat.parse(formattedDate);
//     DateTime today = DateTime.now();
//
//     int age = today.year - birthDate.year;
//
//     // Adjust age if the birthday has not occurred yet this year.
//     if (today.month < birthDate.month ||
//         (today.month == birthDate.month && today.day < birthDate.day)) {
//       age--;
//     }
//
//     return age;
//   }
//
//   static String formatTimestamp(String timestamp) {
//     try {
//       DateTime dateTime = DateTime.parse(timestamp);
//       return DateFormat('h:mm a').format(dateTime);
//     } catch (e) {
//       return 'Invalid date';
//     }
//   }
//
//   static String formatFirestoreTimestamp(Timestamp timestamp) {
//     // Convert Timestamp to DateTime
//     DateTime dateTime = timestamp.toDate();
//
//     // Format DateTime to a string
//     String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
//
//     return formattedDate;
//   }
//
//   static String formatCurrency(double amount) {
//     return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
//   }
//
//   static String formatPhoneNumber(String phoneNumber) {
//     return phoneNumber;
//   }
// }
