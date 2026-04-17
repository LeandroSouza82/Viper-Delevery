import 'package:supabase_flutter/supabase_flutter.dart';

class PerformanceService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getWeeklyPerformance(String driverId) async {
    try {
      // Calcula o início da semana atual (Segunda-feira)
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startAt = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      final response = await _supabase
          .from('rides')
          .select('driver_value, created_at')
          .eq('driver_id', driverId)
          .eq('status', 'completed')
          .gte('created_at', startAt.toIso8601String())
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyPerformance(String driverId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final response = await _supabase
          .from('rides')
          .select('driver_value, created_at')
          .eq('driver_id', driverId)
          .eq('status', 'completed')
          .gte('created_at', startOfMonth.toIso8601String())
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }
}
