import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/modules/home/widgets/weekly_performance_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/modules/profile/views/atividades_view.dart';
import 'package:viper_delivery/src/modules/home/views/settings_view.dart';
import 'package:viper_delivery/src/modules/profile/views/profile_view.dart';
import 'package:viper_delivery/src/modules/profile/views/wallet_view.dart';
import 'package:viper_delivery/src/modules/profile/views/help_view.dart';

enum PerformanceView { day, week, month }
enum DocumentsView { vehicle, profile, cnh }

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
  PerformanceView _selectedView = PerformanceView.week;
  DocumentsView _selectedDocsView = DocumentsView.vehicle;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.settingsController.isDarkTheme;
    final textColor = isDark ? Colors.white : Colors.black;

    return GetBuilder<ViperMenuController>(
      init: widget.menuController,
      builder: (controller) {
        return Drawer(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          width: MediaQuery.of(context).size.width * 0.85,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDark, textColor),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Dashboards (Estilo Panda)
                              _buildSectionTitle('DOCUMENTOS E VEÍCULO', textColor, isDark),
                              const SizedBox(height: 16),
                              _buildDocumentDashboard(isDark, textColor),
                              
                              const SizedBox(height: 32),
                              _buildSectionTitle('MISSÃO DO DIA', textColor, isDark),
                              const SizedBox(height: 16),
                              _buildMissionStatic(isDark, textColor),

                              const SizedBox(height: 32),
                              _buildSectionTitle('PERFORMANCE E GANHOS', textColor, isDark),
                              const SizedBox(height: 16),
                              _buildPerformanceDashboard(isDark, textColor),

                              const SizedBox(height: 32),
                              _buildSectionTitle('SISTEMA E CONTA', textColor, isDark),
                              const SizedBox(height: 16),

                              // Botões de Navegação Restaurados
                              _buildMenuButton(
                                icon: Icons.insights_rounded,
                                label: 'Minhas Atividades',
                                subLabel: 'Ganhos e histórico detalhado',
                                isDark: isDark,
                                textColor: textColor,
                                onPressed: () {
                                  if (!Get.isRegistered<SettingsController>()) { Get.put(SettingsController()); }
                                  Get.to(() => const AtividadesView());
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSimpleMenuItem(
                                icon: Icons.person_outline_rounded,
                                label: 'Meu Perfil',
                                textColor: textColor,
                                isDark: isDark,
                                onPressed: () => Get.to(() => const ProfileView()),
                              ),
                              const SizedBox(height: 12),
                              _buildSimpleMenuItem(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'Minha Carteira',
                                textColor: textColor,
                                isDark: isDark,
                                onPressed: () {
                                  if (!Get.isRegistered<SettingsController>()) { Get.put(SettingsController()); }
                                  Get.to(() => const WalletView());
                                },
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
                                onPressed: () {
                                  if (!Get.isRegistered<SettingsController>()) { Get.put(SettingsController()); }
                                  Get.to(() => const HelpView());
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildFooter(context, isDark, textColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, Color textColor) {
    final profile = widget.menuController.driverProfile;
    final firstName = profile?.firstName ?? 'Motorista';
    final city = profile?.city ?? 'Base Indisponível';
    final state = profile?.state ?? '';
    final avatarUrl = profile?.avatarUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? const Color(0xFF00FF88) : Colors.black, width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
              child: ClipOval(
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        width: 70,
                        height: 70,
                        placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                        errorWidget: (context, url, error) => Icon(Icons.person, color: textColor.withOpacity(0.5), size: 35),
                      )
                    : Icon(Icons.person, color: textColor.withOpacity(0.5), size: 35),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.split(' ').first,
                  style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF00FF88), size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$city - $state',
                        style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 11),
                        maxLines: 1,
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
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDocumentDashboard(bool isDark, Color textColor) {
    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildDocTabItem('VEÍCULO', DocumentsView.vehicle, isDark, textColor),
              _buildDocTabItem('PERFIL', DocumentsView.profile, isDark, textColor),
              _buildDocTabItem('CNH', DocumentsView.cnh, isDark, textColor),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildSelectedDocsView(isDark, textColor),
        ),
      ],
    );
  }

  Widget _buildDocTabItem(String label, DocumentsView view, bool isDark, Color textColor) {
    final isSelected = _selectedDocsView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDocsView = view),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? Colors.white10 : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? (isDark ? Colors.white38 : Colors.black) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? textColor : textColor.withOpacity(0.4),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDocsView(bool isDark, Color textColor) {
    switch (_selectedDocsView) {
      case DocumentsView.vehicle:
        return _buildVehicleView(isDark, textColor);
      case DocumentsView.profile:
        return _buildProfileDataView(isDark, textColor);
      case DocumentsView.cnh:
        return _buildCNHView(isDark, textColor);
    }
  }

  Widget _buildVehicleView(bool isDark, Color textColor) {
    final vehicle = (widget.menuController.driverProfile?.vehicles?.isNotEmpty == true) 
        ? widget.menuController.driverProfile!.vehicles!.first 
        : null;
    
    return _buildPandaContainer(
      isDark, 
      Column(
        children: [
          _buildInfoItem(Icons.local_shipping_outlined, 'MODELO', vehicle?.model ?? 'NÃO CADASTRADO', textColor, isDark),
          const SizedBox(height: 12),
          _buildInfoItem(Icons.palette_outlined, 'COR', (vehicle?.color ?? 'N/A').toUpperCase(), textColor, isDark),
          const SizedBox(height: 12),
          _buildInfoItem(Icons.tag, 'PLACA', vehicle?.plate ?? '-- -- --', textColor, isDark, highlight: true),
        ],
      )
    );
  }

  Widget _buildProfileDataView(bool isDark, Color textColor) {
    final profile = widget.menuController.driverProfile;
    return _buildPandaContainer(
      isDark, 
      Column(
        children: [
          _buildInfoItem(Icons.badge_outlined, 'CPF', profile?.cpf ?? '***.***.***-**', textColor, isDark),
          const SizedBox(height: 12),
          _buildInfoItem(Icons.phone_android, 'TELEFONE', profile?.phone ?? '', textColor, isDark),
          const SizedBox(height: 12),
          _buildInfoItem(Icons.home_outlined, 'BASE OPERACIONAL', '${profile?.city} - ${profile?.state}'.toUpperCase(), textColor, isDark),
        ],
      )
    );
  }

  Widget _buildCNHView(bool isDark, Color textColor) {
    final profile = widget.menuController.driverProfile;
    return _buildPandaContainer(
      isDark, 
      Column(
        children: [
          _buildInfoItem(Icons.credit_card_outlined, 'CATEGORIA', profile?.cnhCategory ?? 'N/A', textColor, isDark),
          const SizedBox(height: 12),
          _buildInfoItem(Icons.numbers, 'REGISTRO', profile?.cnhNumber ?? '**********', textColor, isDark),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          const Text('Documentação verificada pelo sistema Viper.', style: TextStyle(color: Colors.grey, fontSize: 9, fontStyle: FontStyle.italic)),
        ],
      )
    );
  }

  Widget _buildPerformanceDashboard(bool isDark, Color textColor) {
    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildTabItem('DIA', PerformanceView.day, isDark, textColor),
              _buildTabItem('SEMANA', PerformanceView.week, isDark, textColor),
              _buildTabItem('MÊS', PerformanceView.month, isDark, textColor),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildSelectedPerformanceView(isDark, textColor),
        ),
      ],
    );
  }

  Widget _buildTabItem(String label, PerformanceView view, bool isDark, Color textColor) {
    final isSelected = _selectedView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = view),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? Colors.white10 : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? (isDark ? Colors.white38 : Colors.black) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? textColor : textColor.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPerformanceView(bool isDark, Color textColor) {
    switch (_selectedView) {
      case PerformanceView.day:
        return _buildDayView(isDark, textColor);
      case PerformanceView.week:
        final totalWeekly = widget.menuController.weeklyEarnings.reduce((a, b) => a + b);
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GANHOS DA SEMANA', style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
                Text('R\$ ${totalWeekly.toStringAsFixed(2)}', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 16),
            WeeklyPerformanceChart(earnings: widget.menuController.weeklyEarnings, isDark: isDark),
          ],
        );
      case PerformanceView.month:
        return _buildMonthView(isDark, textColor);
    }
  }

  Widget _buildDayView(bool isDark, Color textColor) {
    return _buildPandaContainer(
      isDark,
      Column(
        children: [
          Text('GANHOS DE HOJE', style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('R\$ ${widget.menuController.dailyEarnings.toStringAsFixed(2)}', style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          _buildMiniStat('Entregas', '${widget.menuController.dailyDeliveries}', isDark, textColor),
        ],
      )
    );
  }

  Widget _buildMonthView(bool isDark, Color textColor) {
    return _buildPandaContainer(
      isDark,
      Column(
        children: [
          Text('TOTAL DO MÊS', style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('R\$ ${widget.menuController.monthlyEarnings.toStringAsFixed(2)}', style: TextStyle(color: isDark ? const Color(0xFF00FF88) : Colors.blue, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildMiniStat('Pedidos', '${widget.menuController.monthlyDeliveries}', isDark, textColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniStat('Média', 'R\$ ${(widget.menuController.monthlyDeliveries > 0 ? (widget.menuController.monthlyEarnings / widget.menuController.monthlyDeliveries) : 0).toStringAsFixed(2)}', isDark, textColor)),
            ],
          ),
        ],
      )
    );
  }

  Widget _buildMissionStatic(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0055FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROGRESSO', style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
              const Text('2/5', style: TextStyle(color: Color(0xFF0055FF), fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.4,
            backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            color: const Color(0xFF0055FF),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text('Meta: 5 entregas para bônus de R\$ 50,00', style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPandaContainer(bool isDark, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black, width: 1.5),
      ),
      child: child,
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color textColor, bool isDark, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, color: highlight ? const Color(0xFF00FF88) : textColor.withOpacity(0.5), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(color: highlight ? const Color(0xFF00FF88) : textColor, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
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
          border: Border.all(color: isDark ? Colors.white12 : Colors.black, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF00FF88).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFF00FF88), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(subLabel, style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textColor.withOpacity(0.2)),
          ],
        ),
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
            Text(label, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: textColor.withOpacity(0.2), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: OutlinedButton.icon(
        onPressed: () {
          Get.defaultDialog(
            title: 'Sair do Viper?',
            middleText: 'Tem certeza que deseja desconectar?',
            textConfirm: 'SIM',
            textCancel: 'NÃO',
            confirmTextColor: Colors.white,
            buttonColor: Colors.redAccent,
            onConfirm: () {
              Supabase.instance.client.auth.signOut();
              Get.back();
            },
          );
        },
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('SAIR DO APP'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
