import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViperMenuController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool isLoading = false;
  Map<String, dynamic>? driverProfile;
  List<double> weeklyEarnings = List.filled(7, 0.0);
  String? errorMessage;

  Future<void> fetchAllData() async {
    _setLoading(true);
    errorMessage = null;
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Sessão expirada. Faça login novamente.');

      // 1. Fetch Profile and Vehicle data (Joined)
      final profileResponse = await _supabase
          .from('profiles')
          .select('*, vehicles(*)')
          .eq('id', user.id)
          .single();
      
      driverProfile = profileResponse;

      // 2. Fetch Weekly Earnings (Last 7 days)
      await _fetchWeeklyPerformance(user.id);
      
      notifyListeners();
    } catch (e) {
      errorMessage = 'Erro ao carregar dados: ${e.toString()}';
      debugPrint('ViperMenuController Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchWeeklyPerformance(String userId) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      // Assumindo tabela 'trips' com 'completed_at' e 'amount'
      // Se a tabela não existir, o catch lidará com isso e manteremos o gráfico em zero (mock amigável)
      final response = await _supabase
          .from('trips')
          .select('amount, completed_at')
          .eq('driver_id', userId)
          .gte('completed_at', sevenDaysAgo.toIso8601String())
          .order('completed_at');

      final List<dynamic> data = response as List<dynamic>;
      
      // Reset earnings
      weeklyEarnings = List.filled(7, 0.0);
      
      for (var trip in data) {
        final date = DateTime.parse(trip['completed_at']);
        // weekday: 1 (Seg) a 7 (Dom). 
        // Vamos ajustar para index 0-6 (Dom-Sab) se preferir, ou apenas 7 slots.
        // O usuário pediu 0 a 6 para Domingo a Sábado.
        final dayIndex = date.weekday % 7; 
        weeklyEarnings[dayIndex] += (trip['amount'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('Performance Query Error: Tabela trips pode não existir ainda. Usando faturamento zerado.');
      // Opcional: Se quiser mocks para teste enquanto a tabela não existe:
      // weeklyEarnings = [120.0, 450.0, 300.0, 600.0, 200.0, 800.0, 500.0];
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
