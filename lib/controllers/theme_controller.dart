import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';

/// Drives light/dark mode using the app's own `VoidAppTheme`, which was
/// defined but never actually wired into `MaterialApp` before this.
class ThemeController extends GetxController {
  static const _key = 'dark_mode_enabled';

  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    final stored = VoidStorage().readData<bool>(_key) ?? false;
    themeMode.value = stored ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    await VoidStorage().saveData(_key, enabled);
  }
}
