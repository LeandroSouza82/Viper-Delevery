import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/modules/profile/models/profile_reputation_model.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  Future<void> solicitarTrocaVeiculo({
    required String modelo,
    required String cor,
    required String placa,
    required File crlvImage,
    required File frontImage,
    required File rightImage,
    required File leftImage,
    required File rearImage,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Helper para upload
    Future<String> uploadDoc(String folder, File file) async {
      final fileName = '${user.id}_${folder}_$timestamp.jpg';
      final storagePath = 'crlv_images/$folder/$fileName';
      
      await _supabase.storage.from('documents').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _supabase.storage.from('documents').getPublicUrl(storagePath);
    }

    // 1. Upload das 5 Imagens em paralelo para máxima performance
    final results = await Future.wait([
      uploadDoc('crlv', crlvImage),
      uploadDoc('front', frontImage),
      uploadDoc('right', rightImage),
      uploadDoc('left', leftImage),
      uploadDoc('rear', rearImage),
    ]);

    // 2. Inserção na tabela motorista_veiculos com as 5 URLs
    await _supabase.from('motorista_veiculos').insert({
      'driver_id': user.id,
      'model': modelo,
      'color': cor,
      'plate': placa,
      'crlv_url': results[0],
      'front_url': results[1],
      'right_url': results[2],
      'left_url': results[3],
      'rear_url': results[4],
      'status': 'pendente_analise',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

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
    // REGRA DE SEGURANÇA: Comentários só ficam visíveis após 3 dias da corrida
    // TODO: No Supabase, filtrar a query real: 
    // .lte('created_at', DateTime.now().subtract(Duration(days: 3)).toIso8601String())
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mocks atualizados seguindo a regra de anonimato e delay (datas de +3 dias atrás)
    return [
      ReviewModel(
        id: '1',
        customerName: 'Anônimo',
        comment: 'Entrega rápida e atencioso.',
        rating: 5.0,
        date: 'Há 3 dias', 
      ),
      ReviewModel(
        id: '2',
        customerName: 'Anônimo',
        comment: 'Tudo certo com o pedido.',
        rating: 4.5,
        date: 'Há 5 dias',
      ),
      ReviewModel(
        id: '3',
        customerName: 'Anônimo',
        comment: 'Ótimo piloto, muito cuidadoso.',
        rating: 5.0,
        date: 'Há 1 semana',
      ),
    ];
  }

  Future<void> updateEmergencyContact(String name, String phone) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _supabase.from('driver_settings').update({
      'emergency_contact_name': name,
      'emergency_contact_phone': phone,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }

  Future<Map<String, dynamic>?> getEmergencyContact(String userId) async {
    try {
      final response = await _supabase
          .from('driver_settings')
          .select('emergency_contact_name, emergency_contact_phone')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Erro ao buscar contato de emergência: $e');
      return null;
    }
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
