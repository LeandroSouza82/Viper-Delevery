import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class ViperMapWidget extends StatefulWidget {
  const ViperMapWidget({super.key});

  @override
  State<ViperMapWidget> createState() => _ViperMapWidgetState();
}

class _ViperMapWidgetState extends State<ViperMapWidget> {
  MapboxMap? mapboxMap;
  bool _hasAnimatedToUser = false;

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
      onMapCreated: (MapboxMap controller) async {
        mapboxMap = controller;
        // Configurações imperativas de UI e Gestos (v2.x)
        controller.compass.updateSettings(CompassSettings(enabled: false));
        controller.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
        controller.gestures.updateSettings(GesturesSettings(rotateEnabled: false));

        // 1. Gera a imagem do marcador (Círculo Branco + Seta Preta)
        final puckImageBytes = await _generatePuckImage();
        
        // 2. Registra a imagem no estilo do mapa (opcional, mas bom para cache)
        await controller.style.addStyleImage(
          "custom-puck-image", 
          1.0, 
          MbxImage(width: 150, height: 150, data: puckImageBytes), 
          false, [], [], null
        );

        // 3. Ativa a localização com o Puck customizado e rotação por Heading (Bússola)
        controller.location.updateSettings(
          LocationComponentSettings(
            enabled: true,
            puckBearingEnabled: true,
            puckBearing: PuckBearing.HEADING,
            locationPuck: LocationPuck(
              locationPuck2D: LocationPuck2D(
                topImage: puckImageBytes, // Agora aceita Uint8List diretamente
              ),
            ),
          ),
        );

        // 4. Animação de Boas-Vindas (FlyTo até o motorista) - Estabilização por Hardware
        if (!_hasAnimatedToUser) {
          _hasAnimatedToUser = true; // Trava imediata para evitar loops de hardware
          
          try {
            // Pequeno delay para o Xiaomi estabilizar o canvas antes do movimento
            await Future.delayed(const Duration(milliseconds: 500));
            
            final geo.Position position = await geo.Geolocator.getCurrentPosition();
            if (mounted && mapboxMap != null) {
              await controller.flyTo(
                CameraOptions(
                  center: Point(coordinates: Position(position.longitude, position.latitude)),
                  zoom: 15.0,
                  bearing: 0,
                  pitch: 0,
                ),
                MapAnimationOptions(duration: 2500),
              );
            }
          } catch (e) {
            debugPrint("Erro na animação inicial: $e");
          }
        }
      },
    );
  }

  /// Gera programaticamente a imagem do marcador de localização
  Future<Uint8List> _generatePuckImage() async {
    const double size = 150.0; // Tamanho maior para retina/alta densidade
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    // 1. Sombra suave para profundidade
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 4), size / 2 - 15, shadowPaint);

    // 2. Círculo Branco (Fundo)
    final circlePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 15, circlePaint);

    // 3. Borda Preta Fina
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 15, borderPaint);

    // 4. Seta Preta (Navegação)
    final arrowPath = Path();
    const double center = size / 2;
    const double arrowSize = 40.0;
    
    arrowPath.moveTo(center, center - arrowSize); // Ponta
    arrowPath.lineTo(center - arrowSize * 0.7, center + arrowSize * 0.5); // Esquerda baixo
    arrowPath.lineTo(center, center + arrowSize * 0.1); // Recorte meio
    arrowPath.lineTo(center + arrowSize * 0.7, center + arrowSize * 0.5); // Direita baixo
    arrowPath.close();

    final arrowPaint = Paint()..color = Colors.black;
    canvas.drawPath(arrowPath, arrowPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
}
