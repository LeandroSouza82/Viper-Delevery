import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/controllers/home_controller.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_map_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _homeController = HomeController();

  @override
  void initState() {
    super.initState();
    // Inicia o fluxo de "blindagem" do app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeController.initializeResilience(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const ViperMapWidget(),
          // Barra de Status Online/Offline
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: AnimatedBuilder(
              animation: _homeController,
              builder: (context, child) {
                final isOnline = _homeController.isOnline;
                return ElevatedButton(
                  onPressed: () => _homeController.toggleOnlineStatus(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOnline ? Colors.redAccent : const Color(0xFF0055FF),
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
        ],
      ),
    );
  }
}
