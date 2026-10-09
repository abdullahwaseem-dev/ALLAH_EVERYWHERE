import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Height of the floating glass bottom nav bar itself.
const double floatingNavBarHeight = 64;

/// Gap between the floating nav bar and the bottom screen edge: above the
/// home indicator on Face ID iPhones, a fixed 16 on home-button phones.
double floatingNavBarBottomGap(BuildContext context) =>
    math.max(16, MediaQuery.viewPaddingOf(context).bottom);

/// Bottom padding for scrollable content on the tab screens, so the last
/// item can scroll clear of the floating nav bar. The bar's Scaffold uses
/// extendBody, which reports the bar's height as the body's bottom padding.
double navBarClearance(BuildContext context) => MediaQuery.paddingOf(context).bottom + 16;

/// True on tablets / wide windows, where Home switches to two columns.
bool isWideLayout(BuildContext context) => MediaQuery.sizeOf(context).width >= 700;

/// Keeps reading content at a comfortable line length on iPad: centres the
/// child at [maxWidth] when the screen is wider. On phones (narrower than
/// [maxWidth]) the child is returned untouched.
class ReadableWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ReadableWidth({super.key, required this.child, this.maxWidth = 760});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth <= maxWidth) return child;
      return Center(
        child: SizedBox(
          width: maxWidth,
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          child: child,
        ),
      );
    });
  }
}
