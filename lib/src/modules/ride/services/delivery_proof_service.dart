import 'dart:io';
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
    String publicUrl;

    // PASSO 1: Fazer o upload para o Supabase Storage
    try {
      final String path = '${DateTime.now().millisecondsSinceEpoch}_entrega.jpg';
      
      print('>>> TENTANDO UPLOAD NO BUCKET: driver_documents');
      await _supabase.storage.from('driver_documents').upload(
        path,
        photoFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      ).timeout(const Duration(seconds: 15));
      
      print('>>> UPLOAD CONCLUÍDO COM SUCESSO');
      
      publicUrl = _supabase.storage.from('driver_documents').getPublicUrl(path);
    } catch (e) {
      print('>>> ERRO NO BUCKET: $e');
      return false; // A ViewController exibirá o snackbar de Erro vermelho!
    }

    // PASSO 2: Atualizar a Base de Dados
    try {
      await _supabase.from('rides').update({
        'foto_comprovante': publicUrl,
        'status': 'Concluída',
        'receiver_name': receiverName,
        'receiver_document': document,
        'receiver_vincule': relation,
      }).eq('id', mockOrderId).timeout(const Duration(seconds: 15));
      // NOTA: Se o erro persistir, reinicie o servidor do Supabase 
      // ou aguarde 1 minuto para o cache do PostgREST atualizar o schema.
      
      return true;
    } catch (e) {
      print('>>> ERRO NA TABELA: $e');
      return false; // A ViewController exibirá o snackbar de Erro vermelho!
    }
  }
}
