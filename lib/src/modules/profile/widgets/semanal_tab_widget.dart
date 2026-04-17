import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/profile/controllers/performance_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

class SemanalTabWidget extends StatelessWidget {
  const SemanalTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PerformanceController());
    final isDark = Get.find<SettingsController>().isDarkTheme;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF88)));
      }

      final maxVal = controller.dadosGrafico.reduce((a, b) => a > b ? a : b);
      final hasData = maxVal > 0;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL DA SEMANA',
                      style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${controller.totalSemana.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Gráfico (Altura Fixa para evitar Infinity)
            SizedBox(
              height: 250,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final val = controller.dadosGrafico[index];
                  final isSelected = controller.diaSelecionado.value == index;
                  
                  // Altura proporcional para a barra dentro do Expanded
                  final double percentage = hasData ? (val / maxVal) : 0;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => controller.selecionarDia(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 1. Área fixa para o texto flutuante (não empurra o layout)
                          SizedBox(
                            height: 30,
                            child: isSelected 
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'R\$ ${val.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF00FF88) : Colors.black,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 4),

                          // 2. A barra que preenche o resto do espaço (Proporcional)
                          Expanded(
                            child: FractionallySizedBox(
                              heightFactor: percentage.clamp(0.02, 1.0),
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isSelected
                                        ? [const Color(0xFF00FF88), const Color(0xFF00DD77)]
                                        : [
                                            textColor.withOpacity(0.05),
                                            textColor.withOpacity(0.02)
                                          ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF00FF88).withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 3. Dia da semana
                          Text(
                            controller.getNomeDia(index),
                            style: TextStyle(
                              color: isSelected 
                                  ? const Color(0xFF00FF88) 
                                  : (isDark ? Colors.white70 : Colors.black54),
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Card Informativo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.01),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars_rounded, color: Color(0xFF00FF88), size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance Semanal',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Mantenha a constância para atingir suas metas.',
                          style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
