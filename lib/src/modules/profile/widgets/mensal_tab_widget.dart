import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/profile/controllers/performance_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

class MensalTabWidget extends StatelessWidget {
  const MensalTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PerformanceController>();
    final isDark = Get.find<SettingsController>().isDarkTheme;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100];

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF88)));
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            // Cabeçalho Centralizado Reativo
            Column(
              children: [
                Text(
                  'Total do Mês',
                  style: TextStyle(
                    color: textColor.withOpacity(0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'R\$ ${controller.totalMensal.value.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 48),

            // Grid de Métricas Reativo (Dashboard)
            Row(
              children: [
                _buildMetricCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Dias Trabalhados',
                  value: '${controller.diasTrabalhadosMes.value} dias',
                  color: Colors.blueAccent,
                  bgColor: cardBg!,
                  textColor: textColor,
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  icon: Icons.access_time_rounded,
                  label: 'Horas Online',
                  value: '${controller.horasOnlineMes.value}h',
                  color: const Color(0xFF00FF88),
                  bgColor: cardBg,
                  textColor: textColor,
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'Corridas',
                  value: '${controller.corridasMes.value}',
                  color: Colors.orangeAccent,
                  bgColor: cardBg,
                  textColor: textColor,
                ),
              ],
            ),
            
            const SizedBox(height: 48),
            
            Opacity(
              opacity: 0.3,
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 20, color: textColor.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  Text(
                    'Este é um resumo do faturamento bruto mensal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: textColor.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withOpacity(0.4),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
