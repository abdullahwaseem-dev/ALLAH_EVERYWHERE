import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/data/rewards_data.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';

/// Drives light/dark mode using the app's own `VoidAppTheme`, which was
/// defined but never actually wired into `MaterialApp` before this.
class ThemeController extends GetxController {
  static const _key = 'dark_mode_enabled';
  static const accentKey = 'accent_theme';

  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  /// The accent theme id (see accentColors in rewards_data.dart).
  final RxString accent = 'classic_gold'.obs;

  @override
  void onInit() {
    super.onInit();
    final stored = VoidStorage().readData<bool>(_key) ?? false;
    themeMode.value = stored ? ThemeMode.dark : ThemeMode.light;
    _applyAccent(VoidStorage().readData<String>(accentKey) ?? 'classic_gold');
  }

  void _applyAccent(String id) {
    final colors = accentColors[id] ?? accentColors['classic_gold']!;
    accent.value = accentColors.containsKey(id) ? id : 'classic_gold';
    VoidColors.useAccent(colors.$1, colors.$2);
  }

  /// Switches the app's accent colour (an unlocked accent theme). The app's
  /// themes are built with [withAccent], so every screen that reads the
  /// theme redraws in the new colour.
  Future<void> setAccent(String id) async {
    _applyAccent(id);
    await VoidStorage().saveData(accentKey, accent.value);
  }

  /// [base] carrying the current accent (reading [accent] here makes the
  /// app rebuild when it changes).
  ThemeData withAccent(ThemeData base) {
    final id = accent.value;
    final colors = accentColors[id] ?? accentColors['classic_gold']!;
    final color = base.brightness == Brightness.dark ? colors.$2 : colors.$1;
    return base.copyWith(colorScheme: base.colorScheme.copyWith(secondary: color, tertiary: color));
  }

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    await VoidStorage().saveData(_key, enabled);
  }
}
