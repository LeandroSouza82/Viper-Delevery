import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_map_widget.dart';
import 'package:viper_delivery/src/modules/home/services/viper_routing_service.dart';

/// Controlador centralizado de mapa e polyline.
/// Orquestra as duas fases de roteamento sem tocar no visual.
///
/// Fase 1 — Motorista → Coleta (polyline roxa via ruas reais)
/// Fase 2 — Coleta → Entregas ordenadas por Vizinho Mais Próximo (polyline azul)
class MapController extends GetxController {
  GlobalKey<ViperMapWidgetState>? _mapKey;

  /// Injeta a referência do widget do mapa. Chamado uma única vez na HomeView.
  void attachMapKey(GlobalKey<ViperMapWidgetState> key) {
    _mapKey = key;
  }

  ViperMapWidgetState? get _map => _mapKey?.currentState;

  // ═══════════════════════════════════════════
  // ██  FASE 1: Motorista → Coleta
  // ═══════════════════════════════════════════

  /// Traça a Polyline Motorista → Coleta usando a API de Direções.
  /// Chamado imediatamente após o motorista aceitar a oferta.
  Future<void> traceRouteToPickup({
    required double pickupLat,
    required double pickupLng,
  }) async {
    final map = _map;
    if (map == null) {
      debugPrint('[MapController] Mapa não inicializado.');
      return;
    }

    debugPrint('[MapController] Fase 1 — Traçando rota até a coleta...');
    await map.startPickupRoute(pickupLat: pickupLat, pickupLng: pickupLng);
  }

  // ═══════════════════════════════════════════
  // ██  FASE 2: Coleta → Entregas (Vizinho Mais Próximo)
  // ═══════════════════════════════════════════

  /// Apaga a linha da Fase 1, ordena as entregas pelo algoritmo do
  /// "Vizinho Mais Próximo" e traça a polyline completa via ruas reais.
  ///
  /// Retorna a lista de [ViperOrder] na ordem otimizada para o chamador
  /// atualizar os cards do painel.
  Future<List<ViperOrder>> optimizeAndTraceDeliveries({
    required double pickupLat,
    required double pickupLng,
    required List<ViperOrder> orders,
  }) async {
    final map = _map;
    if (map == null || orders.isEmpty) return orders;

    debugPrint('[MapController] Fase 2 — Otimizando ${orders.length} entregas (Vizinho Mais Próximo)...');

    // 1. Tenta obter posição real do motorista para maior precisão
    double driverLat = pickupLat;
    double driverLng = pickupLng;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      driverLat = pos.latitude;
      driverLng = pos.longitude;
    } catch (_) {}

    // 2. Algoritmo do Vizinho Mais Próximo (já implementado no ViperRoutingService)
    final result = ViperRoutingService.optimize(
      driverLat: driverLat,
      driverLng: driverLng,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      orders: orders,
    );

    debugPrint('[MapController] Rota otimizada: ${result.totalDistance.toStringAsFixed(2)} km total.');

    // 3. Desenha a polyline Fase 2 no mapa (azul, ruas reais)
    await map.updateMapRoute(result.optimizedOrders);

    return result.optimizedOrders;
  }

  /// Limpa toda a rota do mapa e retorna ao estado idle.
  Future<void> clearRoute() async {
    await _map?.clearMapRoute();
    debugPrint('[MapController] Rota limpa — estado idle.');
  }

  /// Re-centraliza o mapa na posição atual do motorista.
  Future<void> recenter() async {
    await _map?.recenter();
  }
}
