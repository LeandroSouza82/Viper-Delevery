import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
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
  final activeOrders = <ViperOrder>[].obs; // LISTA REATIVA GLOBAL
  final _activeOffer = Rxn<ViperOffer>();

  /// Remove a corrida da tela instantaneamente e verifica se a rota acabou.
  void removerCorridaDaTela(String rideId) {
    activeOrders.removeWhere((o) => o.id == rideId);
    debugPrint('[RideStateMachine] Corrida $rideId removida da UI.');
    
    // Se não houver mais pedidos pendentes, finaliza a rota automaticamente
    if (activeOrders.isEmpty && currentState.value != RideState.idle) {
      completeRoute();
    }
  }

  ViperOffer? get activeOffer => _activeOffer.value;

  // ── Callbacks — injetados pelo integrador (HomeView) ──
  VoidCallback? onPickupRouteReady;
  VoidCallback? onDeliveryRouteReady;
  VoidCallback? onRouteCompleted;

  // ═══════════════════════════════════════════
  // ██  TRANSIÇÕES DE ESTADO
  // ═══════════════════════════════════════════

  /// [1] ACEITAR OFERTA → goingToPickup
  /// Chamado quando o motorista aceita uma oferta no overlay.
  void acceptOffer(ViperOffer offer) {
    _activeOffer.value = offer;
    currentState.value = RideState.goingToPickup;
    debugPrint('[RideStateMachine] Estado: goingToPickup — Oferta ${offer.id} aceita.');

    // Side-effect: traçar rota até a coleta (Fase 1)
    final mapController = Get.find<MapController>();
    mapController.traceRouteToPickup(
      pickupLat: offer.pickupLat,
      pickupLng: offer.pickupLng,
    );

    onPickupRouteReady?.call();
  }

  /// [2] IR PARA COLETA → Abre navegador externo (Google Maps / Waze)
  /// Lê preferência de SharedPreferences via ExternalNavigationService.
  Future<void> navigateToPickup(BuildContext context) async {
    final offer = _activeOffer.value;
    if (offer == null) return;

    debugPrint('[RideStateMachine] Abrindo navegador externo para coleta...');
    await ExternalNavigationService.abrirNavegador(
      lat: offer.pickupLat,
      lng: offer.pickupLng,
      context: context,
    );
  }

  /// [3] CHEGUEI NA COLETA → arrivedAtPickup
  /// Dispara notificação/webhook para o painel do gestor (mockado).
  void confirmArrivalAtPickup() {
    currentState.value = RideState.arrivedAtPickup;
    debugPrint('[RideStateMachine] Estado: arrivedAtPickup — Motorista chegou na coleta.');

    // Side-effect: Webhook mockado (print)
    _dispatchPickupNotification();
  }

  /// [4] SEGUIR ROTA → onDeliveryRoute
  /// Aciona a Fase 2 do mapa: ordena entregas e traça polyline completa.
  /// Retorna a lista de orders reordenada pelo Vizinho Mais Próximo.
  Future<List<ViperOrder>> startDeliveryRoute(List<ViperOrder> pendingOrders) async {
    final offer = _activeOffer.value;
    if (offer == null) return pendingOrders;

    currentState.value = RideState.onDeliveryRoute;
    debugPrint('[RideStateMachine] Estado: onDeliveryRoute — Fase 2 ativada.');

    final mapController = Get.find<MapController>();
    final optimized = await mapController.optimizeAndTraceDeliveries(
      pickupLat: offer.pickupLat,
      pickupLng: offer.pickupLng,
      orders: pendingOrders,
    );

    onDeliveryRouteReady?.call();
    return optimized;
  }

  /// [5] ROTA FINALIZADA → routeCompleted / idle
  void completeRoute() {
    currentState.value = RideState.routeCompleted;
    debugPrint('[RideStateMachine] Estado: routeCompleted — Todas as entregas processadas.');

    onRouteCompleted?.call();
  }

  /// Reseta a máquina para o estado inicial.
  void reset() {
    currentState.value = RideState.idle;
    _activeOffer.value = null;
    debugPrint('[RideStateMachine] Reset — idle.');

    final mapController = Get.find<MapController>();
    mapController.clearRoute();
  }

  // ── Internos ──

  /// Mock de webhook/push notification para o painel do gestor.
  void _dispatchPickupNotification() {
    final offer = _activeOffer.value;
    if (offer == null) return;

    // TODO: Substituir por chamada real ao Supabase Edge Function / API
    debugPrint('══════════════════════════════════════════════');
    debugPrint('📦 [WEBHOOK] Motorista chegou na coleta');
    debugPrint('   Oferta: ${offer.id}');
    debugPrint('   Local: ${offer.pickupNeighborhood}, ${offer.pickupStreet}');
    debugPrint('   Pedidos: ${offer.qtdPedidos}');
    debugPrint('══════════════════════════════════════════════');
  }
}
