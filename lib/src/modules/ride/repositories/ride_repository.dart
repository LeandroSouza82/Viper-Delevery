import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/models/ride_model.dart';

class RideRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Escuta em tempo real (Real-time Stream) as corridas associadas a um motorista.
  /// 
  /// Utiliza a funcionalidade de stream do Supabase filtrando estritamente pelo
  /// [driverId]. Isso garante que o motorista só receba atualizações das corridas
  /// atribuídas a ele, sem sobrecarregar o cliente com dados desnecessários.
  /// A ordenação por 'created_at' mantém a fila consistente.
  Stream<List<RideModel>> getMyRidesStream(String driverId) {
    return _supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId) // Filtro de segurança e performance
        .order('created_at')
        .map((data) => data.map((e) => RideModel.fromMap(e)).toList());
  }

  Future<void> updateRideStatus(String rideId, RideStatus status, {String? failureReason}) async {
    final Map<String, dynamic> updateData = {
      'status': status.name,
    };
    if (failureReason != null) {
      updateData['failure_reason'] = failureReason;
    }
    
    await _supabase
        .from('rides')
        .update(updateData)
        .eq('id', rideId);
  }
}
