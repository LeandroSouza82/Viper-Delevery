import 'dart:io';

import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/core/services/location_service.dart';
import 'package:viper_delivery/src/models/driver_model.dart';
import 'package:viper_delivery/src/models/ride_model.dart';
import 'package:viper_delivery/src/modules/onboarding/services/upload_service.dart';

class ViperMenuController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UploadService _uploadService = UploadService();
  
  bool isLoading = false;
  DriverModel? driverProfile;
  List<double> weeklyEarnings = List.filled(7, 0.0);
  
  // Novas métricas de performance
  double dailyEarnings = 0.0;
  int dailyDeliveries = 0;
  double monthlyEarnings = 0.0;
  int monthlyDeliveries = 0;

  String? errorMessage;

  // Estado Global da Localização Real
  double? userLatitude;
  double? userLongitude;

  // Controle de Visibilidade do Botão do Pânico (SOS) - GetX RX
  var showPanicButton = true.obs;

  Future<void> fetchAllData() async {
    debugPrint('[!!! VIPER !!!] MenuController: Iniciando fetchAllData...');
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
          debugPrint('[!!! VIPER !!!] Foto não encontrada no banco. Usando fallback de metadados: $metadataPhoto');
          driverProfile = driverProfile?.copyWith(avatarUrl: metadataPhoto);
        }
      }

      debugPrint('[!!! VIPER !!!] Perfil carregado -> Nome: ${driverProfile?.firstName}, Avatar: ${driverProfile?.avatarUrl}');

      // 2. Fetch Weekly/Daily/Monthly Performance
      await _fetchPerformanceData(user.id);

      // 3. Captura de Localização REAL
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        userLatitude = position.latitude;
        userLongitude = position.longitude;
      }

      // 4. Verificação de Sobreposição (Somente Android)
      if (Platform.isAndroid) {
        final status = await Permission.systemAlertWindow.status;
        debugPrint('[!!! VIPER !!!] Status Sobreposição: $status');
      }
      
      update();
    } catch (e) {
      errorMessage = 'Erro ao carregar dados: ${e.toString()}';
      debugPrint('[!!! VIPER !!!] ERROR no MenuController: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchPerformanceData(String userId) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      final response = await _supabase
          .from('trips')
          .select('amount, completed_at')
          .eq('driver_id', userId)
          .gte('completed_at', startOfMonth.toIso8601String())
          .order('completed_at');

      final List<dynamic> data = response as List<dynamic>;
      
      // Reset metrics
      weeklyEarnings = List.filled(7, 0.0);
      dailyEarnings = 0.0;
      dailyDeliveries = 0;
      monthlyEarnings = 0.0;
      monthlyDeliveries = 0;

      for (var trip in data) {
        final date = DateTime.parse(trip['completed_at']);
        final amount = (trip['amount'] as num).toDouble();

        // Total Mensal
        monthlyEarnings += amount;
        monthlyDeliveries++;

        // Faturamento Diário (Hoje)
        if (date.day == now.day && date.month == now.month && date.year == now.year) {
          dailyEarnings += amount;
          dailyDeliveries++;
        }

        // Gráfico Semanal (7 dias)
        if (date.isAfter(sevenDaysAgo)) {
          final dayIndex = date.weekday % 7; 
          weeklyEarnings[dayIndex] += amount;
        }
      }
    } catch (e) {
      // Falha silenciosa no fetch de performance
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
      
      debugPrint('[!!! VIPER !!!] Pix Key atualizada com sucesso: $newKey');
      update();
    } catch (e) {
      errorMessage = 'Erro ao atualizar Pix: $e';
      debugPrint('[!!! VIPER !!!] ERROR ao atualizar Pix: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    update();
  }

  Future<void> finalizeRide({
    required RideExecutionSummary summary,
    required List<String> rideIds,
    String? receiverName,
    String? receiverCpf,
    File? proofPhoto,
  }) async {
    debugPrint('>>> [CHECKOUT] Iniciando persistência final para ${rideIds.length} corridas');
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Sessão expirada.');

      String? photoUrl;
      if (proofPhoto != null) {
        photoUrl = await _uploadService.uploadFile(
          bucket: 'driver_documents',
          userId: user.id,
          docType: 'delivery_proof_${DateTime.now().millisecondsSinceEpoch}',
          file: proofPhoto,
        );
      }

      // 1. Atualizar status e metadados de todas as rotas do lote (Sweep Update)
      if (rideIds.isNotEmpty) {
        await _supabase
            .from('rides')
            .update({
              'status': 'completed',
              'receiver_name': receiverName,
              'receiver_cpf': receiverCpf,
              'proof_photo_url': photoUrl,
            })
            .inFilter('id', rideIds);
      }

      debugPrint('[!!! VIPER !!!] Checkout finalizado e persistido com sucesso.');
    } catch (e) {
      debugPrint('[!!! VIPER !!!] ERRO NO CHECKOUT: $e');
      rethrow;
    }
  }
}

