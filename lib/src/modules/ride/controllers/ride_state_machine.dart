import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/models/ride_model.dart';
import 'package:viper_delivery/src/modules/ride/repositories/ride_repository.dart';
import 'package:viper_delivery/src/modules/home/services/external_navigation_service.dart';
import 'package:viper_delivery/src/modules/map/controllers/map_controller.dart';

/// Máquina de estados do fluxo logístico.
///
/// Gerencia as transições de fase da corrida de forma reativa (GetX).
/// A UI lê [currentState] para decidir o texto/ação dos botões existentes
/// sem alterar o visual dos cards.
enum RideState {
  /// Nenhuma corrida ativa. Motorista aguardando oferta.
  idle,

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

  /// Atualizado pelo HomeController a cada novo evento da stream.
  void updateFromStream(List<RideModel> rides) {
    activeOrders.assignAll(rides);

    if (rides.isEmpty) {
      if (currentState.value != RideState.idle) {
        currentState.value = RideState.idle;
      }
      return;
    }

    final hasPendingOrAssigned = rides.any((r) => r.status == RideStatus.pending || r.status == RideStatus.assigned);
    final isGoingToPickup = rides.any((r) => r.status == RideStatus.goingToPickup);
    final isArrivedAtPickup = rides.any((r) => r.status == RideStatus.arrivedAtPickup);
    final isOnDeliveryRoute = rides.any((r) => r.status == RideStatus.onDeliveryRoute);
    
    final allCompleted = rides.every((r) => 
      r.status == RideStatus.completed || 
      r.status == RideStatus.failed || 
      r.status == RideStatus.returned
    );

    if (allCompleted) {
      if (currentState.value != RideState.routeCompleted) {
        completeRoute();
      }
    } else if (isOnDeliveryRoute) {
      currentState.value = RideState.onDeliveryRoute;
    } else if (isArrivedAtPickup) {
      currentState.value = RideState.arrivedAtPickup;
    } else if (isGoingToPickup) {
      currentState.value = RideState.goingToPickup;
    } else if (hasPendingOrAssigned && currentState.value == RideState.idle) {
      // Aceita implicitamente a oferta se caiu na conta
      currentState.value = RideState.goingToPickup;
      onPickupRouteReady?.call();
    }
  }

  /// Remove a corrida da tela instantaneamente via update no banco.
  Future<void> removerCorridaDaTela(String rideId, RideStatus status, {String? motivo}) async {
    // Atualiza otimista
    final index = activeOrders.indexWhere((o) => o.id == rideId);
    if (index != -1) {
      activeOrders[index] = activeOrders[index].copyWith(status: status, failureReason: motivo);
    }
    
    // Atualiza o backend (que por sua vez atualizará a stream)
    await _rideRepository.updateRideStatus(rideId, status, failureReason: motivo);
  }

  // ── Callbacks — injetados pelo integrador (HomeView) ──
  VoidCallback? onPickupRouteReady;
  VoidCallback? onDeliveryRouteReady;
  VoidCallback? onRouteCompleted;

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
    
    // Atualiza o backend para todas as ordens pendentes
    for (var order in activeOrders) {
      if (order.status == RideStatus.pending || order.status == RideStatus.assigned) {
        await _rideRepository.updateRideStatus(order.id, RideStatus.goingToPickup);
      }
    }
  }

  /// [2] IR PARA COLETA → Abre navegador externo (Google Maps / Waze)
  Future<void> navigateToPickup(BuildContext context) async {
    if (activeOrders.isEmpty) return;
    
    final first = activeOrders.first;
    await ExternalNavigationService.abrirNavegador(
      lat: first.lat,
      lng: first.lng,
      context: context,
    );
  }

  /// [3] CHEGUEI NA COLETA → arrivedAtPickup
  Future<void> confirmArrivalAtPickup() async {
    currentState.value = RideState.arrivedAtPickup;

    // Atualiza status de todos indo para coleta
    for (var order in activeOrders) {
      if (order.status == RideStatus.goingToPickup) {
        await _rideRepository.updateRideStatus(order.id, RideStatus.arrivedAtPickup);
      }
    }
    
    _dispatchPickupNotification();
  }

  /// [4] SEGUIR ROTA → onDeliveryRoute
  Future<List<RideModel>> startDeliveryRoute(List<RideModel> pendingOrders) async {
    if (activeOrders.isEmpty) return pendingOrders;

    currentState.value = RideState.onDeliveryRoute;

    final mapController = Get.find<MapController>();
    final optimized = await mapController.optimizeAndTraceDeliveries(
      pickupLat: activeOrders.first.lat,
      pickupLng: activeOrders.first.lng,
      orders: pendingOrders,
    );

    onDeliveryRouteReady?.call();
    
    // Atualiza status de todos no ponto de coleta para rota
    for (var order in activeOrders) {
      if (order.status == RideStatus.arrivedAtPickup) {
        await _rideRepository.updateRideStatus(order.id, RideStatus.onDeliveryRoute);
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

  /// Mock de webhook/push notification para o painel do gestor.
  void _dispatchPickupNotification() {
    if (activeOrders.isEmpty) return;

    // TODO: Substituir por chamada real ao Supabase Edge Function / API
  }
}
