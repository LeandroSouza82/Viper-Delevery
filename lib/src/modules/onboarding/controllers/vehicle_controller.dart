import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/modules/onboarding/services/upload_service.dart';

class VehicleController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UploadService _uploadService = UploadService();

  bool isLoading = false;
  String? errorMessage;

  // Document URLs (Profiles Table)
  String? cnhFrontUrl;
  String? criminalRecordUrl;
  String? addressProofUrl;

  // Vehicle URLs and Info (Vehicles Table)
  String? vehicleModel;
  String? vehicleColor;
  String? crlvUrl;
  String? inspectionFrontUrl;
  String? inspectionBackUrl;
  String? inspectionLeftUrl;
  String? inspectionRightUrl;

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
          cnhFrontUrl = url;
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
    required String backUrl,
    required String leftUrl,
    required String rightUrl,
  }) {
    vehicleModel = model;
    vehicleColor = color;
    inspectionFrontUrl = frontUrl;
    inspectionBackUrl = backUrl;
    inspectionLeftUrl = leftUrl;
    inspectionRightUrl = rightUrl;
    notifyListeners();
  }

  bool get isInspectionComplete =>
      vehicleModel != null &&
      vehicleColor != null &&
      inspectionFrontUrl != null &&
      inspectionBackUrl != null &&
      inspectionLeftUrl != null &&
      inspectionRightUrl != null;

  Future<void> submitVehicleData({
    required String vehicleType,
    required String plate,
  }) async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');

      if (cnhFrontUrl == null || criminalRecordUrl == null || addressProofUrl == null || crlvUrl == null || !isInspectionComplete) {
        throw Exception('Todos os documentos e fotos da vistoria são obrigatórios.');
      }

      // 🐍 VIPER: Docs -> Criminal: $criminalRecordUrl, Endereço: $addressProofUrl
      debugPrint('🐍 VIPER: Docs -> Criminal: $criminalRecordUrl, Endereço: $addressProofUrl');

      // 1. Update Profile with Personal Documents
      await _supabase.from('profiles').update({
        'cnh_front_url': cnhFrontUrl,
        'criminal_record_url': criminalRecordUrl,
        'address_proof_url': addressProofUrl,
        'status': 'pending_approval'
      }).eq('id', user.id);

      // 2. Insert into Vehicles Table
      await _supabase.from('vehicles').insert({
        'driver_id': user.id,
        'vehicle_type': vehicleType.toLowerCase(),
        'plate': plate,
        'model': vehicleModel,
        'color': vehicleColor,
        'crlv_url': crlvUrl,
        'inspection_front_url': inspectionFrontUrl,
        'inspection_back_url': inspectionBackUrl,
        'inspection_left_url': inspectionLeftUrl,
        'inspection_right_url': inspectionRightUrl,
      });

      // Removed standalone status update as it's part of the profile update above

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
