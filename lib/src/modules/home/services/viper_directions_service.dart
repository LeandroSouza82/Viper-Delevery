import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:viper_delivery/src/core/config/env.dart';

/// Serviço de integração com a API de Direções do Mapbox.
/// Retorna geometria real de rota (seguindo ruas) em vez de linhas retas.
class ViperDirectionsService {
  static const String _baseUrl =
      'https://api.mapbox.com/directions/v5/mapbox/driving';

  /// Obtém a geometria da rota (lista de coordenadas) passando waypoints.
  /// [waypoints] deve conter pelo menos 2 pontos no formato (lat, lng).
  /// Retorna null se a requisição falhar.
  static Future<List<Position>?> getRouteGeometry(
    List<({double lat, double lng})> waypoints,
  ) async {
    if (waypoints.length < 2) return null;

    // Monta as coordenadas no formato Mapbox: lng,lat;lng,lat;...
    final coordsString = waypoints
        .map((w) => '${w.lng},${w.lat}')
        .join(';');

    final uri = Uri.parse(
      '$_baseUrl/$coordsString'
      '?access_token=${Env.mapboxPublicToken}'
      '&geometries=geojson'
      '&overview=full',
    );

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        debugPrint('[ViperDirections] HTTP ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;

      if (routes == null || routes.isEmpty) {
        debugPrint('[ViperDirections] Nenhuma rota encontrada.');
        return null;
      }

      // Extrai a geometria GeoJSON da primeira rota
      final geometry = routes[0]['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;

      // Converte de [lng, lat] para Position
      return coordinates
          .map((coord) {
            final c = coord as List<dynamic>;
            return Position(c[0] as double, c[1] as double);
          })
          .toList();
    } catch (e) {
      debugPrint('[ViperDirections] Erro na requisição: $e');
      return null;
    }
  }

  /// Conveniência: Rota do motorista até o ponto de coleta (Fase 1)
  static Future<List<Position>?> getPickupRoute({
    required double driverLat,
    required double driverLng,
    required double pickupLat,
    required double pickupLng,
  }) {
    return getRouteGeometry([
      (lat: driverLat, lng: driverLng),
      (lat: pickupLat, lng: pickupLng),
    ]);
  }

  /// Conveniência: Rota da coleta passando por todos os destinos (Fase 2)
  /// Waypoints: Coleta → Destino 1 → Destino 2 → ...
  static Future<List<Position>?> getDeliveryRoute({
    required double pickupLat,
    required double pickupLng,
    required List<({double lat, double lng})> destinations,
  }) {
    return getRouteGeometry([
      (lat: pickupLat, lng: pickupLng),
      ...destinations,
    ]);
  }
}
