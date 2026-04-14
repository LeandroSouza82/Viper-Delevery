import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:viper_delivery/src/modules/home/controllers/home_controller.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_map_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _homeController = HomeController();
  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(0.16);

  static const double _minExtent = 0.16;
  static const double _fadeLimit = 0.5;

  @override
  void initState() {
    super.initState();
    // Inicia o fluxo de "blindagem" do app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeController.initializeResilience(context);
    });
  }

  @override
  void dispose() {
    _sheetExtent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeBottomHeight = bottomPadding > 0 ? bottomPadding : 30.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Força ícones brancos (Android)
        statusBarBrightness: Brightness.dark, // Força ícones brancos (iOS)
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        body: NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            _sheetExtent.value = notification.extent;
            return true;
          },
          child: Stack(
            children: [
              // 1. Mapa como fundo total
              const Positioned.fill(child: ViperMapWidget()),
              
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
                        const SizedBox(height: 24),
                        const Text(
                          'Aguardando Pedidos...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fique online para ver as corridas disponíveis na sua região.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                        ),
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

              // 4. MOLDURAS FIXAS DE PROTEÇÃO (Sempre no topo da Stack)
              // Barra Superior
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: topPadding,
                  color: Colors.black,
                ),
              ),
              // Barra Inferior
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
  }
}
