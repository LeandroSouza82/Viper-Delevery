import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/modules/profile/models/profile_reputation_model.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getDriverProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*, vehicles(*)')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Erro ao buscar perfil: $e');
      return {};
    }
  }

  Future<List<ReviewModel>> getDriverReviews(String userId) async {
    // Por enquanto retornaremos mocks estruturados, 
    // prontos para serem substituídos por queries reais do Supabase
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ReviewModel(
        id: '1',
        customerName: 'Ricardo Oliveira',
        comment: 'Entrega super rápida e piloto muito educado. Recomendo!',
        rating: 5.0,
        date: 'Hoje, 14:20',
      ),
      ReviewModel(
        id: '2',
        customerName: 'Mariana Silva',
        comment: 'Ótimo serviço, a comida chegou quentinha e intacta.',
        rating: 4.8,
        date: 'Ontem, 20:15',
      ),
      ReviewModel(
        id: '3',
        customerName: 'Anônimo',
        comment: 'Muito bom, mas demorou um pouco mais que o previsto.',
        rating: 4.0,
        date: '15/04/2026',
      ),
    ];
  }

  Future<List<TrophyModel>> getDriverTrophies(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      TrophyModel(id: '1', title: 'Top Pilot', icon: '🚀', date: 'Abril 2026'),
      TrophyModel(id: '2', title: 'Elite 100', icon: '💎', date: 'Março 2026'),
      TrophyModel(id: '3', title: 'Cuidado VIP', icon: '🛡️', date: 'Fevereiro 2026'),
      TrophyModel(id: '4', title: 'Pé de Chumbo', icon: '⚡', date: 'Jan 2026'),
    ];
  }

  Map<int, int> getStarDistribution(String userId) {
    // Mock de distribuição de estrelas (5 estrelas -> 450 votos, etc)
    return {
      5: 450,
      4: 32,
      3: 8,
      2: 2,
      1: 1,
    };
  }
}
