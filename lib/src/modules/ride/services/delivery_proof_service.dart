import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryProofService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Faz o upload da foto para o Storage do Supabase (bucket `proofs`)
  /// e atualiza a tabela de relatórios da entrega.
  /// Finaliza a entrega enviando comprovante (arquivo ou bytes) e atualizando o banco.
  /// ESTÁGIO 1: Atualiza apenas o status para permitir UI otimista
  Future<bool> updateStatusOnly(String rideId) async {
    int retryCount = 0;
    const int maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        final user = _supabase.auth.currentUser;
        final now = DateTime.now().toUtc().toIso8601String();
        
        final updateData = {
          'status': 'completed',
          'updated_at': now,
          'completed_at': now, // Coluna nova: completed_at
        };

        debugPrint('>>> [PAYLOAD-STATUS] Enviando: ${jsonEncode(updateData)}');
        
        // 1. Update na tabela RIDES
        final response = await _supabase
            .from('rides')
            .update(updateData)
            .eq('id', rideId)
            .select();

        if (response.isEmpty) {
          debugPrint('>>> [SYNC] Alerta: Update em rides retornou vazio para ID: $rideId');
          return false;
        }

        // 2. Insert na tabela RIDE_HISTORY (Rastro de Auditoria)
        try {
          await _supabase.from('ride_history').insert({
            'ride_id': rideId,
            'status': 'completed',
            'driver_id': user?.id,
            'created_at': now,
            'notes': 'Finalização via Assinatura/Foto no App'
          });
        } catch (historyError) {
          debugPrint('>>> [SYNC] ERRO AO INSERIR NO HISTÓRICO: $historyError');
        }

        return true;
      } on PostgrestException catch (e) {
        // Trata erro PGRST204 (Coluna não encontrada no cache do Postgrest)
        if (e.code == 'PGRST204' || e.message.contains('completed_at')) {
          retryCount++;
          debugPrint('>>> [SYNC] Tentativa $retryCount: Erro de coluna (completed_at). Aguardando cache...');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        
        debugPrint('>>> ERRO AO FINALIZAR ENTREGA (Postgrest): ${e.code} - ${e.message}');
        return false;
      } catch (e) {
        debugPrint('>>> ERRO AO FINALIZAR ENTREGA (Generico): $e');
        return false;
      }
    }
    return false;
  }

  /// ESTÁGIO 2: Upload do arquivo (Storage) com Compressão MÁXIMA
  Future<String?> uploadProofFile(String rideId, File file) async {
    try {
      debugPrint('>>> [STORAGE] Iniciando processo para corrida: $rideId');

      // 1. COMPRESSÃO MÁXIMA (Regra de Ouro)
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      
      // Ajuste para lidar com PNG se necessário (assinaturas)
      final isPng = filePath.toLowerCase().endsWith('.png');
      final extension = isPng ? '.png' : '.jpg';
      final splitted = lastIndex != -1 
          ? filePath.substring(0, lastIndex) 
          : filePath.substring(0, filePath.lastIndexOf('.'));
      
      final outPath = "${splitted}_out$extension";

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path, 
        outPath,
        quality: 25, // Compressão agressiva para economizar banco/storage
        format: isPng ? CompressFormat.png : CompressFormat.jpeg,
      );

      if (compressedFile == null) throw 'Falha na compressão da imagem';
      final fileToUpload = File(compressedFile.path);
      
      final fileSizeKb = (await fileToUpload.length()) / 1024;
      debugPrint('>>> [STORAGE] Arquivo comprimido: ${fileSizeKb.toStringAsFixed(2)} KB');

      // 2. PREPARAÇÃO DO CAMINHO
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${timestamp}_proof$extension';
      final String storagePath = '${_supabase.auth.currentUser?.id}/$fileName';

      debugPrint('>>> [STORAGE] Fazendo upload para: driver_documents/$storagePath');

      // 3. UPLOAD COM TRY-CATCH
      final bucket = _supabase.storage.from('driver_documents');
      
      await bucket.upload(
        storagePath, 
        fileToUpload,
        fileOptions: const FileOptions(upsert: true),
      );
      
      final publicUrl = bucket.getPublicUrl(storagePath);
      debugPrint('>>> [STORAGE] Upload concluído! URL: $publicUrl');

      return publicUrl;

    } catch (e) {
      debugPrint('>>> [ERRO CRÍTICO STORAGE]: $e');
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
      debugPrint('>>> [DB] Iniciando update da rides (completed_at)...');
      final Map<String, dynamic> metadata = {
        'receiver_name': receiverName,
        'receiver_cpf': document,
        'receiver_vincule': relation,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'completed_at': DateTime.now().toUtc().toIso8601String(), // Garantindo completed_at aqui também
      };

      if (publicUrl != null && publicUrl.isNotEmpty) {
        metadata['signature_url'] = publicUrl;
      }

      debugPrint('>>> [PAYLOAD-METADATA] Enviando: ${jsonEncode(metadata)}');

      await _supabase.from('rides').update(metadata).eq('id', rideId);
      debugPrint('>>> [DB] Update finalizado com sucesso para ID: $rideId');
      return true;
    } on PostgrestException catch (e) {
      debugPrint('>>> [ERRO DB] PostgrestException: ${e.code} - ${e.message}');
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
      debugPrint('>>> [ERRO DB] Genérico: $e');
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

