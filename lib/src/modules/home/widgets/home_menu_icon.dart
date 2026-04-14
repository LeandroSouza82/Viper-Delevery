import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

class HomeMenuIcon extends StatelessWidget {
  final SettingsController settingsController;

  const HomeMenuIcon({
    super.key,
    required this.settingsController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, child) {
        final isDark = settingsController.isDarkTheme;
        
        // Cores baseadas no tema para combinar com o StatsPillWidget
        final bgColor = isDark 
            ? Colors.black.withValues(alpha: 0.85) 
            : Colors.white;
        final iconColor = isDark ? Colors.white : Colors.black;
        final borderColor = isDark ? Colors.white12 : Colors.black;

        return GestureDetector(
          onTap: () {
            // Abre o Drawer do Scaffold lateral
            Scaffold.of(context).openDrawer();
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
              border: isDark 
                  ? Border.all(color: borderColor) 
                  : Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              Icons.home_rounded,
              color: iconColor,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}
