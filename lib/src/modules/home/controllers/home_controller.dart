import 'package:flutter/material.dart';
import 'package:viper_delivery/src/core/services/foreground_service_manager.dart';
import 'package:viper_delivery/src/core/utils/permission_helper.dart';

class HomeController extends ChangeNotifier {
  bool isOnline = false;

  Future<void> startViperService(BuildContext context) async {
    final granted = await PermissionHelper.requestResilientPermissions(context);
    if (granted) {
      await ForegroundServiceManager.start();
      isOnline = true;
      notifyListeners();
    }
  }

  Future<void> stopViperService() async {
    await ForegroundServiceManager.stop();
    isOnline = false;
    notifyListeners();
  }

  Future<void> toggleOnlineStatus(BuildContext context) async {
    if (isOnline) {
      await stopViperService();
    } else {
      await startViperService(context);
    }
  }

  Future<void> initializeResilience(BuildContext context) async {
    // Apenas verifica permissões iniciais sem iniciar o serviço automaticamente
    await PermissionHelper.requestResilientPermissions(context);
  }
}
