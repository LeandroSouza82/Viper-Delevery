import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:viper_delivery/src/modules/home/controllers/home_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/widgets/stats_pill_widget.dart';
import 'package:viper_delivery/src/modules/home/widgets/home_menu_icon.dart';
import 'package:viper_delivery/src/modules/home/widgets/recenter_map_button.dart';
import 'package:viper_delivery/src/modules/home/widgets/sos_emergency_button.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_menu_central.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_map_widget.dart';

import 'package:viper_delivery/src/models/ride_model.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_bottom_sheet_panel.dart';
import 'package:viper_delivery/src/modules/home/services/dispatch_service.dart';
import 'package:viper_delivery/src/modules/profile/controllers/performance_controller.dart';
import 'package:viper_delivery/src/modules/profile/controllers/profile_controller.dart';
import 'package:viper_delivery/src/modules/map/controllers/map_controller.dart';
import 'package:viper_delivery/src/modules/ride/controllers/ride_state_machine.dart';
import 'package:viper_delivery/src/modules/home/services/external_navigation_service.dart';

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
  final ProfileController _profileController = Get.put(ProfileController()); // Inicialização Global para o SOS
  final MapController _mapController = Get.put(MapController());
  final RideStateMachine _rideStateMachine = Get.put(RideStateMachine());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ViperMapWidgetState> _mapWidgetKey = GlobalKey<ViperMapWidgetState>();
  final GlobalKey<ViperBottomSheetPanelState> _ridePanelKey = GlobalKey<ViperBottomSheetPanelState>();
  final DispatchService _dispatchService = DispatchService();
  
  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(0.16);

  static const double _minExtent = 0.16;
  static const double _fadeLimit = 0.5;

  @override
  void initState() {
    super.initState();
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
    _dispatchService.dispose();
    super.dispose();
  }

  // Lógica de Dispatch simplificada para rodar apenas em background (logs)
  void _startBackgroundDispatch() {
    _dispatchService.startSearch(initialValue: 15.0);
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
            .where((o) => o.status == RideStatus.pending)
            .toList();
        final optimized = await _rideStateMachine.startDeliveryRoute(pendingOrders);
        // Atualiza a lista com a ordem otimizada
        final nonPending = _rideStateMachine.activeOrders
            .where((o) => o.status != RideStatus.pending)
            .toList();
        _rideStateMachine.activeOrders.assignAll([...nonPending, ...optimized]);

        // Abre o GPS externo apontando para o PRIMEIRO destino otimizado
        if (optimized.isNotEmpty && mounted) {
          await ExternalNavigationService.abrirNavegador(
            lat: optimized.first.lat,
            lng: optimized.first.lng,
            context: context,
          );
        }
        break;

      case RideState.onDeliveryRoute:
        // Navega para o próximo destino pendente
        final nextPending = _rideStateMachine.activeOrders
            .where((o) => o.status == RideStatus.pending || o.status == RideStatus.onDeliveryRoute)
            .toList();
        if (nextPending.isNotEmpty && mounted) {
          await ExternalNavigationService.abrirNavegador(
            lat: nextPending.first.lat,
            lng: nextPending.first.lng,
            context: context,
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
                    child: Center(
                      child: StatsPillWidget(
                        homeController: _homeController,
                        settingsController: _settingsController,
                      ),
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

                  // 8. O REI DA TELA: Removido Mock Overlay pois agora os dados vem da Stream
                  
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
