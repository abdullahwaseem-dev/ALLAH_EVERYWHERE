import 'package:flutter/material.dart';

/// Text styles for scripture. Arabic uses Amiri (the classical Naskh of
/// printed Hadith and Quran editions) and Urdu uses Noto Nastaliq Urdu -
/// both need generous line height, since their diacritics and Nastaliq's
/// diagonal baseline clip or collide at the default height.
class ScriptureText {
  ScriptureText._();

  static const String arabicFamily = 'Amiri';
  static const String urduFamily = 'NotoNastaliqUrdu';

  static TextStyle arabic({required double fontSize, Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: arabicFamily,
      fontSize: fontSize,
      height: 1.9,
      color: color,
      fontWeight: fontWeight,
    );
  }

  static TextStyle urdu({required double fontSize, Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: urduFamily,
      fontSize: fontSize,
      height: 2.1,
      color: color,
      fontWeight: fontWeight,
    );
  }
}
