import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:viper_delivery/src/models/driver_model.dart';
import 'package:viper_delivery/src/modules/onboarding/services/upload_service.dart';
import 'dart:io';
import 'package:viper_delivery/src/core/services/location_service.dart';
import 'package:viper_delivery/src/core/utils/permission_helper.dart';
import 'package:permission_handler/permission_handler.dart';

class ViperMenuController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UploadService _uploadService = UploadService();
  
  bool isLoading = false;
  DriverModel? driverProfile;
  List<double> weeklyEarnings = List.filled(7, 0.0);
  String? errorMessage;

  // Estado Global da Localização Real
  double? userLatitude;
  double? userLongitude;

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

      // 3. Captura de Localização REAL
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        userLatitude = position.latitude;
        userLongitude = position.longitude;
      }

      // 4. Verificação de Sobreposição (Somente Android)
      if (Platform.isAndroid) {
        final status = await Permission.systemAlertWindow.status;
        print('[!!! VIPER !!!] Status Sobreposição: $status');
      }
      
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

  Future<void> finalizeRide({
    required ViperExecutionSummary summary,
    String? receiverName,
    String? receiverCpf,
    File? proofPhoto,
  }) async {
    // Simulação de delay para feedback visual solicitado
    await Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Sessão expirada.');

      String? photoUrl;
      if (proofPhoto != null) {
        photoUrl = await _uploadService.uploadFile(
          bucket: 'driver_documents', // Usando bucket existente para simplificação
          userId: user.id,
          docType: 'delivery_proof_${DateTime.now().millisecondsSinceEpoch}',
          file: proofPhoto,
        );
      }

      // Persistência no Supabase: Registrando o histórico da execução com Proof of Delivery
      await _supabase.from('ride_history').insert({
        'driver_id': user.id,
        'amount': summary.totalValue,
        'count_success': summary.countSuccess,
        'count_failed': summary.countFailed,
        'payment_status': summary.paymentStatus.name,
        'receiver_name': receiverName,
        'receiver_cpf': receiverCpf,
        'proof_photo_url': photoUrl,
        'completed_at': DateTime.now().toIso8601String(),
      });
      
      print('[!!! VIPER !!!] Checkout BLINDADO finalizado e persistido no Supabase.');
    } catch (e) {
      print('[!!! VIPER !!!] Erro no Checkout: $e');
      rethrow;
    }
  }
}
