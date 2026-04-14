import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

enum NavigationApp { googleMaps, waze }
enum ViperThemeMode { day, night, automatic }

class SettingsController extends ChangeNotifier {
  static final SettingsController _instance = SettingsController._internal();
  factory SettingsController() => _instance;
  SettingsController._internal();

  final _supabase = Supabase.instance.client;
  Timer? _debounce;

  // Existing settings (Local)
  NavigationApp _navigationApp = NavigationApp.googleMaps;
  ViperThemeMode _themeMode = ViperThemeMode.automatic;
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  bool _isPanicButtonEnabled = false;
  String _emergencyContact = "";
  bool _isInit = false;

  // New settings (Supabase)
  bool _destFilterActive = false;
  String _destFilterLocation = "";
  int _destinationUses = 3;
  DateTime _lastReset = DateTime.now();
  bool _acceptsCash = true;
  bool _acceptsDebit = true;
  bool _acceptsCredit = true;
  bool _acceptsPrepaid = true;

  // UI Support
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // Getters
  NavigationApp get navigationApp => _navigationApp;
  ViperThemeMode get themeMode => _themeMode;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get isPanicButtonEnabled => _isPanicButtonEnabled;
  String get emergencyContact => _emergencyContact;
  
  bool get destFilterActive => _destFilterActive;
  String get destFilterLocation => _destFilterLocation;
  int get destinationUses => _destinationUses;
  bool get acceptsCash => _acceptsCash;
  bool get acceptsDebit => _acceptsDebit;
  bool get acceptsCredit => _acceptsCredit;
  bool get acceptsPrepaid => _acceptsPrepaid;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

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
    
    // 1. Load Local Settings (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    _navigationApp = NavigationApp.values[prefs.getInt('navigation_app') ?? 0];
    _themeMode = ViperThemeMode.values[prefs.getInt('theme_mode') ?? 2];
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    _isPanicButtonEnabled = prefs.getBool('panic_enabled') ?? false;
    _emergencyContact = prefs.getString('emergency_contact') ?? "";

    // 2. Load Driver Settings (Supabase)
    await _fetchDriverSettings();

    _isInit = true;
    notifyListeners();
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
        _destFilterActive = data['dest_filter_active'] ?? false;
        _destFilterLocation = data['dest_filter_location'] ?? "";
        _destinationUses = data['destination_uses'] ?? 3;
        _lastReset = DateTime.parse(data['last_reset'] ?? DateTime.now().toIso8601String());
        _acceptsCash = data['accepts_cash'] ?? true;
        _acceptsDebit = data['accepts_debit'] ?? true;
        _acceptsCredit = data['accepts_credit'] ?? true;
        _acceptsPrepaid = data['accepts_prepaid'] ?? true;

        // Reset Diário Check
        final now = DateTime.now();
        if (_lastReset.day != now.day || _lastReset.month != now.month || _lastReset.year != now.year) {
          _destinationUses = 3;
          _lastReset = now;
          await _syncToSupabase();
        }
      } else {
        // Create initial settings if missing
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
        'dest_filter_active': _destFilterActive,
        'dest_filter_location': _destFilterLocation,
        'destination_uses': _destinationUses,
        'last_reset': _lastReset.toIso8601String(),
        'accepts_cash': _acceptsCash,
        'accepts_debit': _acceptsDebit,
        'accepts_credit': _acceptsCredit,
        'accepts_prepaid': _acceptsPrepaid,
      });
    } catch (e) {
      debugPrint('SettingsController Sync Error: $e');
    }
  }

  // --- Mapbox Search (Geocoding) ---
  
  void searchLocation(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final token = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
        final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$token&autocomplete=true&language=pt&country=br&limit=5';
        
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _searchResults = (data['features'] as List).map((f) => {
            'text': f['text'],
            'place_name': f['place_name'],
            'center': f['center'],
          }).toList();
        }
      } catch (e) {
        debugPrint('Mapbox Search Error: $e');
      } finally {
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  void selectLocation(Map<String, dynamic> result) {
    _destFilterLocation = result['text'];
    _searchResults = [];
    notifyListeners();
    _syncToSupabase();
  }

  // --- Setters with Sync ---

  Future<void> setDestFilterActive(bool active) async {
    if (active && _destinationUses <= 0) return; // No more uses today
    
    _destFilterActive = active;
    notifyListeners();
    await _syncToSupabase();
  }

  /// Consome um uso do filtro de destino. 
  /// Deve ser chamado no controller de viagens ao aceitar uma entrega com o filtro ativo.
  Future<bool> consumeDestinationUse() async {
    if (_destFilterActive && _destinationUses > 0) {
      _destinationUses--;
      
      // Se acabarem os usos, desativamos o filtro automaticamente
      if (_destinationUses == 0) {
        _destFilterActive = false;
      }
      
      notifyListeners();
      await _syncToSupabase();
      return true;
    }
    return false;
  }

  Future<void> setAcceptsCash(bool value) async {
    _acceptsCash = value;
    notifyListeners();
    await _syncToSupabase();
  }

  Future<void> setAcceptsDebit(bool value) async {
    _acceptsDebit = value;
    notifyListeners();
    await _syncToSupabase();
  }

  Future<void> setAcceptsCredit(bool value) async {
    _acceptsCredit = value;
    notifyListeners();
    await _syncToSupabase();
  }

  Future<void> setAcceptsPrepaid(bool value) async {
    _acceptsPrepaid = value;
    notifyListeners();
    await _syncToSupabase();
  }

  // --- Existing Setters ---

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

  void reevaluateAutoTheme() {
    if (_themeMode == ViperThemeMode.automatic) {
      notifyListeners();
    }
  }
}
