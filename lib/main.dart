import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:viper_delivery/src/core/services/foreground_service_manager.dart';
import 'package:viper_delivery/src/core/config/env.dart';
import 'package:viper_delivery/src/modules/auth/guards/auth_guard_view.dart';
import 'package:viper_delivery/src/modules/auth/views/reset_password_view.dart';
import 'package:viper_delivery/src/modules/auth/views/login_view.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Trava a tela sempre em pé
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Mantém a tela ligada
  await WakelockPlus.enable();

  // Inicializa o serviço de primeiro plano
  await ForegroundServiceManager.init();
  
  // Habilita o modo Edge-to-Edge para desenho por baixo das barras
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseKey,
  );

  // Inicializa o controlador de configurações (Sindicato de Tema)
  Get.put(SettingsController());

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedOut) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    }
    
    if (data.event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/reset-password',
        (route) => false,
      );
    }
  });

  runApp(const ViperDeliveryApp());
}

class ViperDeliveryApp extends StatelessWidget {
  const ViperDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();

    return Obx(() {
      // MAPEAMENTO DEFINITIVO DE TEMA (Viper Unified)
      ThemeMode flutterThemeMode;
      switch (settingsController.themeMode.value) {
        case ViperThemeMode.day:
          flutterThemeMode = ThemeMode.light;
          break;
        case ViperThemeMode.night:
          flutterThemeMode = ThemeMode.dark;
          break;
        default:
          flutterThemeMode = ThemeMode.system;
      }

      return GetMaterialApp(
        navigatorKey: navigatorKey,
        title: 'Viper Delivery',
        debugShowCheckedModeBanner: false,
        themeMode: flutterThemeMode, // SINCRONIA TOTAL: Segue o SettingsController
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          colorSchemeSeed: const Color(0xFF00FF88),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0055FF),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          colorSchemeSeed: const Color(0xFF00FF88),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const AuthGuardView(),
        routes: {
          '/reset-password': (context) => const ResetPasswordView(),
        },
      );
    });
  }
}
