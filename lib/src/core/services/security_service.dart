import 'package:flutter/material.dart';
import 'package:safe_device/safe_device.dart';
import 'package:get/get.dart';

/// Serviço de Segurança VUP PROTECT 🛡️
/// Focado em integridade do dispositivo e prevenção de fraudes.
class SecurityService extends GetxService {
  
  /// Realiza o 'Trust Check' no dispositivo.
  /// Verifica Root, Simuladores e Mock Location (Fake GPS).
  static Future<bool> verifyDevice() async {
    try {
      bool isJailBroken = await SafeDevice.isJailBroken;
      bool isRealDevice = await SafeDevice.isRealDevice;
      bool isMockLocation = await SafeDevice.isMockLocation;
      bool isDevelopmentMode = await SafeDevice.isDevelopmentModeEnable;

      debugPrint('🛡️ [VUP PROTECT] Jailbroken: $isJailBroken, Real: $isRealDevice, Mock: $isMockLocation, DevMode: $isDevelopmentMode');

      if (isJailBroken || !isRealDevice || isMockLocation) {
        _showSecurityAlert(
          title: 'Dispositivo Comprometido',
          message: 'Detectamos irregularidades na integridade do seu dispositivo (Root, Emulador ou Mock Location). Por segurança, o acesso ao cockpit foi bloqueado.',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('🛡️ [VUP PROTECT] Erro ao verificar segurança: $e');
      return false; 
    }
  }

  /// Alerta tático de segurança
  static void _showSecurityAlert({required String title, required String message}) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('ENTENDIDO', style: TextStyle(color: Color(0xFF0055FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
