import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:viper_delivery/src/models/ride_model.dart';
import 'package:viper_delivery/src/modules/home/controllers/home_controller.dart';
import 'package:viper_delivery/src/modules/home/services/external_navigation_service.dart';
import 'package:viper_delivery/src/modules/map/controllers/map_controller.dart';
import 'package:viper_delivery/src/modules/ride/repositories/ride_repository.dart';

/// Máquina de estados do fluxo logístico.
///
/// Gerencia as transições de fase da corrida de forma reativa (GetX).
/// A UI lê [currentState] para decidir o texto/ação dos botões existentes
/// sem alterar o visual dos cards.
enum RideState {
  /// Nenhuma corrida ativa. Motorista aguardando oferta.
  idle,

  /// Oferta recebida. Aguardando aceite do motorista (Card de Convite).
  offerReceived,

  /// Oferta aceita. Motorista indo para o ponto de coleta.
  goingToPickup,

  /// Motorista chegou no ponto de coleta. Aguardando confirmação.
  arrivedAtPickup,

  /// Coleta confirmada. Motorista seguindo a rota de entregas.
  onDeliveryRoute,

  /// Todas as entregas finalizadas (sucesso ou falha).
  routeCompleted,
}

/// Extensão para dados visuais de cada estado (texto do botão principal).
extension RideStateUI on RideState {
  String get buttonLabel {
    switch (this) {
      case RideState.idle:
        return 'AGUARDANDO';
      case RideState.offerReceived:
        return 'NOVA OFERTA';
      case RideState.goingToPickup:
        return 'IR PARA COLETA';
      case RideState.arrivedAtPickup:
        return 'CHEGUEI NA COLETA';
      case RideState.onDeliveryRoute:
        return 'SEGUIR ROTA';
      case RideState.routeCompleted:
        return 'FINALIZADO';
    }
  }

  IconData get buttonIcon {
    switch (this) {
      case RideState.idle:
        return Icons.hourglass_empty;
      case RideState.offerReceived:
        return Icons.local_shipping;
      case RideState.goingToPickup:
        return Icons.navigation;
      case RideState.arrivedAtPickup:
        return Icons.flag;
      case RideState.onDeliveryRoute:
        return Icons.route;
      case RideState.routeCompleted:
        return Icons.check_circle;
    }
  }

  Color get buttonColor {
    switch (this) {
      case RideState.idle:
        return Colors.grey;
      case RideState.offerReceived:
        return const Color(0xFF00C853); // Verde Viper
      case RideState.goingToPickup:
        return const Color(0xFF9C27B0); // Roxo
      case RideState.arrivedAtPickup:
        return Colors.orange;
      case RideState.onDeliveryRoute:
        return const Color(0xFF0055FF); // Azul Viper
      case RideState.routeCompleted:
        return const Color(0xFF00C853); // Verde
    }
  }
}

/// Controlador reativo (GetX) da máquina de estados da corrida.
///
/// Cada transição dispara side-effects (mapa, navegação, notificação)
/// sem acoplar à UI. A UI apenas observa [currentState].
class RideStateMachine extends GetxController {
  final currentState = RideState.idle.obs;
  final activeOrders = <RideModel>[].obs; // LISTA REATIVA GLOBAL
  final RideRepository _rideRepository = RideRepository();

  // ── Callbacks — injetados pelo integrador (HomeView) ──
  VoidCallback? onOfferReceived;
  VoidCallback? onPickupRouteReady;
  VoidCallback? onDeliveryRouteReady;
  VoidCallback? onRouteCompleted;

  /// Atualizado pelo HomeController a cada novo evento da stream.
  void updateFromStream(List<RideModel> rides) async {
    // 1. Identificar novas corridas para lógica de Frotista (Silent Assignment)
    final existingIds = activeOrders.map((r) => r.id).toSet();
    final newRides = rides.where((r) => !existingIds.contains(r.id)).toList();
    
    activeOrders.assignAll(rides);

    if (rides.isEmpty) {
      if (currentState.value != RideState.idle) {
        currentState.value = RideState.idle;
      }
      return;
    }

    // 2. Lógica Especial: Frotista (isCompanyDriver)
    // Se houver novas corridas e for frotista, processamos silenciosamente
    try {
      final isRegistered = Get.isRegistered<HomeController>();
      if (isRegistered) {
        final homeController = Get.find<HomeController>();
        if (homeController.isCompanyDriver && newRides.isNotEmpty) {
          debugPrint('>>> [VUP SILENT] Novas rotas detectadas para Frotista. Processando...');
          
          // Alerta Sonoro e Vibratório (Beep Curto + Haptic)
          SystemSound.play(SystemSoundType.click);
          Vibration.vibrate(duration: 100);

          // Notificação Visual (Mini-Card / Toast)
          _showSilentNotification(newRides.first);

          // Integração Automática: Reordenar Rota (Vizinho Mais Próximo)
          if (currentState.value == RideState.onDeliveryRoute || currentState.value == RideState.goingToPickup) {
            final mapController = Get.find<MapController>();
            final first = rides.first;
            final optimized = await mapController.optimizeAndTraceDeliveries(
              pickupLat: first.pickupLat,
              pickupLng: first.pickupLng,
              orders: rides,
            );
            activeOrders.assignAll(optimized);
          } else if (currentState.value == RideState.idle || currentState.value == RideState.offerReceived) {
            // Se estava parado, aceita a oferta automaticamente
            final first = rides.first;
            acceptOffer(first.lat.toString(), first.lng.toString());
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao processar silent assignment: $e');
    }

    final hasAssignedOrSearching = rides.any(
      (r) => r.status == RideStatus.assigned || r.status == RideStatus.searching,
    );
    final isGoingToPickup = rides.any(
      (r) => r.status == RideStatus.goingToPickup,
    );
    final isArrivedAtPickup = rides.any(
      (r) => r.status == RideStatus.arrivedAtPickup,
    );
    final isOnDeliveryRoute = rides.any(
      (r) => r.status == RideStatus.onDeliveryRoute,
    );
    final isReturnedOrCompleted = rides.every(
      (r) =>
          r.status == RideStatus.completed ||
          r.status == RideStatus.failed ||
          r.status == RideStatus.returned,
    );

    if (isReturnedOrCompleted) {
      if (currentState.value != RideState.routeCompleted) {
        completeRoute();
      }
    } else if (isOnDeliveryRoute) {
      currentState.value = RideState.onDeliveryRoute;
    } else if (isArrivedAtPickup) {
      currentState.value = RideState.arrivedAtPickup;
    } else if (isGoingToPickup) {
      currentState.value = RideState.goingToPickup;
    } else if (hasAssignedOrSearching && currentState.value == RideState.idle) {
      // CONVITE: Entra em modo oferta em vez de ir direto para coleta
      final isRegistered = Get.isRegistered<HomeController>();
      if (isRegistered) {
        final homeController = Get.find<HomeController>();
        if (!homeController.isCompanyDriver) {
          currentState.value = RideState.offerReceived;
          onOfferReceived?.call();
        }
      }
    }
  }

  void _showSilentNotification(RideModel ride) {
    Get.snackbar(
      'NOVA ROTA!',
      'Nova rota adicionada automaticamente ao seu trajeto!',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF0055FF),
      colorText: Colors.white,
      icon: const Icon(Icons.local_shipping, color: Colors.white),
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(15),
      borderRadius: 12,
      mainButton: TextButton(
        onPressed: () => Get.back(),
        child: const Icon(Icons.close, color: Colors.white),
      ),
      isDismissible: true,
      shouldIconPulse: true,
      barBlur: 10,
    );
  }

  /// Remove a corrida da tela instantaneamente via update no banco.
  Future<void> removerCorridaDaTela(
    String rideId,
    RideStatus status, {
    String? motivo,
  }) async {
    // Atualiza otimista
    final index = activeOrders.indexWhere((o) => o.id == rideId);
    if (index != -1) {
      activeOrders[index] = activeOrders[index].copyWith(
        status: status,
        failureReason: motivo,
      );
    }

    // Atualiza o backend (que por sua vez atualizará a stream)
    await _rideRepository.updateRideStatus(
      rideId,
      status,
      failureReason: motivo,
    );
  }


  // ═══════════════════════════════════════════
  // ██  TRANSIÇÕES DE ESTADO
  // ═══════════════════════════════════════════

  /// [1] ACEITAR OFERTA → goingToPickup
  Future<void> acceptOffer(String firstRideLat, String firstRideLng) async {
    currentState.value = RideState.goingToPickup;

    // Side-effect: traçar rota até a coleta (Fase 1)
    final mapController = Get.find<MapController>();
    mapController.traceRouteToPickup(
      pickupLat: double.tryParse(firstRideLat) ?? 0.0,
      pickupLng: double.tryParse(firstRideLng) ?? 0.0,
    );

    onPickupRouteReady?.call();

    // Atualiza o backend para todas as ordens atribuídas ou em busca
    for (var order in activeOrders) {
      if (order.status == RideStatus.assigned || order.status == RideStatus.searching) {
        await _rideRepository.updateRideStatus(
          order.id,
          RideStatus.goingToPickup,
        );
      }
    }
  }

  /// [1.5] RECUSAR OFERTA → Volta para idle e limpa a tela localmente
  Future<void> rejectOffer() async {
    // [VUP MODULAR] Notificar Supabase sobre recusa
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      if (userId != null && activeOrders.isNotEmpty) {
        final ids = activeOrders.map((o) => o.id).toList();
        await _rideRepository.rejectRides(ids, userId);
      }
    } catch (e) {
      debugPrint('Erro ao notificar recusa: $e');
    }
    
    activeOrders.clear();
    reset();
  }

  /// [2] IR PARA COLETA → Abre navegador externo (Google Maps / Waze)
  Future<void> navigateToPickup(BuildContext context) async {
    if (activeOrders.isEmpty) return;

    final first = activeOrders.first;
    await ExternalNavigationService.abrirNavegador(
      lat: first.lat,
      lng: first.lng,
      context: context,
      address: first.pickupAddress,
    );
  }

  /// [3] CHEGUEI NA COLETA → arrivedAtPickup
  Future<void> confirmArrivalAtPickup() async {
    currentState.value = RideState.arrivedAtPickup;

    // Atualiza status de todos indo para coleta
    for (var order in activeOrders) {
      if (order.status == RideStatus.goingToPickup) {
        await _rideRepository.updateRideStatus(
          order.id,
          RideStatus.arrivedAtPickup,
        );
      }
    }

    _dispatchPickupNotification();
  }

  /// [4] SEGUIR ROTA → onDeliveryRoute
  Future<List<RideModel>> startDeliveryRoute(
    List<RideModel> pendingOrders,
  ) async {
    if (activeOrders.isEmpty) return pendingOrders;

    currentState.value = RideState.onDeliveryRoute;

    final mapController = Get.find<MapController>();
    await mapController.optimizeAndTraceDeliveries(
      pickupLat: activeOrders.first.lat,
      pickupLng: activeOrders.first.lng,
      orders: pendingOrders,
    );

    onDeliveryRouteReady?.call();

    // Atualiza status de todos no ponto de coleta para rota
    for (var order in activeOrders) {
      if (order.status == RideStatus.arrivedAtPickup) {
        await _rideRepository.updateRideStatus(
          order.id,
          RideStatus.onDeliveryRoute,
        );
      }
    }

    return pendingOrders; // Retorna pendingOrders pois optimizeAndTraceDeliveries pode usar outra modelagem
  }

  /// [5] ROTA FINALIZADA → routeCompleted / idle
  void completeRoute() {
    currentState.value = RideState.routeCompleted;

    onRouteCompleted?.call();
  }

  /// Reseta a máquina para o estado inicial.
  void reset() {
    currentState.value = RideState.idle;

    final mapController = Get.find<MapController>();
    mapController.clearRoute();
  }

  // ── Internos ──

  /// Webhook/push notification para o painel do gestor via Edge Function.
  Future<void> _dispatchPickupNotification() async {
    if (activeOrders.isEmpty) return;

    try {
      // [VUP SENIOR] Chamada real ao Supabase Edge Function para notificar chegada na coleta
      // Isso dispara o push para o lojista preparar os pacotes.
      final first = activeOrders.first;
      await Supabase.instance.client.functions.invoke(
        'notify-pickup-arrival',
        body: {
          'driver_id': first.driverId,
          'ride_ids': activeOrders.map((o) => o.id).toList(),
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
      debugPrint('>>> [EDGE] Notificação de coleta enviada com sucesso.');
    } catch (e) {
      debugPrint('>>> [EDGE] Falha ao notificar coleta (Edge Function): $e');
      // Não rethrow para não travar o fluxo do motorista se a notificação falhar
    }
  }
}

