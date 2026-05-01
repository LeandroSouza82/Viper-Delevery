import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryProofService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Faz o upload da foto para o Storage do Supabase (bucket `proofs`)
  /// e atualiza a tabela de relatórios da entrega.
  /// Finaliza a entrega enviando comprovante (arquivo ou bytes) e atualizando o banco.
  /// ESTÁGIO 1: Atualiza apenas o status para permitir UI otimista
  Future<bool> updateStatusOnly(String rideId) async {
    try {
      debugPrint('>>> [SYNC] Atualizando status para COMPLETED (Otimista) para ID: $rideId');
      final response = await _supabase
          .from('rides')
          .update({'status': 'completed'})
          .eq('id', rideId)
          .select();
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('>>> [SYNC] Erro ao atualizar status otimista: $e');
      return false;
    }
  }

  /// ESTÁGIO 2: Upload do arquivo (Storage)
  Future<String?> uploadProofFile(String rideId, File file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${timestamp}_proof.jpg';
      final String storagePath = '${user.id}/$fileName';
      
      final bucket = _supabase.storage.from('driver_documents');
      await bucket.upload(
        storagePath, 
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return bucket.getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('>>> [SYNC] Erro no upload Storage: $e');
      return null;
    }
  }

  /// ESTÁGIO 3: Atualiza metadados e URL
  Future<bool> updateMetadata({
    required String rideId,
    required String receiverName,
    required String document,
    required String relation,
    String? publicUrl,
  }) async {
    try {
      final Map<String, dynamic> metadata = {
        'receiver_name': receiverName,
        'receiver_cpf': document,
        'receiver_vincule': relation,
      };

      if (publicUrl != null) {
        metadata['signature_url'] = publicUrl;
      }

      await _supabase.from('rides').update(metadata).eq('id', rideId);
      return true;
    } on PostgrestException catch (e) {
      // Fallback para proof_photo_url
      if (e.message.contains('signature_url') || e.message.contains('column does not exist')) {
        try {
          await _supabase
              .from('rides')
              .update({'proof_photo_url': publicUrl})
              .eq('id', rideId);
          return true;
        } catch (_) {}
      }
      return false;
    } catch (e) {
      debugPrint('>>> [SYNC] Erro ao atualizar metadados: $e');
      return false;
    }
  }

  /// Mantido para compatibilidade se necessário, mas agora chama os métodos atômicos
  Future<bool> finalizeDelivery({
    required String rideId,
    required String receiverName,
    required String document,
    required String relation,
    File? photoFile,
    Uint8List? signatureBytes,
  }) async {
    final statusOk = await updateStatusOnly(rideId);
    if (!statusOk) return false;

    String? url;
    if (photoFile != null) {
      url = await uploadProofFile(rideId, photoFile);
    } else if (signatureBytes != null) {
      // Para bytes, salva temporário e sobe (ou implementa uploadBinary separado)
      // Aqui simplificamos pois o novo fluxo usará arquivos persistentes
    }

    await updateMetadata(
      rideId: rideId,
      receiverName: receiverName,
      document: document,
      relation: relation,
      publicUrl: url,
    );

    return true;
  }
}

