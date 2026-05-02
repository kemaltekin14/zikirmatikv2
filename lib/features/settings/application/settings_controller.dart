import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class SettingsState {
  const SettingsState({
    this.vibrationEnabled = true,
    this.soundEnabled = true,
    this.largeTextMode = false,
    this.easyReadMode = false,
    this.themeMode = AppThemeMode.system,
    this.favorites = const {'subhanallah', 'estagfirullah'},
  });

  final bool vibrationEnabled;
  final bool soundEnabled;
  final bool largeTextMode;
  final bool easyReadMode;
  final AppThemeMode themeMode;
  final Set<String> favorites;

  SettingsState copyWith({
    bool? vibrationEnabled,
    bool? soundEnabled,
    bool? largeTextMode,
    bool? easyReadMode,
    AppThemeMode? themeMode,
    Set<String>? favorites,
  }) {
    return SettingsState(
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      largeTextMode: largeTextMode ?? this.largeTextMode,
      easyReadMode: easyReadMode ?? this.easyReadMode,
      themeMode: themeMode ?? this.themeMode,
      favorites: favorites ?? this.favorites,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  static const _vibrationKey = 'settings.vibrationEnabled';
  static const _soundKey = 'settings.soundEnabled';
  static const _largeTextKey = 'settings.largeTextMode';
  static const _easyReadKey = 'settings.easyReadMode';
  static const _themeKey = 'settings.themeMode';
  static const _favoritesKey = 'settings.favorites';

  @override
  SettingsState build() {
    Future.microtask(_restore);
    return const SettingsState();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final restored = SettingsState(
      vibrationEnabled: prefs.getBool(_vibrationKey) ?? true,
      soundEnabled: prefs.getBool(_soundKey) ?? true,
      largeTextMode: prefs.getBool(_largeTextKey) ?? false,
      easyReadMode: prefs.getBool(_easyReadKey) ?? false,
      themeMode: AppThemeMode.values.firstWhere(
        (mode) => mode.name == prefs.getString(_themeKey),
        orElse: () => AppThemeMode.system,
      ),
      favorites:
          (prefs.getStringList(_favoritesKey) ??
                  ['subhanallah', 'estagfirullah'])
              .toSet(),
    );
    state = restored;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, state.vibrationEnabled);
    await prefs.setBool(_soundKey, state.soundEnabled);
    await prefs.setBool(_largeTextKey, state.largeTextMode);
    await prefs.setBool(_easyReadKey, state.easyReadMode);
    await prefs.setString(_themeKey, state.themeMode.name);
    await prefs.setStringList(_favoritesKey, state.favorites.toList());
  }

  void toggleVibration() {
    state = state.copyWith(vibrationEnabled: !state.vibrationEnabled);
    _persist();
  }

  void setVibrationEnabled(bool value) {
    state = state.copyWith(vibrationEnabled: value);
    _persist();
  }

  void toggleSound() {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
    _persist();
  }

  void setSoundEnabled(bool value) {
    state = state.copyWith(soundEnabled: value);
    _persist();
  }

  void toggleLargeText() {
    state = state.copyWith(largeTextMode: !state.largeTextMode);
    _persist();
  }

  void setLargeTextMode(bool value) {
    state = state.copyWith(largeTextMode: value);
    _persist();
  }

  void toggleEasyRead() {
    state = state.copyWith(easyReadMode: !state.easyReadMode);
    _persist();
  }

  void setEasyReadMode(bool value) {
    state = state.copyWith(easyReadMode: value);
    _persist();
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void setQuietFeedbackMode(bool enabled) {
    state = state.copyWith(vibrationEnabled: !enabled, soundEnabled: !enabled);
    _persist();
  }

  void resetExperienceSettings() {
    state = state.copyWith(
      vibrationEnabled: true,
      soundEnabled: true,
      largeTextMode: false,
      easyReadMode: false,
      themeMode: AppThemeMode.system,
    );
    _persist();
  }

  void toggleFavorite(String dhikrId) {
    final favorites = {...state.favorites};
    if (!favorites.add(dhikrId)) {
      favorites.remove(dhikrId);
    }
    state = state.copyWith(favorites: favorites);
    _persist();
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
