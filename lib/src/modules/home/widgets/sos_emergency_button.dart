import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:viper_delivery/src/core/services/haptic_service.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/profile/controllers/profile_controller.dart';
import 'package:viper_delivery/src/modules/profile/widgets/emergency_contact_modal.dart';

class SOSEmergencyButton extends StatefulWidget {
  final SettingsController settingsController;

  const SOSEmergencyButton({
    super.key,
    required this.settingsController,
  });

  @override
  State<SOSEmergencyButton> createState() => _SOSEmergencyButtonState();
}

class _SOSEmergencyButtonState extends State<SOSEmergencyButton> with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _isHolding = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.9,
      upperBound: 1.1,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _isHolding = true;
      _pulseController.repeat(reverse: true);
    });
    
    _timer = Timer(const Duration(seconds: 2), () {
      _onTrigger();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      _isHolding = false;
      _pulseController.stop();
      _pulseController.value = 1.0;
    });
  }

  Future<void> _onTrigger() async {
    _cancelTimer();
    
    // Feedback de disparo
    HapticFeedback.heavyImpact();
    
    try {
      final profileController = Get.find<ProfileController>();
      await profileController.dispararSosElite();
    } catch (e) {
      debugPrint('Erro ao encontrar ProfileController: $e');
      // Fallback de segurança: Se o controller sumir, abre o 190 direto
      final Uri telUri = Uri(scheme: 'tel', path: '190');
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settingsController,
      builder: (context, child) {
        final isDark = widget.settingsController.isDarkTheme;
        
        final bgColor = isDark 
            ? const Color(0xFF121212).withValues(alpha: 0.9) 
            : Colors.white;
        const iconColor = Colors.redAccent;
        final borderColor = isDark ? Colors.redAccent.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.3);

        return GestureDetector(
          onLongPressStart: (_) => _startTimer(),
          onLongPressEnd: (_) => _cancelTimer(),
          onLongPressCancel: () => _cancelTimer(),
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
                'Segure firme por 2 segundos para disparar o socorro!',
                backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                margin: const EdgeInsets.all(15),
              );
            }
          },
          child: ScaleTransition(
            scale: _pulseController,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isHolding ? 0.6 : 1.0,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: [
                    // Efeito Red Neon Glow intenso
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.6),
                      blurRadius: _isHolding ? 25 : 15,
                      spreadRadius: _isHolding ? 4 : 2,
                    ),
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                      blurRadius: _isHolding ? 40 : 30,
                      spreadRadius: _isHolding ? 8 : 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: iconColor,
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
