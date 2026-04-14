import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

class SOSEmergencyButton extends StatelessWidget {
  final SettingsController settingsController;

  const SOSEmergencyButton({
    super.key,
    required this.settingsController,
  });

  Future<void> _launchSOS() async {
    // Vibração tátil para confirmar a intenção do motorista
    await HapticFeedback.vibrate();

    final Uri telLaunchUri = Uri(
      scheme: 'tel',
      path: '190',
    );

    try {
      if (await canLaunchUrl(telLaunchUri)) {
        await launchUrl(telLaunchUri);
      } else {
        debugPrint('Não foi possível abrir o discador para o número 190');
      }
    } catch (e) {
      debugPrint('Erro ao tentar disparar SOS: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, child) {
        final isDark = settingsController.isDarkTheme;
        
        // Cores baseadas no padrão modular da Viper
        final bgColor = isDark 
            ? Colors.black.withValues(alpha: 0.7) 
            : Colors.white;
        const iconColor = Colors.red; // Vermelho Vivo para Alerta
        final borderColor = isDark ? Colors.red.withValues(alpha: 0.3) : Colors.black;

        return GestureDetector(
          onLongPress: _launchSOS,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: iconColor,
              size: 26,
            ),
          ),
        );
      },
    );
  }
}
