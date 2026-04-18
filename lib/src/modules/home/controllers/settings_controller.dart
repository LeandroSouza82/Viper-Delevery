import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:viper_delivery/src/core/services/haptic_service.dart';
import 'package:vibration/vibration.dart';
import 'package:viper_delivery/src/core/config/env.dart';

enum NavigationApp { googleMaps, waze }
enum ViperThemeMode { day, night, automatic }

class SettingsController extends GetxController {
  // Singleton para compatibilidade legada
  static final SettingsController _instance = SettingsController._internal();
  factory SettingsController() => _instance;
  SettingsController._internal();

  final _supabase = Supabase.instance.client;
  Timer? _debounce;

  // Estados Reativos (GetX)
  final navigationApp = NavigationApp.googleMaps.obs;
  final themeMode = ViperThemeMode.automatic.obs;
  final isSoundEnabled = true.obs;
  final vibrationEnabled = true.obs;
  final isPanicButtonEnabled = false.obs;
  final emergencyContact = "".obs;
  
  final destFilterActive = false.obs;
  final destFilterLocation = "".obs;
  final destinationUses = 3.obs;
  final lastReset = DateTime.now().obs;
  
  final acceptsCash = true.obs;
  final acceptsDebit = true.obs;
  final acceptsCredit = true.obs;
  final acceptsPrepaid = true.obs;

  // Getters para compatibilidade legada
  NavigationApp get navApp => navigationApp.value;
  ViperThemeMode get currentTheme => themeMode.value;
  bool get isSoundEnabledVal => isSoundEnabled.value;
  bool get isVibrationEnabled => vibrationEnabled.value;
  bool get isPanicButtonEnabledVal => isPanicButtonEnabled.value;
  String get currentEmergencyContact => emergencyContact.value;
  
  bool get destFilterActiveVal => destFilterActive.value;
  String get destFilterLocationVal => destFilterLocation.value;
  int get destinationUsesVal => destinationUses.value;
  bool get acceptsCashVal => acceptsCash.value;
  bool get acceptsDebitVal => acceptsDebit.value;
  bool get acceptsCreditVal => acceptsCredit.value;
  bool get acceptsPrepaidVal => acceptsPrepaid.value;

  // UI Support
  final searchResults = <Map<String, dynamic>>[].obs;
  final isSearching = false.obs;
  bool _isInit = false;

  /// Retorna o estilo do mapa baseado na configuração atual e horário
  String get mapStyle {
    if (themeMode.value == ViperThemeMode.day) return MapboxStyles.MAPBOX_STREETS;
    if (themeMode.value == ViperThemeMode.night) return MapboxStyles.DARK;
    
    final hour = DateTime.now().hour;
    return (hour >= 6 && hour < 18) ? MapboxStyles.MAPBOX_STREETS : MapboxStyles.DARK;
  }

  bool get isDarkTheme => mapStyle == MapboxStyles.DARK;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    if (_isInit) return;
    
    // 1. Load Local Settings (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    navigationApp.value = NavigationApp.values[prefs.getInt('navigation_app') ?? 0];
    themeMode.value = ViperThemeMode.values[prefs.getInt('theme_mode') ?? 2];
    isSoundEnabled.value = prefs.getBool('sound_enabled') ?? true;
    vibrationEnabled.value = prefs.getBool('vibration_enabled') ?? true;
    isPanicButtonEnabled.value = prefs.getBool('panic_enabled') ?? false;
    emergencyContact.value = prefs.getString('emergency_contact') ?? "";

    // 2. Load Driver Settings (Supabase)
    await _fetchDriverSettings();

    _isInit = true;
  }

  Future<void> _fetchDriverSettings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('driver_settings')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        destFilterActive.value = data['dest_filter_active'] ?? false;
        destFilterLocation.value = data['dest_filter_location'] ?? "";
        destinationUses.value = data['destination_uses'] ?? 3;
        lastReset.value = DateTime.parse(data['last_reset'] ?? DateTime.now().toIso8601String());
        acceptsCash.value = data['accepts_cash'] ?? true;
        acceptsDebit.value = data['accepts_debit'] ?? true;
        acceptsCredit.value = data['accepts_credit'] ?? true;
        acceptsPrepaid.value = data['accepts_prepaid'] ?? true;
        vibrationEnabled.value = data['vibration_enabled'] ?? true;

        // Reset Diário Check
        final now = DateTime.now();
        if (lastReset.value.day != now.day || lastReset.value.month != now.month || lastReset.value.year != now.year) {
          destinationUses.value = 3;
          lastReset.value = now;
          await _syncToSupabase();
        }
      } else {
        await _syncToSupabase();
      }
    } catch (e) {
      debugPrint('SettingsController Fetch Error: $e');
    }
  }

  Future<void> _syncToSupabase() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('driver_settings').upsert({
        'id': user.id,
        'dest_filter_active': destFilterActive.value,
        'dest_filter_location': destFilterLocation.value,
        'destination_uses': destinationUses.value,
        'last_reset': lastReset.value.toIso8601String(),
        'accepts_cash': acceptsCash.value,
        'accepts_debit': acceptsDebit.value,
        'accepts_credit': acceptsCredit.value,
        'accepts_prepaid': acceptsPrepaid.value,
        'vibration_enabled': vibrationEnabled.value,
      });
    } catch (e) {
      debugPrint('SettingsController Sync Error: $e');
    }
  }

  // --- Chave Geral de Vibração ---

  Future<void> toggleVibration(bool value) async {
    vibrationEnabled.value = value;
    
    // Feedback tátil ao ligar
    if (value) {
      HapticService.vibrateViperPulse();
    } else {
      Vibration.cancel(); // Silêncio total ao desligar
    }

    // Persistência local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);

    // Persistência remota
    await _syncToSupabase();
    
    update();
  }

  // --- Setters Reativos ---

  void searchLocation(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.isEmpty) {
      searchResults.value = [];
      isSearching.value = false;
      return;
    }

    isSearching.value = true;
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final token = Env.mapboxPublicToken;
        final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$token&autocomplete=true&language=pt&country=br&limit=5';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          searchResults.value = (data['features'] as List).map((f) => {
            'text': f['text'],
            'place_name': f['place_name'],
            'center': f['center'],
          }).toList();
        }
      } catch (e) {
        debugPrint('Mapbox Search Error: $e');
      } finally {
        isSearching.value = false;
      }
    });
  }

  void selectLocation(Map<String, dynamic> result) {
    destFilterLocation.value = result['text'];
    searchResults.value = [];
    _syncToSupabase();
  }

  Future<void> setDestFilterActive(bool active) async {
    if (active && destinationUses.value <= 0) return;
    destFilterActive.value = active;
    await _syncToSupabase();
    update();
  }

  Future<bool> consumeDestinationUse() async {
    if (destFilterActive.value && destinationUses.value > 0) {
      destinationUses.value--;
      if (destinationUses.value == 0) destFilterActive.value = false;
      await _syncToSupabase();
      update();
      return true;
    }
    return false;
  }

  Future<void> setAcceptsCash(bool value) async {
    acceptsCash.value = value;
    await _syncToSupabase();
    update();
  }

  Future<void> setAcceptsDebit(bool value) async {
    acceptsDebit.value = value;
    await _syncToSupabase();
    update();
  }

  Future<void> setAcceptsCredit(bool value) async {
    acceptsCredit.value = value;
    await _syncToSupabase();
    update();
  }

  Future<void> setAcceptsPrepaid(bool value) async {
    acceptsPrepaid.value = value;
    await _syncToSupabase();
    update();
  }

  Future<void> setNavigationApp(NavigationApp app) async {
    navigationApp.value = app;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('navigation_app', app.index);
    update();
  }

  Future<void> setThemeMode(ViperThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    update();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    isSoundEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
    update();
  }

  Future<void> setPanicButtonEnabled(bool enabled) async {
    isPanicButtonEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('panic_enabled', enabled);
    update();
  }

  Future<void> setEmergencyContact(String contact) async {
    emergencyContact.value = contact;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_contact', contact);
    update();
  }

  void reevaluateAutoTheme() {
    if (themeMode.value == ViperThemeMode.automatic) {
      update(); // Força atualização para listeners manuais se necessário
    }
  }
}
