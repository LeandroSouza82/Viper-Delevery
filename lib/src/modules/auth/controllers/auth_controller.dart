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

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String cpf,
    required String phone,
    required String email,
    required String password,
    required String city,
    required String neighborhood,
    required String state,
    required String cnhNumber,
    required String cnhCategory,
    required String pixKey,
    String? avatarUrl,
  }) async {
    _setLoading(true);
    try {
      final userMetadata = {
        'first_name': firstName,
        'last_name': lastName,
        'cpf': cpf,
        'phone': phone,
        'city': city,
        'neighborhood': neighborhood,
        'state': state,
        'cnh_number': cnhNumber,
        'cnh_category': cnhCategory,
        'pix_key': pixKey,
        'avatar_url': avatarUrl,
      };
      debugPrint('🐍 VIPER DEBUG: Enviando Metadata -> $userMetadata');

      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: userMetadata,
        emailRedirectTo: 'viperdelivery://login-callback',
      );
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

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
