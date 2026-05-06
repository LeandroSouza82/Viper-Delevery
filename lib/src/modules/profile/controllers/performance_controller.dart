import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/modules/profile/services/performance_service.dart';

class PerformanceController extends GetxController {
  final PerformanceService _service = PerformanceService();
  
  final isLoading = true.obs;
  final totalSemana = 0.0.obs;
  final diaSelecionado = (-1).obs;
  final dadosGrafico = <double>[0, 0, 0, 0, 0, 0, 0].obs; // Seg a Dom

  // Observáveis Mensais
  final totalMensal = 0.0.obs;
  final diasTrabalhadosMes = 0.obs;
  final horasOnlineMes = 0.obs;
  final corridasMes = 0.obs;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final weeklyData = await _service.getWeeklyPerformance(user.id);
      _processWeeklyData(weeklyData);

      final monthlyData = await _service.getMonthlyPerformance(user.id);
      _processMonthlyData(monthlyData);

      diaSelecionado.value = (DateTime.now().weekday % 7); // 0 = Domingo, 1 = Segunda...
      
    } catch (e) {
      debugPrint('Error loading performance data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _processWeeklyData(List<Map<String, dynamic>> data) {
    double total = 0;
    List<double> dailyValues = List.filled(7, 0.0);
    
    for (var ride in data) {
      if (ride['created_at'] == null) continue;
      final date = DateTime.parse(ride['created_at']).toLocal();
      final value = (ride['driver_value'] as num).toDouble();
      
      total += value;
      final dayIndex = date.weekday % 7; // 0=Sun, 1=Mon...
      dailyValues[dayIndex] += value;
    }
    
    totalSemana.value = total;
    dadosGrafico.value = dailyValues;
  }

  void _processMonthlyData(List<Map<String, dynamic>> data) {
    double total = 0;
    Set<int> daysWorked = {};
    
    for (var ride in data) {
      if (ride['created_at'] == null) continue;
      final date = DateTime.parse(ride['created_at']).toLocal();
      final value = (ride['driver_value'] as num).toDouble();
      
      total += value;
      daysWorked.add(date.day);
    }
    
    totalMensal.value = total;
    corridasMes.value = data.length;
    diasTrabalhadosMes.value = daysWorked.length;
    // Horas online precisariam de uma tabela de logs de sessão, mantemos 0 por enquanto ou mock proporcional
    horasOnlineMes.value = daysWorked.length * 8; 
  }

  void selecionarDia(int index) {
    diaSelecionado.value = index;
  }

  String getNomeDia(int index) {
    const dias = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
    return dias[index];
  }
}

