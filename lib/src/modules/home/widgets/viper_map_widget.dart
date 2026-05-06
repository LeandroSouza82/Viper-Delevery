import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:viper_delivery/src/core/config/env.dart';
import 'package:viper_delivery/src/models/ride_model.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/services/viper_directions_service.dart';
import 'package:viper_delivery/src/modules/map/utils/marker_generator.dart';

/// Fase de roteamento visual no mapa
enum RoutePhase {
  idle,    // Sem rota ativa
  pickup,  // Fase 1: Motorista → Coleta (linha roxa)
  delivery // Fase 2: Coleta → Destinos ordenados (linha azul)
}

class ViperMapWidget extends StatefulWidget {
  const ViperMapWidget({super.key});

  @override
  ViperMapWidgetState createState() => ViperMapWidgetState();
}

class ViperMapWidgetState extends State<ViperMapWidget> {
  MapboxMap? mapboxMap;
  bool _hasAnimatedToUser = false;
  
  // ── Controle de Rastreamento (Viper Tracker) ──
  bool _isTracking = true; 
  StreamSubscription<geo.Position>? _positionStream;
  geo.Position? _lastPos;

  // Token Público carregado da classe Env (Envied) para segurança
  final String _accessToken = Env.mapboxPublicToken;
  final _settings = SettingsController();

  // ── Annotation Managers (Pinos e Rota) ──
  PointAnnotationManager? _pointManager;
  PolylineAnnotationManager? _polylineManager;

  // Cache de imagens dos pinos registradas no estilo
  final Set<String> _registeredPinImages = {};

  // ── Máquina de Estados da Rota ──
  RoutePhase _currentPhase = RoutePhase.idle;
  double _pickupLat = 0;
  double _pickupLng = 0;
  bool _isFetchingRoute = false; // Guard contra chamadas concorrentes

  /// Fase atual da rota — lida por HomeView para não sobrescrever Fase 1
  RoutePhase get currentPhase => _currentPhase;

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
    _settings.removeListener(_onSettingsChanged);
    _positionStream?.cancel();
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
          // Limpa managers antigos pois o estilo foi recarregado
          _pointManager = null;
          _polylineManager = null;
          _registeredPinImages.clear();
          await _setupMapboxComponent(mapboxMap!);
        }
      },
      // FASE 4: Trava de Segurança - Se o usuário mover a câmera manualmente, pausa o tracking
      onCameraChangeListener: (cameraChangedEvent) {
        // O Mapbox dispara esse evento para qualquer mudança. 
        // Em implementações reais, verificaríamos a origem, mas aqui o scroll é o principal gatilho.
      },
      onScrollListener: (scrollEvent) => _stopTracking(),
    );
  }

  void _stopTracking() {
    if (_isTracking) {
      setState(() => _isTracking = false);
      debugPrint('📍 [TRACKER] Manual: Pausando acompanhamento automático.');
    }
  }

  /// Configura os componentes do Mapbox (Puck, Gestos, UI)
  /// Chamado na criação e toda vez que o estilo carrega
  Future<void> _setupMapboxComponent(MapboxMap controller) async {
    // Configurações imperativas de UI e Gestos
    controller.compass.updateSettings(CompassSettings(enabled: false));
    controller.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    controller.gestures.updateSettings(GesturesSettings(rotateEnabled: true)); // Habilitado para rotação manual

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

    // 3. Inicializa os Annotation Managers para pinos e rota
    _polylineManager = await controller.annotations.createPolylineAnnotationManager();
    _pointManager = await controller.annotations.createPointAnnotationManager();

    // 4. Inicia Stream de GPS para Câmera Dinâmica (Viper Tracker)
    _startTrackingStream(controller);

    // 5. Animação de Boas-Vindas
    if (!_hasAnimatedToUser) {
      _hasAnimatedToUser = true;
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final geo.Position position = await geo.Geolocator.getCurrentPosition();
        if (mounted) {
          await controller.flyTo(
            CameraOptions(
              center: Point(coordinates: Position(position.longitude, position.latitude)),
              zoom: 16.5,
              bearing: position.heading,
              pitch: 45.0,
            ),
            MapAnimationOptions(duration: 2500),
          );
        }
      } catch (e) {
        debugPrint("Erro na animação inicial: $e");
      }
    }
  }

  void _startTrackingStream(MapboxMap controller) {
    _positionStream?.cancel();
    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        distanceFilter: 2, // Apenas se mover 2 metros para evitar jitter
      ),
    ).listen((pos) {
      _lastPos = pos;
      if (_isTracking && mounted && mapboxMap != null) {
        // FASE 3: A Mágica - Auto-Follow, Auto-Rotate e Tilt 3D com movimento suave
        mapboxMap!.easeTo(
          CameraOptions(
            center: Point(coordinates: Position(pos.longitude, pos.latitude)),
            bearing: pos.heading, // Auto-Rotate
            pitch: 45.0,          // Tilt 3D
            zoom: 16.5,           // Zoom de Navegação
          ),
          MapAnimationOptions(duration: 1000),
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  // ██  ROTA NO MAPA: Máquina de Estados (Fase 1 / Fase 2)
  // ═══════════════════════════════════════════════════════════

  /// FASE 1 — Aceitar oferta: desenha rota Motorista → Coleta
  /// Chamado por HomeView._onAcceptOffer()
  Future<void> startPickupRoute({
    required double pickupLat,
    required double pickupLng,
  }) async {
    _pickupLat = pickupLat;
    _pickupLng = pickupLng;
    _currentPhase = RoutePhase.pickup;

    await _clearAnnotations();

    // Tenta obter posição real do motorista
    double driverLat = pickupLat; // fallback = próprio pickup
    double driverLng = pickupLng;
    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      driverLat = pos.latitude;
      driverLng = pos.longitude;
    } catch (_) {}

    final coords = await ViperDirectionsService.getPickupRoute(
      driverLat: driverLat,
      driverLng: driverLng,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
    );

    // Desenha pino de coleta (especial)
    await _drawPickupPin(pickupLat, pickupLng);

    // Desenha polyline roxa real (sem fallback ponto a ponto)
    if (coords != null && coords.length >= 2) {
      await _drawPolylineFromCoords(
        coords,
        color: const Color(0xFF9C27B0), // Roxo = A caminho da coleta
        casingWidth: 12.0,
        fillWidth: 8.0,
      );
    }

    // Enquadra câmera nos dois pontos
    await _fitCameraToPositions([
      (lat: driverLat, lng: driverLng),
      (lat: pickupLat, lng: pickupLng),
    ]);
  }

  /// FASE 2 — Sair para entrega / reordenar: desenha Coleta → Destinos
  /// Chamado por HomeView._syncMapWithOrders() quando fase == delivery
  /// e também diretamente quando o motorista clica em "Sair para Entrega"
  Future<void> updateMapRoute(List<RideModel> activeOrders) async {
    if (mapboxMap == null) return;
    if (_isFetchingRoute) return; // bloqueia chamadas concorrentes

    _currentPhase = RoutePhase.delivery;
    _isFetchingRoute = true;

    try {
      await _clearAnnotations();
      if (activeOrders.isEmpty) return;

      // Pinos numerados nos destinos
      await _drawNumberedPins(activeOrders);

      // Monta waypoints: Coleta → Destino1 → Destino2 → ...
      final destinations = activeOrders
          .map((o) => (lat: o.lat, lng: o.lng))
          .toList();

      List<Position>? coords;
      if (_pickupLat != 0 && _pickupLng != 0) {
        coords = await ViperDirectionsService.getDeliveryRoute(
          pickupLat: _pickupLat,
          pickupLng: _pickupLng,
          destinations: destinations,
        );
      }

      // Polyline azul Viper real (sem fallback ponto a ponto)
      if (coords != null && coords.length >= 2) {
        await _drawPolylineFromCoords(
          coords,
          color: const Color(0xFF0055FF),
          casingWidth: 12.0,
          fillWidth: 8.0,
        );
      }

      // Enquadra câmera em toda a rota
      await _fitCameraToPositions(
        activeOrders.map((o) => (lat: o.lat, lng: o.lng)).toList(),
      );
    } finally {
      _isFetchingRoute = false;
    }
  }

  /// Limpa toda a rota e volta ao estado idle
  Future<void> clearMapRoute() async {
    _currentPhase = RoutePhase.idle;
    _pickupLat = 0;
    _pickupLng = 0;
    await _clearAnnotations();
  }

  // ── Internos ────────────────────────────────────────────────

  Future<void> _clearAnnotations() async {
    try {
      await _pointManager?.deleteAll();
      await _polylineManager?.deleteAll();
    } catch (e) {
      debugPrint('[ViperMap] Erro ao limpar anotações: $e');
    }
  }

  /// Pino especial de coleta (triângulo laranja com ícone de loja)
  Future<void> _drawPickupPin(double lat, double lng) async {
    if (_pointManager == null || mapboxMap == null) return;
    const imageId = 'viper-pin-pickup';

    if (!_registeredPinImages.contains(imageId)) {
      try {
        final bytes = await MarkerGenerator.generateTeardropMarker(
          color: Colors.orange,
          text: 'C',
        );
        await mapboxMap!.style.addStyleImage(
          imageId, 2.0,
          MbxImage(width: 140, height: 140, data: bytes),
          false, [], [], null,
        );
        _registeredPinImages.add(imageId);
      } catch (e) {
        debugPrint('[ViperMap] Erro ao registrar pino de coleta: $e');
        return;
      }
    }

    try {
      await _pointManager!.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        iconImage: imageId,
        iconSize: 0.6,
        iconAnchor: IconAnchor.CENTER,
      ));
    } catch (e) {
      debugPrint('[ViperMap] Erro ao criar pino coleta: $e');
    }
  }

  /// Pinos numerados dos destinos de entrega
  Future<void> _drawNumberedPins(List<RideModel> orders) async {
    if (_pointManager == null || mapboxMap == null) return;

    final List<PointAnnotationOptions> pinOptions = [];

    for (int i = 0; i < orders.length; i++) {
      final order = orders[i];
      final pinNumber = i + 1;
      final imageId = 'viper-pin-${order.serviceType.name}-$pinNumber';

      if (!_registeredPinImages.contains(imageId)) {
        try {
          final pinBytes = await MarkerGenerator.generateTeardropMarker(
            color: order.serviceType.color,
            text: pinNumber.toString(),
          );
          await mapboxMap!.style.addStyleImage(
            imageId, 2.0,
            MbxImage(width: 140, height: 140, data: pinBytes),
            false, [], [], null,
          );
          _registeredPinImages.add(imageId);
        } catch (e) {
          debugPrint('[ViperMap] Erro ao registrar pino $pinNumber: $e');
          continue;
        }
      }

      pinOptions.add(PointAnnotationOptions(
        geometry: Point(coordinates: Position(order.lng, order.lat)),
        iconImage: imageId,
        iconSize: 0.6,
        iconAnchor: IconAnchor.CENTER,
      ));
    }

    try {
      await _pointManager!.createMulti(pinOptions);
    } catch (e) {
      debugPrint('[ViperMap] Erro ao criar pinos: $e');
    }
  }

  /// Desenha polyline com contorno preto (casing premium).
  /// Camada 1 (base): preto, mais grossa → cria o contorno.
  /// Camada 2 (fill): cor do VUP, mais fina → fica por cima.
  /// A ordem de criação garante que a camada de fill fique acima.
  Future<void> _drawPolylineFromCoords(
    List<Position> coords, {
    required Color color,
    double fillWidth = 4.5,
    double casingWidth = 7.5,
    double opacity = 0.95,
  }) async {
    if (_polylineManager == null || coords.length < 2) return;

    final lineString = LineString(coordinates: coords);

    try {
      // ── 1. Contorno (Casing) — desenhado PRIMEIRO para ficar embaixo ──
      await _polylineManager!.create(
        PolylineAnnotationOptions(
          geometry: lineString,
          lineColor: Colors.black.toARGB32(),
          lineWidth: casingWidth,
          lineOpacity: opacity,
          lineJoin: LineJoin.ROUND,
        ),
      );

      // ── 2. Miolo (Fill) — desenhado DEPOIS para ficar por cima ──
      await _polylineManager!.create(
        PolylineAnnotationOptions(
          geometry: lineString,
          lineColor: color.toARGB32(),
          lineWidth: fillWidth,
          lineOpacity: opacity,
          lineJoin: LineJoin.ROUND,
        ),
      );
    } catch (e) {
      debugPrint('[ViperMap] Erro ao criar polyline: $e');
    }
  }

  /// Ajusta câmera para enquadrar uma lista de pontos lat/lng
  Future<void> _fitCameraToPositions(
    List<({double lat, double lng})> points,
  ) async {
    if (mapboxMap == null || points.isEmpty) return;

    double minLat = points.first.lat;
    double maxLat = points.first.lat;
    double minLng = points.first.lng;
    double maxLng = points.first.lng;

    for (final p in points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }

    const pad = 0.015;
    try {
      final bounds = CoordinateBounds(
        southwest: Point(coordinates: Position(minLng - pad, minLat - pad)),
        northeast: Point(coordinates: Position(maxLng + pad, maxLat + pad)),
        infiniteBounds: false,
      );
      final camera = await mapboxMap!.cameraForCoordinateBounds(
        bounds,
        MbxEdgeInsets(top: 80, left: 60, bottom: 200, right: 60),
        null, null, null, null,
      );
      await mapboxMap!.flyTo(camera, MapAnimationOptions(duration: 800));
    } catch (e) {
      debugPrint('[ViperMap] Erro ao ajustar câmera: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ██  GERADORES DE IMAGEM PROGRAMÁTICA
  // ═══════════════════════════════════════════════════════════



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

  /// Centraliza o mapa na localização atual do usuário e REATIVA o tracking
  Future<void> recenter() async {
    try {
      setState(() => _isTracking = true); // FASE 4: Reativa o acompanhamento
      
      final geo.Position position = _lastPos ?? await geo.Geolocator.getCurrentPosition();
      
      if (mounted && mapboxMap != null) {
        await mapboxMap!.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(position.longitude, position.latitude)),
            zoom: 16.5,
            bearing: position.heading,
            pitch: 45.0,
          ),
          MapAnimationOptions(duration: 1500),
        );
        debugPrint('📍 [TRACKER] Auto: Retornando ao acompanhamento do GPS.');
      }
    } catch (e) {
      debugPrint("Erro ao recentralizar mapa: $e");
    }
  }
}


