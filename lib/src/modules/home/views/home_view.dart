import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:viper_delivery/src/modules/home/controllers/home_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/widgets/stats_pill_widget.dart';
import 'package:viper_delivery/src/modules/home/widgets/home_menu_icon.dart';
import 'package:viper_delivery/src/modules/home/widgets/recenter_map_button.dart';
import 'package:viper_delivery/src/modules/home/widgets/sos_emergency_button.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_menu_central.dart';
import 'package:viper_delivery/src/modules/home/services/viper_mock_service.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_bottom_sheet_panel.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_map_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final SettingsController _settingsController = SettingsController();
  final HomeController _homeController = HomeController();
  final GlobalKey<ViperMapWidgetState> _mapWidgetKey = GlobalKey<ViperMapWidgetState>();
  final GlobalKey<ViperBottomSheetPanelState> _ridePanelKey =
      GlobalKey<ViperBottomSheetPanelState>();
  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(0.1);
  final ValueNotifier<List<ViperOrder>> _rideOrders = ValueNotifier<List<ViperOrder>>([]);
  final ValueNotifier<int> _rideWave = ValueNotifier<int>(0);

  static const double _minExtent = 0.1;
  static const double _fadeLimit = 0.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicia o fluxo de "blindagem" do app e configurações
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
    _rideWave.dispose();
    super.dispose();
  }

  void _onSimulateRide() {
    HapticFeedback.heavyImpact();
    _rideOrders.value = ViperMockService.generateRandomRide();
    _rideWave.value++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ridePanelKey.currentState?.expandToHalf();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reavalia o tema automático ao voltar para o app
      _settingsController.reevaluateAutoTheme();
    }
  }

  /// Exibe o Modal de Configurações Premium (Versão Clean com Dropdowns)
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeBottomHeight = bottomPadding > 0 ? bottomPadding : 30.0;

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
            key: GlobalKey<ScaffoldState>(), // Opcional, mas útil para Drawer
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
              // 1. Mapa como fundo total
              Positioned.fill(child: ViperMapWidget(key: _mapWidgetKey)),
              
              // 2. Super Rota (painel deslizante sobre o mapa)
              ViperBottomSheetPanel(
                key: _ridePanelKey,
                isDark: isDark,
                bottomSafePadding: safeBottomHeight,
                orders: _rideOrders,
                rideWave: _rideWave,
              ),

              // 3. Botão "Fantasma" (Sempre no topo para nunca ser escondido)
              ValueListenableBuilder<double>(
                valueListenable: _sheetExtent,
                builder: (context, extent, child) {
                  final opacity = ((_fadeLimit - extent) / (_fadeLimit - _minExtent)).clamp(0.0, 1.0);
                  // Posição ajustada: O botão 'surfa' sempre acima da barra branca
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
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
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
              // 4. MOLDURA DE TOPO: Cápsula de Status Premium
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

              // 4.1 ÍCONE DE MENU (Casinha) + simulação de corrida
              Positioned(
                top: topPadding + 15,
                left: 15,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HomeMenuIcon(
                      settingsController: _settingsController,
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'viper_simulate_ride',
                      tooltip: 'Simular corrida (mock)',
                      onPressed: _onSimulateRide,
                      backgroundColor:
                          isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      foregroundColor: const Color(0xFF0055FF),
                      elevation: isDark ? 4 : 2,
                      shape: CircleBorder(
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black26,
                          width: 1,
                        ),
                      ),
                      child: const Icon(Icons.radar_rounded),
                    ),
                  ],
                ),
              ),

              // 4.2 BOTÃO DE RECENTRALIZAR (Canto Superior Direito)
              Positioned(
                top: topPadding + 15,
                right: 15,
                child: RecenterMapButton(
                  settingsController: _settingsController,
                  onTap: () => _mapWidgetKey.currentState?.recenter(),
                ),
              ),

              // 4.3 BOTÃO DE EMERGÊNCIA SOS (Abaixo do Recenter)
              Positioned(
                top: topPadding + 75,
                right: 15,
                child: SOSEmergencyButton(
                  settingsController: _settingsController,
                ),
              ),

              // 5. BARRA PRETA DE STATUS (Simulando relógio/bateria)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: topPadding,
                  color: Colors.black,
                ),
              ),

              // 7. Barra Inferior (Proteção SafeArea)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: safeBottomHeight,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
  }
}
