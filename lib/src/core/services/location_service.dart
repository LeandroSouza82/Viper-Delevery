import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Verifica e solicita permissões de localização de forma rigorosa
  static Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verificar se o serviço de GPS do hardware está ligado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[!!! VIPER !!!] GPS do dispositivo desativado.');
      return false;
    }

    // 2. Verificar permissão atual
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Solicitar permissão pela primeira vez
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[!!! VIPER !!!] Permissão de GPS negada pelo usuário.');
        return false;
      }
    }
    
    // 3. Caso o usuário tenha negado permanentemente
    if (permission == LocationPermission.deniedForever) {
      debugPrint('[!!! VIPER !!!] Permissão de GPS negada permanentemente nas configurações.');
      return false;
    } 

    return true;
  }

  /// Obtém a localização atual do dispositivo (Latitude e Longitude reais)
  /// Retorna null se não houver permissão ou ocorrer falha, evitando crash.
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      // Usando precisão alta para operações logísticas
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('[!!! VIPER !!!] Falha graciosa na captura do GPS: $e');
      return null;
    }
  }
}

