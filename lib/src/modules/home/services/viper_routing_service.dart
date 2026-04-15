import 'dart:math';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';

class ViperRoutingResult {
  final List<ViperOrder> optimizedOrders;
  final double distanceDriverToPickup;
  final double distancePickupToDeliveries;
  final double totalDistance;

  ViperRoutingResult({
    required this.optimizedOrders,
    required this.distanceDriverToPickup,
    required this.distancePickupToDeliveries,
    required this.totalDistance,
  });
}

class ViperRoutingService {
  /// Otimiza a rota usando o algoritmo de Vizinho Mais Próximo
  static ViperRoutingResult optimize({
    required double driverLat,
    required double driverLng,
    required double pickupLat,
    required double pickupLng,
    required List<ViperOrder> orders,
  }) {
    if (orders.isEmpty) {
      return ViperRoutingResult(
        optimizedOrders: [],
        distanceDriverToPickup: 0,
        distancePickupToDeliveries: 0,
        totalDistance: 0,
      );
    }

    // 1. Distância Motorista -> Coleta
    final double distDriverToPickup = _calculateDistance(driverLat, driverLng, pickupLat, pickupLng);

    // 2. Otimização das Entregas (Vizinho Mais Próximo)
    List<ViperOrder> unvisited = List.from(orders);
    List<ViperOrder> optimized = [];
    double distPickupToDeliveries = 0;

    // O ponto de partida para a primeira entrega é o Ponto de Coleta
    double currentLat = pickupLat;
    double currentLng = pickupLng;

    while (unvisited.isNotEmpty) {
      ViperOrder? nearest;
      double minDistance = double.infinity;
      int nearestIndex = -1;

      for (int i = 0; i < unvisited.length; i++) {
        final dist = _calculateDistance(currentLat, currentLng, unvisited[i].lat, unvisited[i].lng);
        if (dist < minDistance) {
          minDistance = dist;
          nearest = unvisited[i];
          nearestIndex = i;
        }
      }

      if (nearest != null) {
        distPickupToDeliveries += minDistance;
        currentLat = nearest.lat;
        currentLng = nearest.lng;
        optimized.add(unvisited.removeAt(nearestIndex));
      }
    }

    return ViperRoutingResult(
      optimizedOrders: optimized,
      distanceDriverToPickup: distDriverToPickup,
      distancePickupToDeliveries: distPickupToDeliveries,
      totalDistance: distDriverToPickup + distPickupToDeliveries,
    );
  }

  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    // Distância euclidiana simples multiplicada por um fator para simular KM reais
    // (Aproximadamente 111km por grau de latitude)
    final dLat = (lat1 - lat2) * 111.32;
    final dLng = (lng1 - lng2) * 40075 * cos((lat1 + lat2) / 2 * pi / 180) / 360;
    return sqrt(dLat * dLat + dLng * dLng);
  }
}
