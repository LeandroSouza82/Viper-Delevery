import 'package:vibration/vibration.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

/// Serviço tático para feedback háptico premium (Viper Sensation)
class HapticService {
  static SettingsController get settingsController => Get.find<SettingsController>();
  static bool _isEmergencyActive = false;

  /// Padrão 'Viper Pulse': Pulso forte seguido de pulso fraco.
  /// Ideal para aberturas de modais e confirmações críticas.
  static Future<void> vibrateViperPulse() async {
    // A TRAVA MESTRA: Se estiver desligado nos ajustes, o código morre aqui.
    if (!settingsController.vibrationEnabled.value) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        print('📳 [HAPTIC] Viper Pulse disparado');
        // Padrão pulso duplo (batimento cardíaco): [Espera, Forte, Pausa, Curto]
        await Vibration.vibrate(
          pattern: [0, 100, 50, 60],
          intensities: [0, 255, 0, 150],
        );
      }
    } catch (e) {
      // Falha silenciosa em caso de erro de hardware ou emulador
    }
  }

  /// Padrão 'Viper Close': Pulso simples, curto e suave para fechamentos.
  static Future<void> vibrateViperClose() async {
    if (!settingsController.vibrationEnabled.value) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 30, amplitude: 50);
      }
    } catch (e) {
      // Falha silenciosa
    }
  }

  /// Padrão 'Warning': Três pulsos rápidos para erros ou notificações importantes.
  static Future<void> vibrateWarning() async {
    if (!settingsController.vibrationEnabled.value) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
      }
    } catch (e) {
      // Falha silenciosa
    }
  }

  /// Padrão 'Viper Emergency': Ciclo de 12 segundos com efeito 'Vai e Vem' (Onda).
  /// Ideal para SOS ou Alertas de Nova Oferta Urgente.
  static Future<void> vibrateViperEmergency() async {
    if (!settingsController.vibrationEnabled.value) return;

    if (_isEmergencyActive) return; // Evita múltiplas instâncias
    _isEmergencyActive = true;

    print('🚨 [SOS] Iniciando ciclo de 12s de vibração');

    try {
      if (await Vibration.hasVibrator() ?? false) {
        for (int i = 0; i < 12; i++) {
          if (!_isEmergencyActive || !settingsController.vibrationEnabled.value) break;

          // Ciclo de 1 segundo: [Espera, Sobe (500ms), Pausa (100ms), Desce (400ms)]
          Vibration.vibrate(
            pattern: [0, 500, 100, 400],
            intensities: [0, 255, 0, 100],
          );

          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
    } catch (e) {
      print('❌ [HAPTIC] Erro na vibração de emergência: $e');
    } finally {
      _isEmergencyActive = false;
    }
  }

  /// Interrompe qualquer vibração ativa imediatamente.
  static void stopVibration() {
    _isEmergencyActive = false;
    Vibration.cancel();
    print('📳 [HAPTIC] Vibração interrompida manualmente');
  }
}
