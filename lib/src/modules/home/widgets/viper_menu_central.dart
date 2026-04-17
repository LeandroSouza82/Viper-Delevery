import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/shared/widgets/pix_qr_dialog.dart';
import 'package:viper_delivery/src/modules/profile/views/atividades_view.dart';
import 'package:viper_delivery/src/modules/home/views/settings_view.dart';
import 'package:viper_delivery/src/modules/profile/views/profile_view.dart';
import 'package:viper_delivery/src/modules/profile/views/wallet_view.dart';
import 'package:viper_delivery/src/modules/profile/views/history_view.dart';
import 'package:viper_delivery/src/modules/profile/views/acceptance_rate_view.dart';
import 'package:viper_delivery/src/modules/profile/views/help_view.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

class ViperMenuCentral extends StatefulWidget {
  final SettingsController settingsController;
  final ViperMenuController menuController;

  const ViperMenuCentral({
    super.key,
    required this.settingsController,
    required this.menuController,
  });

  @override
  State<ViperMenuCentral> createState() => _ViperMenuCentralState();
}

class _ViperMenuCentralState extends State<ViperMenuCentral> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.menuController, widget.settingsController]),
      builder: (context, child) {
        final isDark = widget.settingsController.isDarkTheme;
        final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final dividerColor = isDark ? Colors.white12 : Colors.black12;
        
        // LOG DE RECONSTRUÇÃO AGRESSIVO
        print('[!!! VIPER !!!] UI: Reconstruindo Drawer. Loading: ${widget.menuController.isLoading}, Driver: ${widget.menuController.driverProfile?.firstName}');

        return Drawer(
          backgroundColor: bgColor,
          width: MediaQuery.of(context).size.width * 0.85,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
          ),
          child: widget.menuController.isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF88)))
              : SafeArea(
                  child: Column(
                    children: [
                      // 1. Cabeçalho de Perfil (Topo: Foto, Nome e Endereço)
                      _buildHeader(isDark, textColor),
                      
                      const SizedBox(height: 20),
                      Divider(color: dividerColor),
                      
                      // 2. Área de Dados
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Meio: Card de 'Documentos' com CNH e Placa
                              _buildSectionTitle('DOCUMENTOS E VEÍCULO', textColor, isDark),
                              const SizedBox(height: 16),
                              _buildProfileCard(isDark, textColor),
                              
                              const SizedBox(height: 32),
                              _buildSectionTitle('MISSÃO DO DIA', textColor, isDark),
                              const SizedBox(height: 16),
                              _buildMissionStatic(isDark, textColor),

                              const SizedBox(height: 32),
                              _buildSectionTitle('COCKPIT E PERFORMANCE', textColor, isDark),
                              const SizedBox(height: 16),
                              // Destaque: Atividades
                              _buildMenuButton(
                                icon: Icons.insights_rounded,
                                label: 'Minhas Atividades',
                                subLabel: 'Ganhos e histórico de desempenho',
                                isDark: isDark,
                                textColor: textColor,
                                onPressed: () {
                                  if (!Get.isRegistered<SettingsController>()) {
                                    Get.put(widget.settingsController);
                                  }
                                  Get.to(() => const AtividadesView());
                                },
                              ),
                              
                              const SizedBox(height: 24),
                              _buildSectionTitle('SISTEMA E CONTA', textColor, isDark),
                              const SizedBox(height: 16),
                              
                              // Outros itens restaurados
                              ListTile(
                                leading: Icon(Icons.person_outline_rounded, color: textColor.withOpacity(0.6)),
                                title: const Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
                                textColor: textColor,
                                onTap: () => Get.to(() => const ProfileView()),
                              ),
                              const SizedBox(height: 4),
                              ListTile(
                                leading: Icon(Icons.account_balance_wallet_outlined, color: textColor.withOpacity(0.6)),
                                title: const Text('Minha Carteira', style: TextStyle(fontWeight: FontWeight.bold)),
                                textColor: textColor,
                                onTap: () => Get.to(() => const WalletView()),
                              ),
                              const SizedBox(height: 12),
                              _buildSimpleMenuItem(
                                icon: Icons.settings_outlined,
                                label: 'Configurações',
                                textColor: textColor,
                                isDark: isDark,
                                onPressed: () => Get.to(() => SettingsView(
                                  settingsController: widget.settingsController,
                                )),
                              ),
                              const SizedBox(height: 12),
                              _buildSimpleMenuItem(
                                icon: Icons.help_outline_rounded,
                                label: 'Ajuda e Suporte',
                                textColor: textColor,
                                isDark: isDark,
                                onPressed: () => Get.to(() => const HelpView()),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // 3. Rodapé
                      _buildFooter(context, isDark, textColor),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, Color textColor) {
    final firstName = widget.menuController.driverProfile?.firstName ?? 'Motorista';
    final city = widget.menuController.driverProfile?.city ?? 'Base Não Informada';
    final state = widget.menuController.driverProfile?.state ?? '';
    final avatarUrl = widget.menuController.driverProfile?.avatarUrl;

    print('[!!! VIPER !!!] UI: Renderizando Header -> Nome: $firstName, Foto: $avatarUrl');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00FF88), width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        width: 70,
                        height: 70,
                        placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                        errorWidget: (context, url, error) {
                          print('[!!! VIPER !!!] ERROR: Falha no CachedNetworkImage: $error');
                          return const Icon(Icons.error_outline, color: Colors.redAccent, size: 30);
                        },
                      )
                    : Icon(Icons.person, color: textColor.withOpacity(0.5), size: 35),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.split(' ').first,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, color: const Color(0xFF00FF88), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$city - $state',
                        style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        color: textColor.withOpacity(0.4),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required String subLabel,
    required bool isDark,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black, 
            width: isDark ? 1.0 : 2.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.insights_rounded, color: Color(0xFF00FF88), size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subLabel,
                    style: TextStyle(
                      color: textColor.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: textColor.withOpacity(0.2), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark, Color textColor) {
    // FIX DE TIPAGEM: Usando propriedades do DriverModel
    final vehicles = widget.menuController.driverProfile?.vehicles;
    final vehicle = (vehicles != null && vehicles.isNotEmpty) ? vehicles.first : null;
    
    final plate = vehicle?['plate'] ?? '-- -- --';
    final model = vehicle?['model'] ?? 'Veículo não cadastrado';
    final cnh = widget.menuController.driverProfile?.cnhNumber ?? '**********';
    final cat = widget.menuController.driverProfile?.cnhCategory ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black, 
          width: isDark ? 1.0 : 2.0,
        ),
      ),
      child: Column(
        children: [
          _buildInfoItem(Icons.credit_card_outlined, 'CNH (CATEGORIA $cat)', cnh, textColor, isDark),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          const SizedBox(height: 16),
          _buildInfoItem(Icons.local_shipping_outlined, 'VEÍCULO ($model)', plate, textColor, isDark, highlight: true),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color textColor, bool isDark, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, color: highlight ? const Color(0xFF00FF88) : textColor.withOpacity(0.5), size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold)),
              Text(
                value, 
                style: TextStyle(
                  color: highlight ? const Color(0xFF00FF88) : textColor, 
                  fontSize: 15, 
                  fontWeight: highlight ? FontWeight.w900 : FontWeight.bold
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMissionStatic(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0055FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black, 
          width: isDark ? 1.0 : 2.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Fix de Overflow
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROGRESSO', style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold)),
              const Text('2/5', style: TextStyle(color: Color(0xFF0055FF), fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.4,
            backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            color: const Color(0xFF0055FF),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(
            'Faltam 3 entregas para o bônus de R\$ 50,00',
            style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              Get.defaultDialog(
                title: 'Sair do Viper?',
                titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                middleText: 'Tem certeza que deseja desconectar sua conta?',
                middleTextStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                backgroundColor: const Color(0xFF1E1E1E),
                radius: 16,
                textCancel: 'Cancelar',
                cancelTextColor: Colors.white,
                textConfirm: 'Sim, Sair',
                confirmTextColor: Colors.white,
                buttonColor: Colors.redAccent,
                onCancel: () {},
                onConfirm: () {
                  Supabase.instance.client.auth.signOut();
                  Get.back(); // Fecha o dialog antes
                },
              );
            },
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('SAIR DO APP'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSimpleMenuItem({
    required IconData icon,
    required String label,
    required Color textColor,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor.withOpacity(0.6), size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: textColor.withOpacity(0.2), size: 18),
          ],
        ),
      ),
    );
  }
}
