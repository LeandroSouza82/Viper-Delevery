import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:viper_delivery/src/modules/profile/controllers/profile_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

import '../widgets/profile_header.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final controller = Get.put(ProfileController());
  final settingsController = Get.find<SettingsController>();

  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
  }

  @override
  void dispose() {
    _disableScreenProtection();
    super.dispose();
  }

  Future<void> _enableScreenProtection() async {
    try {
      await FlutterWindowManagerPlus.addFlags(FlutterWindowManagerPlus.FLAG_SECURE);
      debugPrint('🛡️ [VUP PROTECT] Proteção de tela ATIVA no Perfil');
    } catch (e) {
      debugPrint('🛡️ [VUP PROTECT] Erro ao ativar proteção de tela: $e');
    }
  }

  Future<void> _disableScreenProtection() async {
    try {
      await FlutterWindowManagerPlus.clearFlags(FlutterWindowManagerPlus.FLAG_SECURE);
      debugPrint('🛡️ [VUP PROTECT] Proteção de tela DESATIVADA');
    } catch (e) {
      debugPrint('🛡️ [VUP PROTECT] Erro ao desativar proteção de tela: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // UNIFICAÇÃO TOTAL: Herdando cores do ColorScheme global
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primaryColor = const Color(0xFF00FF88);

    return Scaffold(
      // backgroundColor REMOVIDO para herança total do MaterialApp
      appBar: AppBar(
        title: Text(
          "VUP PILOTO", 
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900, 
            letterSpacing: 2.5,
            color: onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, size: 22, color: onSurface), 
            onPressed: () => _showLogoutDialog(context)
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final profile = controller.driverProfile.value;
        final name = profile?.firstName ?? '';
        final vehicle = (profile?.vehicles?.isNotEmpty == true) 
            ? (profile!.vehicles!.first.model ?? '') 
            : 'Viper Pilot';

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // 1. TOPO: Identidade Elite (Herdando onSurface)
              ProfileHeader(
                name: name, 
                vehicle: vehicle,
                avatarUrl: profile?.avatarUrl,
              ),
              
              const SizedBox(height: 80),

              // 2. BASE: Console de Segurança e Ações Táticas
              _buildSectionHeader("OPÇÕES DE CONTA", onSurface),
              const SizedBox(height: 16),
              
              _buildActionTile(
                Icons.lock_outline_rounded, 
                "Alterar Senha", 
                () => Get.toNamed('/reset-password'),
                onSurface,
                primaryColor,
                theme
              ),
              
              _buildActionTile(
                Icons.swap_calls_rounded, 
                "Trocar Veículo", 
                () => _showTrocaVeiculoModal(context),
                onSurface,
                primaryColor,
                theme,
                isHighlight: true
              ),
              
              const SizedBox(height: 60),
              
              // Divisória Herdada
              Divider(color: onSurface.withOpacity(0.08)),
              const SizedBox(height: 20),
              
              Text(
                "VUP PROTECT v1.0 - PERÍMETRO SEGURO", 
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onSurface.withOpacity(0.3), 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.5,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: color.withOpacity(0.3),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon, 
    String title, 
    VoidCallback onTap, 
    Color onSurface, 
    Color primaryColor,
    ThemeData theme,
    {bool isHighlight = false}
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isHighlight ? primaryColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? primaryColor.withOpacity(0.3) : onSurface.withOpacity(0.08)
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isHighlight ? primaryColor : onSurface.withOpacity(0.7), 
          size: 22
        ),
        title: Text(
          title, 
          style: TextStyle(
            color: isHighlight ? primaryColor : onSurface,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
            fontSize: 14
          )
        ),
        trailing: Icon(
          Icons.chevron_right_rounded, 
          size: 20, 
          color: onSurface.withOpacity(0.3)
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    Get.dialog(
      AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Sair da Conta', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: Text('Tem certeza que deseja encerrar sua sessão?', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Supabase.instance.client.auth.signOut(), 
            child: const Text('SAIR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTrocaVeiculoModal(BuildContext context) {
    final theme = Theme.of(context);
    Get.snackbar(
      'Troca de Veículo',
      'Funcionalidade em desenvolvimento para a próxima versão.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: theme.colorScheme.surface,
      colorText: theme.colorScheme.onSurface,
      borderWidth: 1,
      borderColor: theme.colorScheme.onSurface.withOpacity(0.1),
    );
  }
}
