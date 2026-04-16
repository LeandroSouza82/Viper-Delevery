import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/models/driver_model.dart';

class ViperMenuController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool isLoading = false;
  DriverModel? driverProfile;
  List<double> weeklyEarnings = List.filled(7, 0.0);
  String? errorMessage;

  Future<void> fetchAllData() async {
    print('--------------------------------------------------');
    print('[!!! VIPER !!!] MenuController: Iniciando fetchAllData...');
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
      
      driverProfile = DriverModel.fromMap(profileResponse);
      
      // FALLBACK SÊNIOR: Se não estiver no banco, tenta pegar nos metadados do Auth
      if (driverProfile?.avatarUrl == null || driverProfile!.avatarUrl!.isEmpty) {
        final metadataPhoto = user.userMetadata?['avatar_url'];
        if (metadataPhoto != null) {
          print('[!!! VIPER !!!] Foto não encontrada no banco. Usando fallback de metadados: $metadataPhoto');
          driverProfile = driverProfile?.copyWith(avatarUrl: metadataPhoto);
        }
      }

      print('[!!! VIPER !!!] Perfil carregado -> Nome: ${driverProfile?.firstName}, Avatar: ${driverProfile?.avatarUrl}');

      // 2. Fetch Weekly Earnings (Last 7 days)
      await _fetchWeeklyPerformance(user.id);
      
      notifyListeners();
    } catch (e) {
      errorMessage = 'Erro ao carregar dados: ${e.toString()}';
      print('[!!! VIPER !!!] ERROR no MenuController: $e');
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

  Future<void> updatePixKey(String newKey) async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Sessão expirada.');

      await _supabase
          .from('profiles')
          .update({'pix_key': newKey})
          .eq('id', user.id);

      // Atualiza o modelo local para refletir na UI instantaneamente
      if (driverProfile != null) {
        driverProfile = driverProfile!.copyWith(pixKey: newKey);
      }
      
      print('[!!! VIPER !!!] Pix Key atualizada com sucesso: $newKey');
      notifyListeners();
    } catch (e) {
      errorMessage = 'Erro ao atualizar Pix: $e';
      print('[!!! VIPER !!!] ERROR ao atualizar Pix: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
