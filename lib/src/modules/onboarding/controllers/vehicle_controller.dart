import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/modules/onboarding/services/upload_service.dart';

class VehicleController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UploadService _uploadService = UploadService();

  bool isLoading = false;
  String? errorMessage;

  // Document URLs
  String? cnhUrl;
  String? criminalRecordUrl;
  String? addressProofUrl;
  String? crlvUrl;

  // Vehicle URLs and Info
  String? vehicleModel;
  String? vehicleColor;
  String? vehicleFrontUrl;
  String? vehicleSideRightUrl;
  String? vehicleSideLeftUrl;
  String? vehicleRearUrl;

  Future<void> uploadDocument(String type, File file) async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');

      final url = await _uploadService.uploadDocument(
        userId: user.id,
        docType: type,
        file: file,
      );

      switch (type) {
        case 'cnh':
          cnhUrl = url;
          break;
        case 'criminal':
          criminalRecordUrl = url;
          break;
        case 'address':
          addressProofUrl = url;
          break;
        case 'crlv':
          crlvUrl = url;
          break;
      }
      notifyListeners();
    } catch (e) {
      errorMessage = 'Falha no upload do documento: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void setVehicleInspectionData({
    required String model,
    required String color,
    required String frontUrl,
    required String sideRightUrl,
    required String sideLeftUrl,
    required String rearUrl,
  }) {
    vehicleModel = model;
    vehicleColor = color;
    vehicleFrontUrl = frontUrl;
    vehicleSideRightUrl = sideRightUrl;
    vehicleSideLeftUrl = sideLeftUrl;
    vehicleRearUrl = rearUrl;
    notifyListeners();
  }

  bool get isInspectionComplete =>
      vehicleModel != null &&
      vehicleColor != null &&
      vehicleFrontUrl != null &&
      vehicleSideRightUrl != null &&
      vehicleSideLeftUrl != null &&
      vehicleRearUrl != null;

  Future<void> submitVehicleData({
    required String vehicleType,
    required String plate,
  }) async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');

      if (cnhUrl == null || criminalRecordUrl == null || addressProofUrl == null || crlvUrl == null || !isInspectionComplete) {
        throw Exception('Todos os documentos e fotos da vistoria são obrigatórios.');
      }

      // Final insert into vehicles table
      await _supabase.from('vehicles').insert({
        'driver_id': user.id,
        'vehicle_type': vehicleType.toLowerCase(),
        'plate': plate,
        'model': vehicleModel,
        'color': vehicleColor,
        'cnh_url': cnhUrl,
        'criminal_record_url': criminalRecordUrl,
        'address_proof_url': addressProofUrl,
        'crlv_url': crlvUrl,
        'photo_front_url': vehicleFrontUrl,
        'photo_side_right_url': vehicleSideRightUrl,
        'photo_side_left_url': vehicleSideLeftUrl,
        'photo_rear_url': vehicleRearUrl,
        // Legacy column fallback
        'photo_url': vehicleFrontUrl,
        'doc_url': crlvUrl,
      });

      // Update profile status
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
