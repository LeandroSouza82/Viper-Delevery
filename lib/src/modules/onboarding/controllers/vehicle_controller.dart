import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  String? errorMessage;

  File? documentPhoto;
  File? vehiclePhoto;

  Future<void> pickDocumentPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      documentPhoto = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<void> pickVehiclePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      vehiclePhoto = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<void> submitVehicleData({
    required String vehicleType,
    required String plate,
  }) async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }
      
      if (documentPhoto == null || vehiclePhoto == null) {
        throw Exception('Ambas as fotos são obrigatórias.');
      }

      final docExt = documentPhoto!.path.split('.').last;
      final docPath = '${user.id}/document_${DateTime.now().millisecondsSinceEpoch}.$docExt';
      await _supabase.storage.from('driver_documents').upload(docPath, documentPhoto!);
      final docUrl = _supabase.storage.from('driver_documents').getPublicUrl(docPath);

      final vehExt = vehiclePhoto!.path.split('.').last;
      final vehPath = '${user.id}/vehicle_${DateTime.now().millisecondsSinceEpoch}.$vehExt';
      await _supabase.storage.from('driver_documents').upload(vehPath, vehiclePhoto!);
      final vehUrl = _supabase.storage.from('driver_documents').getPublicUrl(vehPath);

      await _supabase.from('vehicles').insert({
        'driver_id': user.id,
        'vehicle_type': vehicleType.toLowerCase(),
        'plate': plate,
        'doc_url': docUrl,
        'photo_url': vehUrl,
      });

      await _supabase.from('profiles').update({
        'status': 'pending_approval'
      }).eq('id', user.id);

    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
