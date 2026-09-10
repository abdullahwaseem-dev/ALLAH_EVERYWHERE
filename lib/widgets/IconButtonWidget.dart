import 'package:flutter/material.dart';

class IconButtonWidget extends StatelessWidget {
  final String imagePath;
  final String title;

  const IconButtonWidget({Key? key, required this.imagePath, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imagePath, height: 40),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
