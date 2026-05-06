import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/models/ride_model.dart';
import 'package:viper_delivery/src/modules/home/controllers/home_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:viper_delivery/src/modules/home/services/external_navigation_service.dart';
import 'package:viper_delivery/src/modules/home/services/viper_routing_service.dart';
import 'package:viper_delivery/src/modules/home/widgets/home_menu_icon.dart';
import 'package:viper_delivery/src/modules/home/widgets/recenter_map_button.dart';
import 'package:viper_delivery/src/modules/home/widgets/sos_emergency_button.dart';
import 'package:viper_delivery/src/modules/home/widgets/stats_pill_widget.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_bottom_sheet_panel.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_map_widget.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_menu_central.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_offer_overlay.dart';
import 'package:viper_delivery/src/modules/map/controllers/map_controller.dart';
import 'package:viper_delivery/src/modules/profile/controllers/performance_controller.dart';
import 'package:viper_delivery/src/modules/profile/controllers/profile_controller.dart';
import 'package:viper_delivery/src/modules/ride/controllers/ride_state_machine.dart';
import 'package:viper_delivery/src/modules/ride/services/upload_queue_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final SettingsController _settingsController = Get.put(SettingsController());
  final HomeController _homeController = HomeController();
  final ViperMenuController _menuController = Get.put(ViperMenuController());
  final PerformanceController _performanceController = Get.put(PerformanceController());
  final MapController _mapController = Get.put(MapController());
  final RideStateMachine _rideStateMachine = Get.put(RideStateMachine());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ViperMapWidgetState> _mapWidgetKey = GlobalKey<ViperMapWidgetState>();
  final GlobalKey<ViperBottomSheetPanelState> _ridePanelKey = GlobalKey<ViperBottomSheetPanelState>();
  
  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(0.16);

  static const double _minExtent = 0.16;

  @override
  void initState() {
    super.initState();
    Get.put(ProfileController()); // [SOS] Injeção Cirúrgica
    WidgetsBinding.instance.addObserver(this);
    
    // Wiring: MapController precisa da key do mapa
    _mapController.attachMapKey(_mapWidgetKey);

    // Wiring: RideStateMachine callbacks
    _rideStateMachine.onPickupRouteReady = () {
      _ridePanelKey.currentState?.expandToHalf();
    };
    _rideStateMachine.onDeliveryRouteReady = () {
      _ridePanelKey.currentState?.expandToHalf();
    };
    _rideStateMachine.onRouteCompleted = () {
      _ridePanelKey.currentState?.collapseToPeek();
    };

    // Refresh de dados inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settingsController.init();
      _homeController.initializeResilience(context);
      _menuController.fetchAllData();
      _performanceController.onInit(); // Garante o fetch inicial
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sheetExtent.dispose();
    super.dispose();
  }

  /// Ação do botão flutuante da máquina de estados.
  /// Reage ao estado atual sem alterar o visual dos cards.
  Future<void> _onStateMachineAction() async {
    switch (_rideStateMachine.currentState.value) {
      case RideState.goingToPickup:
        // Abre navegador externo (Google Maps / Waze)
        await _rideStateMachine.navigateToPickup(context);
        // Transição automática para "arrivedAtPickup" após navegar
        _rideStateMachine.confirmArrivalAtPickup();
        break;

      case RideState.arrivedAtPickup:
        // Dispara notificação e muda para "seguir rota"
        final pendingOrders = _rideStateMachine.activeOrders
            .where((o) => o.status == RideStatus.assigned)
            .toList();
        final optimized = await _rideStateMachine.startDeliveryRoute(pendingOrders);
        // Atualiza a lista com a ordem otimizada
        final nonPending = _rideStateMachine.activeOrders
            .where((o) => o.status != RideStatus.assigned)
            .toList();
        _rideStateMachine.activeOrders.assignAll([...nonPending, ...optimized]);

        // Abre o GPS externo apontando para o PRIMEIRO destino otimizado
        if (optimized.isNotEmpty && mounted) {
          await ExternalNavigationService.abrirNavegador(
            lat: optimized.first.lat,
            lng: optimized.first.lng,
            context: context,
            address: optimized.first.deliveryAddress,
          );
        }
        break;

      case RideState.onDeliveryRoute:
        // Navega para o próximo destino pendente
        final nextPending = _rideStateMachine.activeOrders
            .where((o) => o.status == RideStatus.assigned || o.status == RideStatus.onDeliveryRoute)
            .toList();
        if (nextPending.isNotEmpty && mounted) {
          await ExternalNavigationService.abrirNavegador(
            lat: nextPending.first.lat,
            lng: nextPending.first.lng,
            context: context,
            address: nextPending.first.deliveryAddress,
          );
        }
        _ridePanelKey.currentState?.expandToHalf();
        break;

      case RideState.routeCompleted:
        _rideStateMachine.reset();
        break;

      default:
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _settingsController.reevaluateAutoTheme();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final safeBottomHeight = MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 30.0;

    return Obx(() {
        final isDark = _settingsController.isDarkTheme;
        
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light, 
            systemNavigationBarColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            extendBody: true,
            drawer: ViperMenuCentral(
              settingsController: _settingsController,
              menuController: _menuController,
              onReturnToCD: () {
                _mapController.recenter();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Traçando rota de volta ao Centro de Distribuição...'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            body: NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                _sheetExtent.value = notification.extent;
                return true;
              },
              child: Stack(
                children: [
                  // 1. Mapa (Fundo)
                  Positioned.fill(child: ViperMapWidget(key: _mapWidgetKey)),
                  
                  // 2. HUD - Cápsula de Status (Topo)
                  Positioned(
                    top: topPadding + 15,
                    left: 0,
                    right: 0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        StatsPillWidget(
                          homeController: _homeController,
                          settingsController: _settingsController,
                        ),
                        // [VUP SYNC] Indicador de Upload Pendente
                        Positioned(
                          right: 40,
                          child: Obx(() {
                            final queue = Get.find<UploadQueueService>();
                            if (!queue.hasPendingUploads) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.cloud_upload,
                                color: Colors.white,
                                size: 14,
                              ),
                            ).animate(onPlay: (controller) => controller.repeat())
                             .shimmer(duration: const Duration(seconds: 2));
                          }),
                        ),
                      ],
                    ),
                  ),

                  // 3. Botão Acionar Rota (Online/Offline) - Ride-on-Sheet
                  ValueListenableBuilder<double>(
                    valueListenable: _sheetExtent,
                    builder: (context, extent, child) {
                      // O botão "pousa" sobre a Dragon Ball e sobe junto com ela
                      // Efeito de sumir: 1.0 (fechada) -> 0.0 (extent > 0.4)
                      final opacity = ((0.4 - extent) / (0.4 - _minExtent)).clamp(0.0, 1.0);
                      
                      return Positioned(
                        bottom: (screenHeight * extent) + 15, 
                        left: 24,
                        right: 24,
                        child: IgnorePointer(
                          ignoring: opacity == 0,
                          child: Opacity(
                            opacity: opacity,
                            child: Obx(() {
                                final isOnline = _homeController.isOnline.value;
                                final orders = _rideStateMachine.activeOrders;
                                final hasActive = orders.any((o) => o.status != RideStatus.completed && o.status != RideStatus.failed && o.status != RideStatus.returned);
                                final hasFailed = orders.any((o) => o.status == RideStatus.failed);
                                final isReturning = !hasActive && hasFailed && orders.isNotEmpty;

                                return ElevatedButton(
                                  onPressed: () {
                                    if (isReturning) {
                                      _mapWidgetKey.currentState?.recenter(); 
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Retornando à base para devoluções...')),
                                      );
                                    } else {
                                      _homeController.toggleOnlineStatus(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isReturning 
                                        ? Colors.orangeAccent 
                                        : (isOnline ? Colors.redAccent : const Color(0xFF0055FF)),
                                    side: const BorderSide(color: Colors.black, width: 2.5),
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isReturning ? Icons.keyboard_return : (isOnline ? Icons.power_settings_new : Icons.play_arrow), 
                                        color: Colors.white
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        isReturning ? 'RETORNAR À BASE' : (isOnline ? 'FICAR OFFLINE' : 'FICAR ONLINE'),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                      ),
                                    ],
                                  ),
                                  );
                              }),
                          ),
                        ),
                      );
                    },
                  ),

                  // 4. Menu Lateral (Gatilho da Gaveta)
                  Positioned(
                    top: topPadding + 15,
                    left: 15,
                    child: HomeMenuIcon(settingsController: _settingsController),
                  ),

                  // 4.6 Botão Reativo da Máquina de Estados
                  Obx(() {
                    final state = _rideStateMachine.currentState.value;
                    if (state == RideState.idle) return const SizedBox.shrink();
                    return Positioned(
                      top: topPadding + 135,
                      left: 15,
                      child: FloatingActionButton.extended(
                        heroTag: 'ride_state_btn',
                        onPressed: _onStateMachineAction,
                        backgroundColor: state.buttonColor,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        icon: Icon(state.buttonIcon, size: 18),
                        label: Text(
                          state.buttonLabel,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                        ),
                      ),
                    );
                  }),

                  // 5. Botão Recentalizar
                  Positioned(
                    top: topPadding + 15,
                    right: 15,
                    child: RecenterMapButton(
                      settingsController: _settingsController,
                      onTap: () => _mapWidgetKey.currentState?.recenter(),
                    ),
                  ),

                  // 6. Botão SOS
                  Obx(() => _menuController.showPanicButton.value
                    ? Positioned(
                        top: topPadding + 75,
                        right: 15,
                        child: SOSEmergencyButton(settingsController: _settingsController),
                      )
                    : const SizedBox.shrink()),

                  // 7. Painel Inferior (Dragon Ball / ViperBottomSheetPanel)
                  Obx(() => ViperBottomSheetPanel(
                        key: _ridePanelKey,
                        isDark: isDark,
                        bottomSafePadding: safeBottomHeight,
                        rideStateMachine: _rideStateMachine,
                        menuController: _menuController,
                        settingsController: _settingsController,
                        onFinalize: () {
                          _rideStateMachine.reset();
                        },
                        isClt: _homeController.isClt,
                      )),

                  // 8. O REI DA TELA: Card de Convite (Super Rota)
                  Obx(() {
                    if (_rideStateMachine.currentState.value == RideState.offerReceived && _rideStateMachine.activeOrders.isNotEmpty) {
                      final orders = _rideStateMachine.activeOrders;
                      final first = orders.first;
                      final pos = _homeController.currentPosition.value;

                      // [VUP MODULAR] Cálculo de Rota Otimizada e Distâncias Reais (GPS)
                      final routeResult = ViperRoutingService.optimize(
                        driverLat: pos?.latitude ?? first.pickupLat,
                        driverLng: pos?.longitude ?? first.pickupLng,
                        pickupLat: first.pickupLat,
                        pickupLng: first.pickupLng,
                        orders: orders,
                      );

                      // Bloqueio de Rota Inválida (0.0 KM)
                      if (routeResult.totalDistance <= 0) return const SizedBox.shrink();

                      final firstRide = routeResult.optimizedOrders.first;
                      final lastRide = routeResult.optimizedOrders.last;
                      final totalValue = orders.fold(0.0, (sum, r) => sum + r.driverValue);
                      
                      // Regra de Negócio: Frotista (Company) vs Freelancer
                      final canDeclineOffer = !_homeController.isCompanyDriver;

                      final offer = ViperOffer(
                        id: firstRide.id,
                        orders: routeResult.optimizedOrders.map((r) => ViperOrder(
                          id: r.id,
                          cliente: r.clientName,
                          enderecoColeta: r.pickupAddress,
                          bairroColeta: '', 
                          enderecoEntrega: r.deliveryAddress,
                          bairroEntrega: r.deliveryNeighborhood,
                          tipo: ViperOrderType.entrega, 
                          valor: r.driverValue,
                          lat: r.lat,
                          lng: r.lng,
                          status: ViperOrderStatus.pending,
                        )).toList(),
                        distanciaTotal: routeResult.totalDistance,
                        valorTotal: totalValue,
                        valorPorKm: totalValue / routeResult.totalDistance, 
                        isSuper: orders.length > 1,
                        pickupNeighborhood: 'Ponto de Coleta',
                        pickupStreet: firstRide.pickupAddress,
                        dropoffNeighborhood: lastRide.deliveryNeighborhood,
                        dropoffStreet: lastRide.deliveryAddress,
                        distanciaDeslocamento: routeResult.distanceDriverToPickup,
                        valorKmIda: 0.85,
                        valorKmRota: routeResult.distancePickupToDeliveries > 0 ? (totalValue / routeResult.distancePickupToDeliveries) : 0.0,
                        pickupLat: firstRide.pickupLat,
                        pickupLng: firstRide.pickupLng,
                      );

                      return Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.6), // Escurece o fundo
                          child: ViperOfferOverlay(
                            offer: offer,
                            isDark: isDark,
                            canDecline: canDeclineOffer,
                            onAccept: () {
                              _rideStateMachine.acceptOffer(first.lat.toString(), first.lng.toString());
                            },
                            onDecline: () {
                              _rideStateMachine.rejectOffer();
                            },
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  
                  // Molduras de Sistema (Dinâmicas)
                  Positioned(top: 0, left: 0, right: 0, child: Container(height: topPadding, color: isDark ? Colors.black : Colors.white)),
                  Positioned(bottom: 0, left: 0, right: 0, child: Container(height: safeBottomHeight, color: isDark ? Colors.black : Colors.white)),
                ],
              ),
            ),
          ),
        );
    });
  }
}
