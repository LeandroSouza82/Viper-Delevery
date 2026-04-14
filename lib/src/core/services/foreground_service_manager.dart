import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    debugPrint('Foreground Service Started');
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // Aqui poderíamos adicionar lógica de envio de localização para o Supabase
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    debugPrint('Foreground Service Destroyed');
  }
}

class ForegroundServiceManager {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'viper_delivery_service',
        channelName: 'Viper Delivery Service',
        channelDescription: 'Mantém o motorista online para receber corridas.',
        channelImportance: NotificationChannelImportance.MAX,
        priority: NotificationPriority.MAX,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        notificationTitle: 'Viper Delivery',
        notificationText: 'Online e Disponível',
        callback: startCallback,
      );
    }
  }

  static Future<bool> stop() async {
    return FlutterForegroundTask.stopService();
  }
}
