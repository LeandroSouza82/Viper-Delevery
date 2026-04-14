import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

enum NavigationApp { googleMaps, waze }
enum ViperThemeMode { day, night, automatic }

class SettingsController extends ChangeNotifier {
  static final SettingsController _instance = SettingsController._internal();
  factory SettingsController() => _instance;
  SettingsController._internal();

  NavigationApp _navigationApp = NavigationApp.googleMaps;
  ViperThemeMode _themeMode = ViperThemeMode.automatic;
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  bool _isPanicButtonEnabled = false;
  String _emergencyContact = "";
  bool _isInit = false;

  NavigationApp get navigationApp => _navigationApp;
  ViperThemeMode get themeMode => _themeMode;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get isPanicButtonEnabled => _isPanicButtonEnabled;
  String get emergencyContact => _emergencyContact;

  /// Retorna o estilo do mapa baseado na configuração atual e horário
  String get mapStyle {
    if (_themeMode == ViperThemeMode.day) return MapboxStyles.MAPBOX_STREETS;
    if (_themeMode == ViperThemeMode.night) return MapboxStyles.DARK;
    
    // Lógica Automática (06:00 - 18:00)
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 18) {
      return MapboxStyles.MAPBOX_STREETS;
    } else {
      return MapboxStyles.DARK;
    }
  }

  /// Verifica se o tema atual (calculado) é escuro
  bool get isDarkTheme {
    return mapStyle == MapboxStyles.DARK;
  }

  Future<void> init() async {
    if (_isInit) return;
    final prefs = await SharedPreferences.getInstance();
    
    // Carrega Navegador
    final navIndex = prefs.getInt('navigation_app') ?? 0;
    _navigationApp = NavigationApp.values[navIndex];

    // Carrega Tema
    final themeIndex = prefs.getInt('theme_mode') ?? 2; // Default: Automatic
    _themeMode = ViperThemeMode.values[themeIndex];

    // Carrega Operacional/Segurança
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    _isPanicButtonEnabled = prefs.getBool('panic_enabled') ?? false;
    _emergencyContact = prefs.getString('emergency_contact') ?? "";

    _isInit = true;
    notifyListeners();
  }

  Future<void> setNavigationApp(NavigationApp app) async {
    _navigationApp = app;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('navigation_app', app.index);
    notifyListeners();
  }

  Future<void> setThemeMode(ViperThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _isVibrationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', enabled);
    notifyListeners();
  }

  Future<void> setPanicButtonEnabled(bool enabled) async {
    _isPanicButtonEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('panic_enabled', enabled);
    notifyListeners();
  }

  Future<void> setEmergencyContact(String contact) async {
    _emergencyContact = contact;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_contact', contact);
    notifyListeners();
  }

  /// Reavalia o tema automático (útil para eventos de resume)
  void reevaluateAutoTheme() {
    if (_themeMode == ViperThemeMode.automatic) {
      notifyListeners();
    }
  }
}
