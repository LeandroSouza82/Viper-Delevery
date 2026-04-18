import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/profile/controllers/profile_controller.dart';
import 'package:viper_delivery/src/modules/profile/widgets/emergency_contact_modal.dart';
import 'package:viper_delivery/src/core/services/haptic_service.dart';

class SOSEmergencyButton extends StatelessWidget {
  final SettingsController settingsController;

  const SOSEmergencyButton({
    super.key,
    required this.settingsController,
  });

  Future<void> _launchSOS() async {
    final profileController = Get.find<ProfileController>();
    await profileController.dispararSosElite();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, child) {
        final isDark = settingsController.isDarkTheme;
        
        final bgColor = isDark 
            ? const Color(0xFF121212).withOpacity(0.9) 
            : Colors.white;
        const iconColor = Colors.redAccent;
        final borderColor = isDark ? Colors.redAccent.withOpacity(0.5) : Colors.red.withOpacity(0.3);

        return GestureDetector(
          onTap: () {
            final profileController = Get.find<ProfileController>();
            if (profileController.emergencyPhone.value.isEmpty) {
              HapticService.vibrateViperPulse();
              Get.bottomSheet(
                EmergencyContactModal(controller: profileController),
                isScrollControlled: true,
                ignoreSafeArea: false,
              );
            } else {
              Get.snackbar(
                'SOS Elite', 
                'Segure firme por 1 segundo para disparar o socorro!',
                backgroundColor: Colors.redAccent.withOpacity(0.9),
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                margin: const EdgeInsets.all(15),
              );
            }
          },
          onLongPress: _launchSOS,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
// ...
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                // Efeito Red Neon Glow intenso
                BoxShadow(
                  color: Colors.red.withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: iconColor,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}
