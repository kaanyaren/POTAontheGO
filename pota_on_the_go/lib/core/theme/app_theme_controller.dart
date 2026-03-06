import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';

final appThemeProvider = AsyncNotifierProvider<AppThemeController, ThemeMode>(
  AppThemeController.new,
);

class AppThemeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final preferences = await SharedPreferences.getInstance();
    final storedValue = preferences.getString(_themeModeKey);
    return _themeModeFromString(storedValue);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, mode.name);
  }

  ThemeMode _themeModeFromString(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
