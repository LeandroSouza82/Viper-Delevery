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

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final SettingsController _settingsController = SettingsController();
  final HomeController _homeController = HomeController();
  final GlobalKey<ViperMapWidgetState> _mapWidgetKey = GlobalKey<ViperMapWidgetState>();
  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(0.16);

  static const double _minExtent = 0.16;
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
    super.dispose();
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
              
              // 2. DraggableScrollableSheet (Agora fica 'Atrás' do botão na hierarquia)
              DraggableScrollableSheet(
                initialChildSize: _minExtent,
                minChildSize: _minExtent,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Novo Cabeçalho com Ícones de Controle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.blueGrey),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SettingsView(settingsController: _settingsController)),
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _homeController,
                              builder: (context, child) {
                                final isOnline = _homeController.isOnline;
                                return Text(
                                  isOnline ? 'Aguardando Pedidos...' : 'Você está Offline',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.tune, color: Colors.blueGrey),
                              onPressed: () {
                                // Ação de Filtros/Ajustes
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: _homeController,
                          builder: (context, child) {
                            final isOnline = _homeController.isOnline;
                            return Text(
                              isOnline 
                                ? 'Fique atento! Novas corridas aparecerão aqui.'
                                : 'Fique online para ver as corridas disponíveis na sua região.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                        // Garantia de que o conteúdo não seja cortado pela moldura preta
                        SizedBox(height: safeBottomHeight + 20),
                      ],
                    ),
                  );
                },
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

              // 4.1 ÍCONE DE MENU (Casinha)
              Positioned(
                top: topPadding + 15,
                left: 15,
                child: HomeMenuIcon(
                  settingsController: _settingsController,
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
