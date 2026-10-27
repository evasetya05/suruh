import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../../core/storage/local_storage.dart';

/// Persists the user's light / dark / system preference.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._storage) : super(_read(_storage));

  final LocalStorage _storage;

  static ThemeMode _read(LocalStorage storage) {
    final String? stored = storage.getString(LocalStorage.kThemeMode);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _storage.setString(LocalStorage.kThemeMode, mode.name);
  }

  /// Cycles system -> light -> dark, which is what the app-bar toggle uses.
  Future<void> cycle() => set(
        switch (state) {
          ThemeMode.system => ThemeMode.light,
          ThemeMode.light => ThemeMode.dark,
          ThemeMode.dark => ThemeMode.system,
        },
      );

  IconData get icon => switch (state) {
        ThemeMode.system => Icons.brightness_auto_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
      };

  String get label => switch (state) {
        ThemeMode.system => 'System theme',
        ThemeMode.light => 'Light theme',
        ThemeMode.dark => 'Dark theme',
      };
}
