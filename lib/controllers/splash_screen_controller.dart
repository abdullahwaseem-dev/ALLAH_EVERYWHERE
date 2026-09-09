import 'package:flutter/material.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';


class SplashScreenController {
  final TickerProvider vsync;
  late AnimationController _controller;

  SplashScreenController({required this.vsync}) {

    _controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }


  Widget buildDot(int index) {
    double delay = index * 0.2;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double opacity = (1 - (index * 0.33)) * _controller.value;
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 12.0,
            height: 12.0,
            decoration: BoxDecoration(
              color: VoidColors.black,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }


  void dispose() {
    _controller.dispose();
  }
}
