import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

class RecenterMapButton extends StatelessWidget {
  final SettingsController settingsController;
  final VoidCallback onTap;

  const RecenterMapButton({
    super.key,
    required this.settingsController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, child) {
        final isDark = settingsController.isDarkTheme;
        
        // Cores baseadas no padrão modular da Casinha/Comprimido
        final bgColor = isDark 
            ? Colors.black.withOpacity(0.7) 
            : Colors.white;
        final iconColor = isDark ? Colors.white : Colors.black;
        final borderColor = isDark ? Colors.white24 : Colors.black;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.my_location_rounded,
              color: iconColor,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}
