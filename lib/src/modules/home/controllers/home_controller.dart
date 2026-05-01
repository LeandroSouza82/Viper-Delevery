import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/core/services/foreground_service_manager.dart';
import 'package:viper_delivery/src/core/services/security_service.dart';
import 'package:viper_delivery/src/core/utils/permission_helper.dart';
import 'package:viper_delivery/src/models/driver_model.dart';
import 'package:viper_delivery/src/models/ride_model.dart';
import 'package:viper_delivery/src/modules/ride/controllers/ride_state_machine.dart';
import 'package:viper_delivery/src/modules/ride/repositories/ride_repository.dart';

enum PillDisplayMode { earnings, mission, rating }

class HomeController extends GetxController {
  final isOnline = false.obs;
  final driverProfile = Rxn<DriverModel>();
  final currentPosition = Rxn<Position>();

  bool get isClt => driverProfile.value?.isClt ?? false;
  bool get isCompanyDriver => driverProfile.value?.isCompanyDriver ?? false;

  // Real Rides Stream
  final realRides = <RideModel>[].obs;
  StreamSubscription? _ridesSubscription;
  final RideRepository _rideRepository = RideRepository();

  // Gestão do Comprimido (Pill)
  final displayMode = PillDisplayMode.earnings.obs;
  Timer? _pillResetTimer;

  void setDisplayMode(PillDisplayMode mode, {bool startTimer = true}) {
    _pillResetTimer?.cancel();
    displayMode.value = mode;
    update();

    // Se mudar para algo que não seja Missão/Rating (conforme o caso), inicia o timer de retorno
    final defaultMode = isCompanyDriver ? PillDisplayMode.mission : PillDisplayMode.earnings;
    if (startTimer && mode != defaultMode) {
      _pillResetTimer = Timer(const Duration(seconds: 12), () {
        displayMode.value = defaultMode;
        update();
      });
    }
  }

  void cycleDisplayMode() {
    switch (displayMode.value) {
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
  bool get showEarningsInPill => displayMode.value == PillDisplayMode.earnings;
  void setShowEarnings(bool value) {
    setDisplayMode(value ? PillDisplayMode.earnings : PillDisplayMode.rating);
  }

  Future<void> startViperService(BuildContext context) async {
    // [VUP PROTECT] Inicia verificação de integridade antes de permitir 'Online'
    final isSecure = await SecurityService.verifyDevice();
    if (!context.mounted) return;
    if (!isSecure) {
      return; // Bloqueia operação se o dispositivo estiver comprometido
    }

    final granted = await PermissionHelper.requestResilientPermissions(context);
    if (!context.mounted) return;
    if (granted) {
      await ForegroundServiceManager.start();
      isOnline.value = true;
      update();
    }
  }

  Future<void> stopViperService() async {
    await ForegroundServiceManager.stop();
    isOnline.value = false;
    _ridesSubscription?.cancel();
    update();
  }

  Future<void> toggleOnlineStatus(BuildContext context) async {
    if (isOnline.value) {
      await stopViperService();
    } else {
      await startViperService(context);
    }
  }

  Future<void> initializeResilience(BuildContext context) async {
    // Apenas verifica permissões iniciais sem iniciar o serviço automaticamente
    await PermissionHelper.requestResilientPermissions(context);

    // Buscar perfil do motorista para flags como isClt
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .single();
        driverProfile.value = DriverModel.fromMap(response);
        
        // Ajuste de UI inicial para Frotistas
        if (isCompanyDriver) {
          displayMode.value = PillDisplayMode.mission;
        }

        update();

        // Inicia o listener de corridas em real-time se já logado
        listenRides(user.id);
      }
    } catch (e) {
      debugPrint('Error fetching profile in HomeController: $e');
    }
  }

  /// Inicia o ouvinte em tempo real para as corridas do motorista.
  ///
  /// Sempre que o banco de dados for alterado (inserção, atualização, deleção),
  /// a stream envia a nova lista. O `HomeController` atualiza sua lista local (`realRides`)
  /// e, o mais importante, injeta esses novos dados na `RideStateMachine`.
  /// A `RideStateMachine` é a verdadeira orquestradora da interface (via GetX):
  /// ao receber novos dados, ela recalcula a fase da corrida (ex: goingToPickup)
  /// e aciona as transições de tela automaticamente.
  void listenRides(String driverId) {
    _ridesSubscription?.cancel();
    _ridesSubscription = _rideRepository
        .getMyRidesStream(driverId)
        .listen(
          (rides) async {
            // [VUP MODULAR] Obtém localização atual para filtro geográfico
            Position? currentPos;
            try {
              currentPos = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 3),
                ),
              );
              currentPosition.value = currentPos;
            } catch (e) {
              debugPrint('Erro ao obter localização para filtro: $e');
            }

            // Aplica filtro de raio (5km) rigoroso
            final filteredRides = rides.where((r) {
              // Se a corrida já está atribuída a este motorista, ela deve aparecer independente da distância
              if (r.driverId == driverId && r.status != RideStatus.searching) {
                return true;
              }

              // Se a corrida está em 'searching' (Radar), filtramos pelo raio de 5km
              if (currentPos != null) {
                final distance = Geolocator.distanceBetween(
                  currentPos.latitude,
                  currentPos.longitude,
                  r.pickupLat,
                  r.pickupLng,
                );
                return distance <= 5000; // 5000 metros = 5km
              }

              // Fallback: se não tiver GPS, por segurança não exibe radar genérico
              return false;
            }).toList();

            realRides.assignAll(filteredRides);
            update();

            // Atualiza a RideStateMachine com as corridas filtradas
            try {
              final stateMachine = Get.find<RideStateMachine>();
              stateMachine.updateFromStream(filteredRides);
            } catch (e) {
              // Ignora caso a máquina de estados ainda não tenha sido inicializada
            }
          },
          onError: (e) {
            // Falha silenciosa no stream
          },
        );
  }

  @override
  void dispose() {
    _ridesSubscription?.cancel();
    super.dispose();
  }
}

