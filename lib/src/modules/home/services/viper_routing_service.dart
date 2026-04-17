import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:geolocator/geolocator.dart';

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
  /// Otimiza a rota e calcula a distância acumulada real entre todas as paradas
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

    // 1. Distância Motorista -> Coleta (Ida) - Precisão Real GPS
    final double distDriverToPickup = _calculateRealDistance(driverLat, driverLng, pickupLat, pickupLng);

    // 2. Otimização das Entregas (Vizinho Mais Próximo) com Soma Acumulada
    List<ViperOrder> unvisited = List.from(orders);
    List<ViperOrder> optimized = [];
    double distEntregaAcumulada = 0;

    // O ponto de partida para a primeira entrega é o Ponto de Coleta
    double currentLat = pickupLat;
    double currentLng = pickupLng;

    while (unvisited.isNotEmpty) {
      ViperOrder? nearest;
      double minDistance = double.infinity;
      int nearestIndex = -1;

      for (int i = 0; i < unvisited.length; i++) {
        final dist = _calculateRealDistance(currentLat, currentLng, unvisited[i].lat, unvisited[i].lng);
        if (dist < minDistance) {
          minDistance = dist;
          nearest = unvisited[i];
          nearestIndex = i;
        }
      }

      if (nearest != null) {
        distEntregaAcumulada += minDistance;
        currentLat = nearest.lat;
        currentLng = nearest.lng;
        optimized.add(unvisited.removeAt(nearestIndex));
      }
    }

    return ViperRoutingResult(
      optimizedOrders: optimized,
      distanceDriverToPickup: distDriverToPickup,
      distancePickupToDeliveries: distEntregaAcumulada,
      totalDistance: distDriverToPickup + distEntregaAcumulada,
    );
  }

  /// Calcula a distância real em KM usando o motor do Geolocator (WGS84)
  static double _calculateRealDistance(double lat1, double lng1, double lat2, double lng2) {
    final double distanceInMetres = Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    return distanceInMetres / 1000; // Converte para KM
  }
}
