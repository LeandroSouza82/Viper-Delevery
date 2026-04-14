import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class ViperMapWidget extends StatefulWidget {
  const ViperMapWidget({super.key});

  @override
  State<ViperMapWidget> createState() => _ViperMapWidgetState();
}

class _ViperMapWidgetState extends State<ViperMapWidget> {
  MapboxMap? mapboxMap;

  // Token Público carregado do .env para segurança
  final String _accessToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';

  @override
  void initState() {
    super.initState();
    // Configura o token globalmente para o SDK
    MapboxOptions.setAccessToken(_accessToken);
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey("mapbox_map"),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(-48.5495, -27.5969), // Longitude, Latitude (Florianópolis)
        ),
        zoom: 13.0,
        bearing: 0,
        pitch: 0,
      ),
      onMapCreated: (MapboxMap controller) {
        mapboxMap = controller;
        // Configurações imperativas de UI (v2.x)
        controller.compass.updateSettings(CompassSettings(enabled: false));
        controller.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
      },
    );
  }
}
