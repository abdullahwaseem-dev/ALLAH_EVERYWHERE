import 'package:flutter/material.dart';
import '../constraints/colors.dart';
import 'custom_themes/appbar_theme.dart';
import 'custom_themes/bottom_sheet_theme.dart';
import 'custom_themes/checkbox_theme.dart';
import 'custom_themes/chip_theme.dart';
import 'custom_themes/elevated_button_theme.dart';
import 'custom_themes/outlined_button_theme.dart';
import 'custom_themes/text_field_theme.dart';
import 'custom_themes/text_theme.dart';

class VoidAppTheme {
  VoidAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Lexend',
    brightness: Brightness.light,
    primaryColor: VoidColors.primary,
    scaffoldBackgroundColor: Colors.white,
    textTheme: VoidTextTheme.lightTextTheme,
    chipTheme: VoidChipTheme.lightChipTheme,
    appBarTheme: VoidAppBarTheme.lightAppBarTheme,
    checkboxTheme: VoidCheckboxTheme.lightCheckBoxTheme,
    bottomSheetTheme: VoidBottomSheetTheme.lightBottomSheetTheme,
    elevatedButtonTheme: VoidElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: VoidOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: VoidTextFieldTheme.lightInputDecorationTheme,
  );
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: VoidColors.pink,
    scaffoldBackgroundColor: Colors.black,
    textTheme: VoidTextTheme.darkTextTheme,
    chipTheme: VoidChipTheme.darkChipTheme,
    appBarTheme: VoidAppBarTheme.darkAppBarTheme,
    checkboxTheme: VoidCheckboxTheme.darkCheckBoxTheme,
    bottomSheetTheme: VoidBottomSheetTheme.darkBottomSheetTheme,
    elevatedButtonTheme: VoidElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: VoidOutlinedButtonTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: VoidTextFieldTheme.darkInputDecorationTheme,
  );
}
