import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:viper_delivery/src/modules/home/widgets/viper_bottom_sheet_panel.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final SettingsController _settingsController = SettingsController();
  final HomeController _homeController = HomeController();
  final GlobalKey<ViperMapWidgetState> _mapWidgetKey = GlobalKey<ViperMapWidgetState>();
  final GlobalKey<ViperBottomSheetPanelState> _ridePanelKey = GlobalKey<ViperBottomSheetPanelState>();
  
  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(0.16);
  final ValueNotifier<List<ViperOrder>> _rideOrders = ValueNotifier<List<ViperOrder>>([]);
  final ValueNotifier<ViperOffer?> _activeOffer = ValueNotifier<ViperOffer?>(null);

  static const double _minExtent = 0.16;
  static const double _fadeLimit = 0.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settingsController.init();
      _homeController.initializeResilience(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sheetExtent.dispose();
    _rideOrders.dispose();
    _activeOffer.dispose();
    super.dispose();
  }

  void _onRadarPressed() {
    HapticFeedback.selectionClick();
    // Simula a chegada de uma nova oferta
    _activeOffer.value = ViperMockService.generateOffer();
  }

  void _onAcceptOffer(ViperOffer offer) {
    _rideOrders.value = [..._rideOrders.value, ...offer.orders];
    _activeOffer.value = null;
    
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
            systemNavigationBarColor: isDark ? Colors.black : Colors.white,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
            key: GlobalKey<ScaffoldState>(),
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            extendBody: true,
            drawer: ViperMenuCentral(settingsController: _settingsController),
            body: NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                _sheetExtent.value = notification.extent;
                return true;
              },
              child: Stack(
                children: [
                  // 1. Mapa
                  Positioned.fill(child: ViperMapWidget(key: _mapWidgetKey)),
                  
                  // 2. Painel Inferior (ViperBottomSheetPanel)
                  ViperBottomSheetPanel(
                    key: _ridePanelKey,
                    isDark: isDark,
                    bottomSafePadding: safeBottomHeight,
                    orders: _rideOrders,
                  ),

                  // 3. Botão Online/Offline (Fantasma)
                  ValueListenableBuilder<double>(
                    valueListenable: _sheetExtent,
                    builder: (context, extent, child) {
                      final opacity = ((_fadeLimit - extent) / (_fadeLimit - _minExtent)).clamp(0.0, 1.0);
                      final bottomPosition = (extent * screenHeight) + 25;

                      return Positioned(
                        bottom: bottomPosition,
                        left: 24,
                        right: 24,
                        child: IgnorePointer(
                          ignoring: opacity == 0,
                          child: Opacity(
                            opacity: opacity,
                            child: AnimatedBuilder(
                              animation: _homeController,
                              builder: (context, child) {
                                final isOnline = _homeController.isOnline;
                                return ElevatedButton(
                                  onPressed: () => _homeController.toggleOnlineStatus(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isOnline ? Colors.redAccent : const Color(0xFF0055FF),
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
                                      Icon(isOnline ? Icons.power_settings_new : Icons.play_arrow, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Text(
                                        isOnline ? 'FICAR OFFLINE' : 'FICAR ONLINE',
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

                  // 4. Overlay de Oferta
                  ValueListenableBuilder<ViperOffer?>(
                    valueListenable: _activeOffer,
                    builder: (context, offer, child) {
                      if (offer == null) return const SizedBox.shrink();
                      return Container(
                        color: Colors.black54,
                        child: ViperOfferOverlay(
                          offer: offer,
                          isDark: isDark,
                          onAccept: () => _onAcceptOffer(offer),
                          onDecline: () => _activeOffer.value = null,
                        ),
                      );
                    },
                  ),

                  // 5. HUD - Cápsula de Status
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

                  // 6. Coluna de Botões Flutuantes (Radar, Menu, Ajustes)
                  Positioned(
                    top: topPadding + 15,
                    left: 15,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HomeMenuIcon(settingsController: _settingsController),
                        const SizedBox(height: 12),
                        // RADAR (Simulador de Ofertas)
                        _buildFloatingButton(
                          icon: Icons.radar_rounded,
                          onPressed: _onRadarPressed,
                          isDark: isDark,
                          heroTag: 'radar_btn',
                        ),
                        const SizedBox(height: 12),
                        // AJUSTES
                        _buildFloatingButton(
                          icon: Icons.tune_rounded,
                          onPressed: () {},
                          isDark: isDark,
                          heroTag: 'tune_btn',
                        ),
                        const SizedBox(height: 12),
                        // CONFIGURAÇÕES
                        _buildFloatingButton(
                          icon: Icons.settings_rounded,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SettingsView(settingsController: _settingsController)),
                          ),
                          isDark: isDark,
                          heroTag: 'settings_btn',
                        ),
                      ],
                    ),
                  ),

                  // 7. Botão Recentalizar
                  Positioned(
                    top: topPadding + 15,
                    right: 15,
                    child: RecenterMapButton(
                      settingsController: _settingsController,
                      onTap: () => _mapWidgetKey.currentState?.recenter(),
                    ),
                  ),

                  // 8. Botão SOS
                  Positioned(
                    top: topPadding + 75,
                    right: 15,
                    child: SOSEmergencyButton(settingsController: _settingsController),
                  ),

                  // Molduras de Sistema
                  Positioned(top: 0, left: 0, right: 0, child: Container(height: topPadding, color: Colors.black)),
                  Positioned(bottom: 0, left: 0, right: 0, child: Container(height: safeBottomHeight, color: Colors.black)),
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
  }) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      foregroundColor: const Color(0xFF0055FF),
      elevation: 4,
      shape: CircleBorder(
        side: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 1),
      ),
      child: Icon(icon),
    );
  }
}
