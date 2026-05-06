import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/home/controllers/home_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

class StatsPillWidget extends StatelessWidget {
  final HomeController homeController;
  final SettingsController settingsController;

  const StatsPillWidget({
    super.key,
    required this.homeController,
    required this.settingsController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = settingsController.isDarkTheme;
      final mode = homeController.displayMode.value;
      
      final bgColor = isDark 
          ? Colors.black.withValues(alpha: 0.85) 
          : Colors.white.withValues(alpha: 0.9);
      final textColor = isDark ? Colors.white : Colors.black87;
      final borderColor = isDark ? Colors.white12 : Colors.black12;

      return GestureDetector(
        onTap: () {
          homeController.cycleDisplayMode();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: _getBorderColor(mode, borderColor),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(mode),
              const SizedBox(width: 10),
              _buildContent(mode, textColor),
              // Pequeno indicador de conexão sempre visível como um ponto
              const SizedBox(width: 12),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: homeController.isOnline.value ? Colors.green : Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Color _getBorderColor(PillDisplayMode mode, Color defaultColor) {
    switch (mode) {
      case PillDisplayMode.earnings:
        return Colors.green.withValues(alpha: 0.4);
      case PillDisplayMode.mission:
        return Colors.blueAccent.withValues(alpha: 0.4);
      case PillDisplayMode.rating:
        return Colors.amber.withValues(alpha: 0.4);
    }
  }

  Widget _buildIcon(PillDisplayMode mode) {
    IconData icon;
    Color color;

    // Se for frotista e estiver no modo ganhos (fallback de segurança), força missão
    final effectiveMode = (homeController.isCompanyDriver && mode == PillDisplayMode.earnings)
        ? PillDisplayMode.mission
        : mode;

    switch (effectiveMode) {
      case PillDisplayMode.earnings:
        icon = Icons.payments_outlined;
        color = Colors.greenAccent;
        break;
      case PillDisplayMode.mission:
        icon = Icons.emoji_events_outlined;
        color = (homeController.isCompanyDriver) ? Colors.blueGrey : Colors.blueAccent;
        break;
      case PillDisplayMode.rating:
        icon = Icons.star;
        color = Colors.amber;
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: Icon(icon, key: ValueKey(effectiveMode), color: color, size: 22),
    );
  }

  Widget _buildContent(PillDisplayMode mode, Color textColor) {
    String label;
    String value;
    Color valueColor;

    // Se for frotista e estiver no modo ganhos (fallback de segurança), força missão
    final effectiveMode = (homeController.isCompanyDriver && mode == PillDisplayMode.earnings)
        ? PillDisplayMode.mission
        : mode;

    switch (effectiveMode) {
      case PillDisplayMode.earnings:
        label = 'GANHOS HOJE';
        value = 'R\$ 342,80';
        valueColor = Colors.green;
        break;
      case PillDisplayMode.mission:
        label = (homeController.isCompanyDriver) ? 'STATUS FROTA' : 'MISSÃO ATIVA';
        value = (homeController.isCompanyDriver) ? 'ATIVA' : '2/5';
        valueColor = (homeController.isCompanyDriver) ? textColor : Colors.blueAccent;
        break;
      case PillDisplayMode.rating:
        label = 'AVALIAÇÃO';
        value = '4.98';
        valueColor = textColor;
        break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.4),
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            value,
            key: ValueKey(value),
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

