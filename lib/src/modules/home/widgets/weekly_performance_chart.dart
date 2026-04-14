import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyPerformanceChart extends StatelessWidget {
  final List<double> earnings;
  final bool isDark;

  const WeeklyPerformanceChart({
    super.key,
    required this.earnings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black, 
          width: isDark ? 1.0 : 2.0,
        ),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => isDark ? Colors.black : Colors.white,
              tooltipBorder: BorderSide(
                color: isDark ? Colors.white24 : Colors.black,
                width: 1.5,
              ),
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'R\$ ${rod.toY.toStringAsFixed(2)}',
                  TextStyle(
                    color: isDark ? const Color(0xFF00FF88) : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: _getBottomTitles,
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _generateGroups(),
        ),
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (var value in earnings) {
      if (value > max) max = value;
    }
    return max == 0 ? 100 : max * 1.8; // Aumentado significativamente para dar respiro aos tooltips
  }

  List<BarChartGroupData> _generateGroups() {
    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: earnings[index],
            color: _getRodColor(),
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY() * 0.8,
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
        ],
      );
    });
  }

  Color _getRodColor() {
    // Modo Dia: Preto absoluto | Modo Noite: Verde/Azul Viper
    if (isDark) {
      return const Color(0xFF00FF88); // Verde Neon Viper
    }
    return Colors.black87;
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;
    switch (value.toInt()) {
      case 0: text = 'D'; break;
      case 1: text = 'S'; break;
      case 2: text = 'T'; break;
      case 3: text = 'Q'; break;
      case 4: text = 'Q'; break;
      case 5: text = 'S'; break;
      case 6: text = 'S'; break;
      default: text = ''; break;
    }
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(text, style: style),
    );
  }
}
