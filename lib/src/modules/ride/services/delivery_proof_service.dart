import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryProofService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Faz o upload da foto para o Storage do Supabase (bucket `proofs`)
  /// e atualiza a tabela de relatórios da entrega.
  Future<bool> uploadPhotoProof({
    required String mockOrderId,
    required File photoFile,
    required String receiverName,
    required String document,
    required String relation,
  }) async {
    try {
      // PASSO A: Fazer o upload do ficheiro para o Supabase Storage
      final nomeArquivo = '${DateTime.now().millisecondsSinceEpoch}_comprovante.jpg';
      
      print('>>> TENTANDO UPLOAD NO BUCKET: comprovantes_entrega');
      await _supabase.storage.from('comprovantes_entrega').upload(
        nomeArquivo,
        photoFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      ).timeout(const Duration(seconds: 15));
      print('>>> UPLOAD CONCLUÍDO COM SUCESSO');

      // PASSO B: Obter a publicUrl do ficheiro recém-carregado
      final publicUrl = _supabase.storage.from('comprovantes_entrega').getPublicUrl(nomeArquivo);
      debugPrint('[SUPABASE UPLOAD] Foto salva no Storage -> $publicUrl');

      // PASSO C: Atualizar a Base de Dados
      await _supabase.from('viper_orders').update({
        'status': 'Concluída',
        'proof_photo_url': publicUrl,
        'receiver_name': receiverName,
        'receiver_document': document,
        'receiver_relation': relation,
        'delivery_date': DateTime.now().toIso8601String(),
      }).eq('id', mockOrderId).timeout(const Duration(seconds: 15));

      return true;
    } catch (e) {
      print('ERRO SUPABASE: $e');
      debugPrint('[SUPABASE ERROR] Falha na operação: $e');
      return false;
    }
  }
}
