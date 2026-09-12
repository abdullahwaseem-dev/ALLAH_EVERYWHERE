import 'package:flutter/material.dart';

/// Several screens (Quran, Hadith, Qibla, Dua, Fiqh, Seerat, Tib-e-Nabwi,
/// Prayer Timing) are built around a light, decorative background image.
/// There's no dark-mode variant of that artwork, so in dark mode this
/// swaps it for a plain dark gradient instead - keeping text readable
/// without needing new art assets.
class ThemedBackground extends StatelessWidget {
  final String lightImagePath;
  final BoxFit fit;

  const ThemedBackground({Key? key, required this.lightImagePath, this.fit = BoxFit.fill})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
          ),
        ),
      );
    }
    return Image.asset(lightImagePath, width: double.infinity, fit: fit);
  }
}
