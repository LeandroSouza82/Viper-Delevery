import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Parâmetros de câmera / GPS para o mapa (Mapbox + Geolocator).
/// Mantém zoom útil para moto e limita animações para não sobrecarregar o aparelho.
abstract final class MapFollowConfig {
  static const double zoomMin = 15.0;
  static const double zoomMax = 17.0;

  /// Animação curta entre atualizações de posição (ms).
  static const int easeDurationMs = 750;

  /// Intervalo mínimo entre dois [easeTo] automáticos (economia de CPU/bateria).
  static const Duration minIntervalBetweenAutoEase = Duration(milliseconds: 900);

  /// Atualiza GPS só após deslocamento mínimo (reduz wakeups no Android).
  static const geo.LocationSettings locationSettings = geo.LocationSettings(
    accuracy: geo.LocationAccuracy.high,
    distanceFilter: 12,
  );

  /// Inclinação 3D em modo navegação (seguindo / recentralizar com rotação).
  static const double navigationPitch = 45.0;

  /// Abaixo disso, `heading` costuma ser ruído; mantém o bearing atual da câmera.
  static const double minSpeedMpsForHeadingBearing = 0.5;

  static double clampZoom(double zoom) {
    if (zoom < zoomMin) return zoomMin;
    if (zoom > zoomMax) return zoomMax;
    return zoom;
  }

  /// [rotateWithHeading]: `true` só em modo follow (ou após recentralizar) —
  /// usa [geo.Position.heading] como bearing e [navigationPitch]. Com `false`,
  /// preserva bearing/pitch atuais (ex.: usuário soltou o mapa).
  static Future<void> easeCameraToPosition(
    MapboxMap map, {
    required geo.Position position,
    required int durationMs,
    required bool rotateWithHeading,
  }) async {
    final state = await map.getCameraState();
    final zoom = clampZoom(state.zoom);

    final double bearing;
    final double pitch;
    if (rotateWithHeading) {
      bearing = _bearingFromHeading(position, fallbackBearing: state.bearing);
      pitch = navigationPitch;
    } else {
      bearing = state.bearing;
      pitch = state.pitch;
    }

    await map.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: zoom,
        bearing: bearing,
        pitch: pitch,
      ),
      MapAnimationOptions(duration: durationMs),
    );
  }

  static double _bearingFromHeading(
    geo.Position position, {
    required double fallbackBearing,
  }) {
    if (position.heading.isNaN) return fallbackBearing;
    // Parado: heading 0 é ambíguo em vários aparelhos — não força rotação.
    if (position.speed < minSpeedMpsForHeadingBearing &&
        position.heading.abs() < 1.0) {
      return fallbackBearing;
    }
    var h = position.heading % 360.0;
    if (h < 0) h += 360.0;
    return h;
  }
}
