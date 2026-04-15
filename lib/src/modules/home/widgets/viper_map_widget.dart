import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:viper_delivery/src/modules/home/controllers/map_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

class ViperMapWidget extends StatefulWidget {
  const ViperMapWidget({super.key});

  @override
  ViperMapWidgetState createState() => ViperMapWidgetState();
}

class ViperMapWidgetState extends State<ViperMapWidget> {
  MapboxMap? mapboxMap;
  bool _hasAnimatedToUser = false;

  /// Quando `true`, a câmera acompanha o GPS; pan/zoom manual define `false`.
  bool isFollowingUser = true;

  StreamSubscription<geo.Position>? _positionSub;
  bool _cameraMoveFromApp = false;
  bool _easeInFlight = false;
  DateTime? _lastAutoEaseAt;

  // Token Público carregado do .env para segurança
  final String _accessToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';
  final _settings = SettingsController();

  @override
  void initState() {
    super.initState();
    // Inicia configurações se necessário
    _settings.init();
    // Escuta mudanças de tema para atualizar o mapa
    _settings.addListener(_onSettingsChanged);
    // Configura o token globalmente para o SDK
    MapboxOptions.setAccessToken(_accessToken);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _positionSub = null;
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      mapboxMap?.loadStyleURI(_settings.mapStyle);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey("mapbox_map"),
      styleUri: _settings.mapStyle,
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(-48.5495, -27.5969)),
        zoom: 13.0,
        bearing: 0,
        pitch: 0,
      ),
      onMapCreated: (MapboxMap controller) async {
        mapboxMap = controller;
        await _setupMapboxComponent(controller);
      },
      onStyleLoadedListener: (styleLoadedEvent) async {
        if (mapboxMap != null) {
          await _setupMapboxComponent(mapboxMap!);
        }
      },
    );
  }

  /// Configura os componentes do Mapbox (Puck, Gestos, UI)
  /// Chamado na criação e toda vez que o estilo carrega
  Future<void> _setupMapboxComponent(MapboxMap controller) async {
    // Configurações imperativas de UI e Gestos
    controller.compass.updateSettings(CompassSettings(enabled: false));
    controller.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    controller.gestures.updateSettings(GesturesSettings(rotateEnabled: false));

    // 1. Gera e Registra a imagem do marcador
    final puckImageBytes = await _generatePuckImage();
    await controller.style.addStyleImage(
      "custom-puck-image", 
      1.0, 
      MbxImage(width: 150, height: 150, data: puckImageBytes), 
      false, [], [], null
    );

    // 2. Ativa a localização com o Puck customizado e bússola
    controller.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
        locationPuck: LocationPuck(
          locationPuck2D: LocationPuck2D(topImage: puckImageBytes),
        ),
      ),
    );

    // 3. Animação de Boas-Vindas (apenas na primeira vez)
    if (!_hasAnimatedToUser) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final geo.Position position = await geo.Geolocator.getCurrentPosition();
        if (mounted) {
          _cameraMoveFromApp = true;
          await controller.flyTo(
            CameraOptions(
              center: Point(coordinates: Position(position.longitude, position.latitude)),
              zoom: MapFollowConfig.zoomMin,
              bearing: 0,
              pitch: 0,
            ),
            MapAnimationOptions(duration: 2500),
          );
          _cameraMoveFromApp = false;
        }
      } catch (e) {
        debugPrint("Erro na animação inicial: $e");
        _cameraMoveFromApp = false;
      } finally {
        _hasAnimatedToUser = true;
      }
    }

    _bindUserInterruptsFollow(controller);
    _ensurePositionStream(controller);
  }

  void _bindUserInterruptsFollow(MapboxMap controller) {
    void onUserMovedMap() {
      if (_cameraMoveFromApp) return;
      if (!isFollowingUser) return;
      if (mounted) {
        setState(() => isFollowingUser = false);
      } else {
        isFollowingUser = false;
      }
    }

    controller.setOnMapMoveListener((_) => onUserMovedMap());
    controller.setOnMapZoomListener((_) => onUserMovedMap());
  }

  void _ensurePositionStream(MapboxMap controller) {
    if (_positionSub != null) return;

    _positionSub = geo.Geolocator.getPositionStream(
      locationSettings: MapFollowConfig.locationSettings,
    ).listen(
      (geo.Position position) {
        if (!mounted || mapboxMap == null) return;
        unawaited(_onLocationUpdate(mapboxMap!, position));
      },
      onError: (Object e) => debugPrint('Stream de localização: $e'),
    );
  }

  Future<void> _onLocationUpdate(
    MapboxMap controller,
    geo.Position position,
  ) async {
    if (!isFollowingUser || !mounted) return;

    final now = DateTime.now();
    if (_lastAutoEaseAt != null &&
        now.difference(_lastAutoEaseAt!) <
            MapFollowConfig.minIntervalBetweenAutoEase) {
      return;
    }
    if (_easeInFlight) return;

    _easeInFlight = true;
    _lastAutoEaseAt = now;
    _cameraMoveFromApp = true;
    try {
      await MapFollowConfig.easeCameraToPosition(
        controller,
        position: position,
        durationMs: MapFollowConfig.easeDurationMs,
        rotateWithHeading: true,
      );
    } catch (e) {
      debugPrint('Erro ao seguir posição: $e');
    } finally {
      _cameraMoveFromApp = false;
      _easeInFlight = false;
    }
  }

  /// Gera programaticamente a imagem do marcador de localização
  Future<Uint8List> _generatePuckImage() async {
    const double size = 150.0; // Tamanho maior para retina/alta densidade
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    // 1. Sombra suave para profundidade
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
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

  /// Centraliza o mapa na localização atual do usuário
  Future<void> recenter() async {
    if (mounted) {
      setState(() => isFollowingUser = true);
    } else {
      isFollowingUser = true;
    }

    final controller = mapboxMap;
    if (controller == null) return;

    try {
      final geo.Position position = await geo.Geolocator.getCurrentPosition();
      if (!mounted) return;

      _cameraMoveFromApp = true;
      await MapFollowConfig.easeCameraToPosition(
        controller,
        position: position,
        durationMs: MapFollowConfig.easeDurationMs,
        rotateWithHeading: true,
      );
    } catch (e) {
      debugPrint("Erro ao recentralizar mapa: $e");
    } finally {
      _cameraMoveFromApp = false;
    }
  }
}
