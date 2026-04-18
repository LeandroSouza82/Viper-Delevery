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
import 'package:viper_delivery/src/modules/home/views/settings_view.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:viper_delivery/src/modules/home/services/viper_mock_service.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_offer_overlay.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_bottom_sheet_panel.dart';
import 'package:viper_delivery/src/modules/home/services/dispatch_service.dart';
import 'package:viper_delivery/src/modules/profile/controllers/performance_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final SettingsController _settingsController = SettingsController();
  final HomeController _homeController = HomeController();
  final ViperMenuController _menuController = Get.put(ViperMenuController());
  final PerformanceController _performanceController = Get.put(PerformanceController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ViperMapWidgetState> _mapWidgetKey = GlobalKey<ViperMapWidgetState>();
  final GlobalKey<ViperBottomSheetPanelState> _ridePanelKey = GlobalKey<ViperBottomSheetPanelState>();
  final DispatchService _dispatchService = DispatchService();
  
  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(0.16);
  final ValueNotifier<List<ViperOrder>> _rideOrders = ValueNotifier<List<ViperOrder>>([]);
  Timer? _offerTimer;
  StreamSubscription? _offerSubscription;

  static const double _minExtent = 0.16;
  static const double _fadeLimit = 0.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Escuta mudanças na oferta para disparar o timer de 12s
    _offerSubscription = _menuController.activeOffer.listen((_) => _onOfferChanged());
    
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
    _offerSubscription?.cancel();
    _offerTimer?.cancel();
    _sheetExtent.dispose();
    _rideOrders.dispose();
    _dispatchService.dispose();
    super.dispose();
  }

  void _onOfferChanged() {
    _offerTimer?.cancel();
    if (_menuController.activeOffer.value != null) {
      // Regra dos 12 segundos: se o motorista não agir, a oferta some
      _offerTimer = Timer(const Duration(seconds: 12), () {
        if (mounted) {
          print('[!!! VIPER !!!] Oferta expirada por tempo limite (12s).');
          _menuController.clearActiveOffer();
        }
      });
    }
  }

  // Lógica de Dispatch simplificada para rodar apenas em background (logs)
  void _startBackgroundDispatch() {
    _dispatchService.startSearch(initialValue: 15.0);
  }

  void _onRadarPressed() {
    HapticFeedback.selectionClick();
    // Simula a chegada de uma nova oferta aleatória
    _menuController.activeOffer.value = ViperMockService.generateOffer(
      userLat: _menuController.userLatitude,
      userLng: _menuController.userLongitude,
    );
  }

  void _onTestSimulation() {
    HapticFeedback.heavyImpact();
    // Agora o ciclo é controlado pelo MenuController (Super -> Entrega -> Coleta -> Serviço)
    _menuController.triggerNextTestOffer();
  }

  void _onAcceptOffer(ViperOffer offer) {
    _rideOrders.value = [..._rideOrders.value, ...offer.orders];
    _menuController.clearActiveOffer();
    
    // Pequeno delay para garantir que o overlay sumiu antes do painel subir
    Future.delayed(const Duration(milliseconds: 100), () {
      _ridePanelKey.currentState?.expandToHalf();
    });
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

    return ListenableBuilder(
      listenable: _settingsController,
      builder: (context, child) {
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
                            child: ListenableBuilder(
                              listenable: Listenable.merge([_homeController, _rideOrders]),
                              builder: (context, child) {
                                final isOnline = _homeController.isOnline;
                                final orders = _rideOrders.value;
                                final hasActive = orders.any((o) => o.status == ViperOrderStatus.pending);
                                final hasFailed = orders.any((o) => o.status == ViperOrderStatus.failed);
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
                              },
                            ),
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

                  // 4.5 Gatilho de Testes (Simulação de Super Rota)
                  Positioned(
                    top: topPadding + 75,
                    left: 15,
                    child: _buildFloatingButton(
                      icon: Icons.auto_awesome_motion_rounded,
                      onPressed: _onTestSimulation,
                      isDark: _settingsController.isDarkTheme,
                      heroTag: 'test_simulation_btn',
                      color: Colors.purpleAccent,
                    ),
                  ),

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
                        orders: _rideOrders,
                        offer: _menuController.activeOffer.value,
                        menuController: _menuController,
                        settingsController: _settingsController,
                        onFinalize: () {
                          _menuController.clearActiveOffer();
                        },
                        isClt: _homeController.isClt,
                      )),

                  // 8. O REI DA TELA: Overlay de Oferta
                  Obx(() {
                    final offer = _menuController.activeOffer.value;
                    if (offer == null) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black.withOpacity(0.6),
                      child: ViperOfferOverlay(
                        offer: offer,
                        isDark: isDark,
                        onAccept: () => _onAcceptOffer(offer),
                        onDecline: () => _menuController.clearActiveOffer(),
                      ),
                    );
                  }),

                  // Molduras de Sistema (Dinâmicas)
                  Positioned(top: 0, left: 0, right: 0, child: Container(height: topPadding, color: isDark ? Colors.black : Colors.white)),
                  Positioned(bottom: 0, left: 0, right: 0, child: Container(height: safeBottomHeight, color: isDark ? Colors.black : Colors.white)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    required String heroTag,
    Color? color,
  }) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      foregroundColor: color ?? const Color(0xFF0055FF),
      elevation: 4,
      shape: CircleBorder(
        side: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 1),
      ),
      child: Icon(icon),
    );
  }
}
