import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool isLoading = false;
  String? errorMessage;

  Future<void> signIn(String email, String password, bool keepLoggedIn, bool saveEmail) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (saveEmail) {
        await prefs.setString('saved_email', email);
      } else {
        await prefs.remove('saved_email');
      }
      await prefs.setBool('keep_logged_in', keepLoggedIn);

      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials') || e.code == 'invalid_credentials') {
        errorMessage = 'E-mail ou senha incorretos. Verifique e tente novamente.';
      } else if (e.message.toLowerCase().contains('user not found') || e.code == 'user_not_found') {
        errorMessage = 'Este usuário ainda não está cadastrado.';
      } else {
        errorMessage = 'Ops! Tivemos um problema técnico. Tente novamente em instantes.';
      }
      rethrow;
    } catch (e) {
      errorMessage = 'Ops! Tivemos um problema técnico. Tente novamente em instantes.';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> uploadProfileSelfie(String userId, File file) async {
    _setLoading(true);
    try {
      // Força o reconhecimento da sessão após o cadastro
      try {
        await _supabase.auth.refreshSession();
        print('DEBUG: Session Refreshed');
      } catch (e) {
        print('DEBUG: Falha ao renovar sessão: $e');
      }

      final String? currentAuthId = _supabase.auth.currentUser?.id;
      final String ext = file.path.split('.').last;

      print('DEBUG: Bucket Name: driver_documents');
      print('DEBUG: User ID (Param): $userId');
      print('DEBUG: Session Active: ${_supabase.auth.currentSession != null}');

      if (currentAuthId == null) {
        print('Por que a moto funciona e a selfie não? O userId do Auth está nulo no momento da selfie!');
      }

      print('Tamanho do arquivo para upload: ${await file.length()} bytes');
      
      // Caminho Simplificado (Flat) para teste de RLS
      final String fileName = 'selfie_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final String path = fileName;
      
      // Operação de Emergência: Upload Binário
      final storageResponse = await _supabase.storage.from('driver_documents').uploadBinary(
        path, 
        await file.readAsBytes(),
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );
      
      debugPrint('[Supabase Storage Success] $storageResponse');
      
      final String publicUrl = _supabase.storage.from('driver_documents').getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e) {
      print('ERRO_BRUTO_SUPABASE (Storage): ${e.toString()}');
      errorMessage = 'Falha no servidor de arquivos (Bucket). Status: ${e.statusCode}';
      return null;
    } catch (e) {
      print('ERRO_BRUTO_SUPABASE (Geral): ${e.toString()}');
      errorMessage = 'Erro ao enviar foto para o servidor (bucket driver_documents).';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfileAvatar(String userId, String url) async {
    try {
      await _supabase.from('profiles').update({'avatar_url': url}).eq('id', userId);
      return true;
    } catch (e) {
      print('ERRO DATABASE UPDATE: $e');
      errorMessage = 'Conta criada, mas erro ao vincular a foto de perfil.';
      return false;
    }
  }

  Future<String?> signUp({
    required String firstName,
    required String lastName,
    required String cpf,
    required String phone,
    required String email,
    required String password,
    required String city,
    required String neighborhood,
    required String state,
    required String address,
    required String cnhNumber,
    required String cnhCategory,
    required String pixKey,
    String? avatarUrl,
  }) async {
    _setLoading(true);
    try {
      // Limpeza Cirúrgica (Trim)
      final tFirstName = firstName.trim();
      final tLastName = lastName.trim();
      final tCity = city.trim();
      final tNeighborhood = neighborhood.trim();
      final tState = state.trim();
      final tAddress = address.trim();
      final tEmail = email.trim();
      final tCnhNumber = cnhNumber.trim();
      final tPixKey = pixKey.trim();

      final userMetadata = {
        'first_name': tFirstName,
        'last_name': tLastName,
        'cpf': cpf,
        'phone': phone,
        'city': tCity,
        'neighborhood': tNeighborhood,
        'state': tState,
        'address': tAddress,
        'cnh_number': tCnhNumber,
        'cnh_category': cnhCategory,
        'pix_key': tPixKey,
        'avatar_url': avatarUrl,
      };

      final AuthResponse response = await _supabase.auth.signUp(
        email: tEmail,
        password: password,
        data: userMetadata,
        emailRedirectTo: 'viperdelivery://login-callback',
      );
      
      return response.user?.id;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') || e.message.toLowerCase().contains('already exists')) {
        errorMessage = 'Este e-mail já está sendo utilizado por outro motorista.';
      } else if (e.message.toLowerCase().contains('network') || e.message.toLowerCase().contains('timeout')) {
        errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente.';
      } else {
        errorMessage = e.message;
      }
      rethrow;
    } catch (e) {
      errorMessage = 'Ocorreu um erro inesperado: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
    return null;
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'viperdelivery://login-callback',
      );
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> finalizeDriverProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String cpf,
    required String phone,
    required String city,
    required String neighborhood,
    required String state,
    required String address,
    required String cnhNumber,
    required String cnhCategory,
    required String pixKey,
    required String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'cpf': cpf,
        'phone': phone,
        'city': city.trim(),
        'neighborhood': neighborhood.trim(),
        'state': state.trim(),
        'address': address.trim(),
        'cnh_number': cnhNumber.trim(),
        'cnh_category': cnhCategory,
        'pix_key': pixKey.trim(),
      };

      // Só adiciona se o upload tiver funcionado, para não sobrescrever com null
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      await _supabase.from('profiles').update(updateData).eq('id', userId);
      
      // Verificação Final: Garante que a sessão local tenha o ID correto para RLS
      if (_supabase.auth.currentUser?.id == null) {
        print('DEBUG: Sessão local ainda nula, mas update enviado via User ID parameter.');
      }

      return true;
    } catch (e) {
      print('ERRO_FINALIZE_PROFILE: $e');
      errorMessage = 'Conta criada, mas houve um erro ao salvar o perfil final.';
      // Note: Retornamos falso aqui para que a UI saiba que houve falha no DB,
      // mas no RegisterView vamos permitir o avanço se o erro for só no upload.
      return false;
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
