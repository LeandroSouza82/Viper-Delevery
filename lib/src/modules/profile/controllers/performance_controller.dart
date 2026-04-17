import 'package:get/get.dart';

class PerformanceController extends GetxController {
  // Comentado temporariamente para evitar erro de tabela inexistente no Supabase
  // final PerformanceService _service = PerformanceService();
  
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
    _loadMockData(); // Injeta dados falsos para renderização visual
  }

  void _loadMockData() {
    isLoading.value = true;
    
    // Simula um pequeno delay de carregamento para UX
    Future.delayed(const Duration(milliseconds: 800), () {
      totalSemana.value = 854.20;
      dadosGrafico.value = [
        120.50, // Segunda
        85.00,  // Terça
        210.00, // Quarta
        0.00,   // Quinta
        150.00, // Sexta
        90.00,  // Sábado
        198.70  // Domingo
      ];
      
      // Mock Mensal
      totalMensal.value = 3450.00;
      diasTrabalhadosMes.value = 22;
      horasOnlineMes.value = 145;
      corridasMes.value = 310;
      
      diaSelecionado.value = DateTime.now().weekday - 1;
      isLoading.value = false;
    });
  }

  void selecionarDia(int index) {
    diaSelecionado.value = index;
  }

  String getNomeDia(int index) {
    const dias = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
    return dias[index];
  }
}
