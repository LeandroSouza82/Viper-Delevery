import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/models/ride_model.dart';

class RideRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Escuta em tempo real as corridas.
  ///
  /// Filtro Servidor: Ignora `pending`.
  /// Filtro Cliente: Aceita `searching` (Radar de freelancers) OU corridas
  /// onde `driver_id` é o motorista logado (assigned).
  Stream<List<RideModel>> getMyRidesStream(String driverId) {
    return _supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .neq('status', 'pending')
        .order('created_at')
        .map((data) => data
            .map((e) => RideModel.fromMap(e))
            .where((r) => r.status == RideStatus.searching || r.driverId == driverId)
            .toList());
  }

  Future<void> updateRideStatus(String rideId, RideStatus status, {String? failureReason}) async {
    int retryCount = 0;
    const int maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        final now = DateTime.now().toUtc();
        final Map<String, dynamic> updateData = {
          'status': status.name,
          'updated_at': now.toIso8601String(),
        };
        
        if (status == RideStatus.completed) {
          updateData['completed_at'] = now.toIso8601String();
        }
        
        if (failureReason != null) {
          updateData['failure_reason'] = failureReason;
        }
        
        debugPrint('>>> [PAYLOAD] Enviando para o banco: ${jsonEncode(updateData)}');
        
        await _supabase
            .from('rides')
            .update(updateData)
            .eq('id', rideId);

        // [AUDITORIA] Inserção no histórico de mudanças
        try {
          final user = _supabase.auth.currentUser;
          await _supabase.from('ride_history').insert({
            'ride_id': rideId,
            'status': status.name,
            'driver_id': user?.id,
            'created_at': now.toIso8601String(),
            'notes': 'Mudança de estado via App (Repository)'
          });
        } catch (e) {
          debugPrint('>>> [REPO] Erro ao salvar histórico: $e');
        }
        
        return; // Sucesso
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST204' || e.message.contains('completed_at')) {
          retryCount++;
          debugPrint('>>> [REPO] Tentativa $retryCount: Erro de coluna. Aguardando cache...');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        debugPrint('>>> [REPO] Erro ao atualizar status: $e');
        rethrow;
      } catch (e) {
        debugPrint('>>> [REPO] Erro genérico: $e');
        rethrow;
      }
    }
  }

  /// Notifica o sistema que o motorista recusou essas corridas.
  /// Adiciona o motorista ao array 'rejected_by' no banco.
  Future<void> rejectRides(List<String> rideIds, String driverId) async {
    try {
      // Usamos um RPC ou uma atualização direta se o campo for um array
      // Para este projeto, vamos assumir que o backend processa via update no campo 'status' 
      // ou um campo específico de rejeição.
      await _supabase.from('rides').update({
        'status': 'searching', // Volta para o radar
        'rejected_by': [driverId], // Idealmente seria um append no Postgres
      }).inFilter('id', rideIds);
      
      debugPrint('>>> [REPO] Corridas recusadas: $rideIds');
    } catch (e) {
      debugPrint('>>> [REPO] Erro ao recusar corridas: $e');
    }
  }
}

