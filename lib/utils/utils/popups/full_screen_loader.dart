// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import '../../common/widgets/annimation_loader.dart';
// import '../constraints/colors.dart';
// import '../helpers/helper_functions.dart';

// class VoidFullScreenLoader {
//   static void openLoadingDialog(String text, String animation) {
//     showDialog(
//         context: Get.overlayContext!,
//         barrierDismissible: false,
//         builder: (_) => PopScope(
//               canPop: false,
//               child: Container(
//                 color: VoidHelperFunctions.isDarkMode(Get.context!)
//                     ? VoidColors.dark
//                     : VoidColors.white,
//                 width: double.infinity,
//                 height: double.infinity,
//                 child: Column(
//                   children: [
//                     const SizedBox(
//                       height: 250,
//                     ),
//                     VoidAnimationLoaderWidget(text: text, animation: animation),
//                   ],
//                 ),
//               ),
//             ));
//   }

//   static stopLoading(){
//     Navigator.of(Get.overlayContext!).pop();
//   }
// }
