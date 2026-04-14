import 'dart:async';
import 'package:flutter/material.dart';
import 'package:viper_delivery/src/core/services/foreground_service_manager.dart';
import 'package:viper_delivery/src/core/utils/permission_helper.dart';

enum PillDisplayMode { earnings, mission, rating }

class HomeController extends ChangeNotifier {
  bool isOnline = false;
  
  // Gestão do Comprimido (Pill)
  PillDisplayMode displayMode = PillDisplayMode.earnings;
  Timer? _pillResetTimer;

  void setDisplayMode(PillDisplayMode mode, {bool startTimer = true}) {
    _pillResetTimer?.cancel();
    displayMode = mode;
    notifyListeners();

    // Se mudar para algo que não seja Ganhos, inicia o timer de retorno
    if (startTimer && mode != PillDisplayMode.earnings) {
      _pillResetTimer = Timer(const Duration(seconds: 12), () {
        displayMode = PillDisplayMode.earnings;
        notifyListeners();
      });
    }
  }

  void cycleDisplayMode() {
    switch (displayMode) {
      case PillDisplayMode.earnings:
        setDisplayMode(PillDisplayMode.mission);
        break;
      case PillDisplayMode.mission:
        setDisplayMode(PillDisplayMode.rating);
        break;
      case PillDisplayMode.rating:
        setDisplayMode(PillDisplayMode.earnings, startTimer: false);
        break;
    }
  }

  // Antigo método showEarnings (mantido por compatibilidade temporária se necessário, redirecionando)
  bool get showEarningsInPill => displayMode == PillDisplayMode.earnings;
  void setShowEarnings(bool value) {
    setDisplayMode(value ? PillDisplayMode.earnings : PillDisplayMode.rating);
  }

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
