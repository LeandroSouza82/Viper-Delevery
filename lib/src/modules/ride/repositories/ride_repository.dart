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

