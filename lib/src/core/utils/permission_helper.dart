import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionHelper {
  static Future<void> showExplanationDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDI'),
          ),
        ],
      ),
    );
  }

  static Future<bool> requestResilientPermissions(BuildContext context) async {
    // 1. Localização (Foreground)
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await showExplanationDialog(
        context,
        title: 'Uso da Localização',
        message: 'Precisamos acessar sua localização para mostrar motoristas próximos e calcular rotas.',
      );
      status = await Permission.location.request();
      if (!status.isGranted) return false;
    }

    // 2. Notificações (Android 13+)
    var notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      await showExplanationDialog(
        context,
        title: 'Notificações',
        message: 'Ative as notificações para receber alertas de novas corridas em tempo real.',
      );
      notificationStatus = await Permission.notification.request();
    }

    // 3. Localização (Background) - "Sempre permitir"
    if (await Permission.location.isGranted) {
      var bgStatus = await Permission.locationAlways.status;
      if (!bgStatus.isGranted) {
        await showExplanationDialog(
          context,
          title: 'Localização em Segundo Plano',
          message: 'Selecione "Permitir o tempo todo" na próxima tela. Isso permite que você receba corridas mesmo com o app minimizado ou tela apagada.',
        );
        bgStatus = await Permission.locationAlways.request();
      }
    }

    // 4. Otimização de Bateria
    var batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      await showExplanationDialog(
        context,
        title: 'Desempenho da Bateria',
        message: 'Para garantir que o app não seja suspenso pelo sistema, desative a otimização de bateria para o Viper Delivery.',
      );
      await Permission.ignoreBatteryOptimizations.request();
    }

    return true;
  }
}
