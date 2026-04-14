import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/modules/auth/views/login_view.dart';
import 'package:viper_delivery/src/modules/onboarding/views/vehicle_registration_view.dart';
import 'package:viper_delivery/src/modules/onboarding/views/pending_approval_view.dart';
import 'package:viper_delivery/src/modules/home/views/home_view.dart';
import 'package:viper_delivery/src/modules/splash/views/splash_view.dart';

class AuthGuardView extends StatelessWidget {
  const AuthGuardView({super.key});

  Future<Widget> _checkAuthStatus() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      return const SplashView(); // Go to Splash/Welcome then Login
    }

    try {
      // Fetch profile status
      final response = await supabase
          .from('profiles')
          .select('status')
          .eq('id', session.user.id)
          .single();

      final status = response['status'] as String;

      switch (status) {
        case 'approved':
          return const HomeView();
        case 'pending_approval':
          return const PendingApprovalView();
        case 'pending_vehicle':
          return const VehicleRegistrationView();
        case 'rejected':
          return const LoginView(); // Or a custom rejected view
        default:
          return const VehicleRegistrationView();
      }
    } catch (e) {
      // If profile not found or error, fallback to login
      await supabase.auth.signOut();
      return const LoginView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _checkAuthStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const LoginView();
        }

        return snapshot.data!;
      },
    );
  }
}
