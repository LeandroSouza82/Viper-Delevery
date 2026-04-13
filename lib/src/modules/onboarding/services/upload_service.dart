import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadFile({
    required String bucket,
    required String userId,
    required String docType,
    required File file,
  }) async {
    final ext = file.path.split('.').last;
    final fileName = '${userId}_$docType.$ext';
    final storagePath = '$userId/$fileName';

    await _supabase.storage.from(bucket).upload(
      storagePath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return _supabase.storage.from(bucket).getPublicUrl(storagePath);
  }

  Future<String> uploadVehiclePhoto({
    required String userId,
    required String angle,
    required File file,
  }) async {
    return uploadFile(
      bucket: 'driver_documents',
      userId: userId,
      docType: 'vehicle_$angle',
      file: file,
    );
  }

  Future<String> uploadDocument({
    required String userId,
    required String docType,
    required File file,
  }) async {
    return uploadFile(
      bucket: 'driver_documents',
      userId: userId,
      docType: docType,
      file: file,
    );
  }
}
