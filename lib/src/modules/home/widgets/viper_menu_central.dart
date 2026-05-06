import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // [VUP UI]
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/models/ride_model.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/modules/home/views/settings_view.dart';
import 'package:viper_delivery/src/modules/home/widgets/drawer_falhas_widget.dart';
import 'package:viper_delivery/src/modules/home/widgets/weekly_performance_chart.dart';
import 'package:viper_delivery/src/modules/profile/controllers/profile_controller.dart';
import 'package:viper_delivery/src/modules/profile/views/atividades_view.dart';
import 'package:viper_delivery/src/modules/profile/views/help_view.dart';
import 'package:viper_delivery/src/modules/profile/views/profile_view.dart';
import 'package:viper_delivery/src/modules/profile/views/wallet_view.dart';
import 'package:viper_delivery/src/modules/ride/controllers/ride_state_machine.dart';

enum PerformanceView { day, week, month }
enum DocumentsView { vehicle, profile, cnh }

class ViperMenuCentral extends StatefulWidget {
  final SettingsController settingsController;
  final ViperMenuController menuController;
  final VoidCallback? onReturnToCD;

  const ViperMenuCentral({
    super.key,
    required this.settingsController,
    required this.menuController,
    this.onReturnToCD,
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
                              if (!(widget.menuController.driverProfile?.isCompanyDriver ?? false)) ...[
                                _buildSectionTitle('PERFORMANCE E GANHOS', textColor, isDark),
                                const SizedBox(height: 16),
                                _buildPerformanceDashboard(isDark, textColor),
                                const SizedBox(height: 32),
                              ],
                              _buildSectionTitle('LOGÍSTICA REVERSA', textColor, isDark),
                              const SizedBox(height: 16),
                              _buildReverseLogisticsSection(isDark, textColor),

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
                                onPressed: () {
                                  if (!Get.isRegistered<SettingsController>()) { Get.put(SettingsController()); }
                                  Get.to(
                                    () => const ProfileView(),
                                    binding: BindingsBuilder(() => Get.lazyPut(() => ProfileController())),
                                  );
                                },
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
                                onPressed: () => Get.to(
                                  () => SettingsView(settingsController: widget.settingsController),
                                  binding: BindingsBuilder(() => Get.lazyPut(() => ProfileController())),
                                ),
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
                        errorWidget: (context, url, error) => Icon(Icons.person, color: textColor.withValues(alpha: 0.5), size: 35),
                      )
                    : Icon(Icons.person, color: textColor.withValues(alpha: 0.5), size: 35),
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
                        style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Label de Status: Empresa vs Freelancer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (profile?.isCompanyDriver ?? false)
                        ? const Color(0xFF0055FF).withValues(alpha: 0.1) // Azul suave
                        : const Color(0xFF00FF88).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (profile?.isCompanyDriver ?? false)
                          ? const Color(0xFF0055FF).withValues(alpha: 0.3)
                          : const Color(0xFF00FF88).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    (profile?.isCompanyDriver ?? false) ? 'EMPRESA' : 'FREELANCER',
                    style: TextStyle(
                      color: (profile?.isCompanyDriver ?? false)
                          ? const Color(0xFF0055FF)
                          : (isDark ? const Color(0xFF00FF88) : Colors.green[800]),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
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
        color: textColor.withValues(alpha: 0.4),
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
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
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
              color: isSelected ? textColor : textColor.withValues(alpha: 0.4),
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
          _buildVehicleDetail(
            icon: Icons.local_shipping_outlined, 
            label: 'MODELO', 
            value: vehicle?.model, 
            textColor: textColor, 
            isDark: isDark
          ),
          const SizedBox(height: 16),
          _buildVehicleDetail(
            icon: Icons.palette_outlined, 
            label: 'COR', 
            value: vehicle?.color, 
            textColor: textColor, 
            isDark: isDark
          ),
          const SizedBox(height: 16),
          _buildVehicleDetail(
            icon: Icons.tag, 
            label: 'PLACA', 
            value: vehicle?.plate, 
            textColor: textColor, 
            isDark: isDark, 
            isPlate: true
          ),
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
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
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
              color: isSelected ? textColor : textColor.withValues(alpha: 0.4),
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
                Text('GANHOS DA SEMANA', style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold)),
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
          Text('GANHOS DE HOJE', style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold)),
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
          Text('TOTAL DO MÊS', style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold)),
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
        color: const Color(0xFF0055FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROGRESSO', style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold)),
              const Text('2/5', style: TextStyle(color: Color(0xFF0055FF), fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.4,
            backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            color: const Color(0xFF0055FF),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text('Meta: 5 entregas para bônus de R\$ 50,00', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildReverseLogisticsSection(bool isDark, Color textColor) {
    return Obx(() {
        final stateMachine = Get.find<RideStateMachine>();
        final allOrders = stateMachine.activeOrders;
        final failedOrders = allOrders.where((o) => o.status == RideStatus.failed || o.status == RideStatus.returned).toList();
        final hasActive = allOrders.any((o) => o.status != RideStatus.completed && o.status != RideStatus.failed && o.status != RideStatus.returned);

        return DrawerFalhasWidget(
          failedOrders: failedOrders,
          isDark: isDark,
          hasActiveRoute: hasActive,
          onReturnToCD: () {
            Navigator.pop(context); // Fecha o Drawer
            widget.onReturnToCD?.call();
          },
          onItemTap: (order) {
            debugPrint('[DrawerFalhas] Tapped: ${order.clientName} — ${order.failureReason}');
          },
        );
      });
  }

  Widget _buildPandaContainer(bool isDark, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black, width: 1.5),
      ),
      child: child,
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color textColor, bool isDark, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, color: highlight ? const Color(0xFF00FF88) : textColor.withValues(alpha: 0.5), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 8, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(color: highlight ? const Color(0xFF00FF88) : textColor, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget Modular para exibição de detalhes do veículo (Viper V2)
  Widget _buildVehicleDetail({
    required IconData icon,
    required String label,
    required String? value,
    required Color textColor,
    required bool isDark,
    bool isPlate = false,
  }) {
    // Tratamento de Estados Vazios (VUP CIRÚRGICO)
    final bool isMissing = value == null || value.trim().isEmpty;
    
    // Cor de Alerta: Vermelho se pendente, verde se placa, padrão caso contrário
    final Color displayValueColor = isMissing 
        ? Colors.redAccent 
        : (isPlate ? const Color(0xFF00FF88) : textColor);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Simetria vertical
      children: [
        Icon(
          icon, 
          color: isPlate ? const Color(0xFF00FF88) : textColor.withValues(alpha: 0.5), 
          size: 18
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label, 
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.4), 
                  fontSize: 8, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                )
              ),
              const SizedBox(height: 2),
              if (isPlate && !isMissing)
                IntrinsicWidth(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text(
                      value.toUpperCase(),
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.robotoMono(
                        color: const Color(0xFF00FF88),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5, 
                      ),
                    ),
                  ),
                )
              else
                Text(
                  isMissing ? 'Pendente' : value.toUpperCase(),
                  style: TextStyle(
                    color: displayValueColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
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
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF00FF88).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFF00FF88), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(subLabel, style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.2)),
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
          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor.withValues(alpha: 0.6), size: 20),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.2), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 8, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, Color textColor) {
    final buttonBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final iconColor = isDark ? Colors.redAccent : Colors.red;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: TextButton.icon(
        onPressed: () {
          Get.defaultDialog(
            title: 'Sair do Viper?',
            middleText: 'Tem certeza que deseja desconectar?',
            textConfirm: 'SIM',
            textCancel: 'NÃO',
            titleStyle: TextStyle(color: textColor),
            middleTextStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            confirmTextColor: Colors.white,
            buttonColor: Colors.redAccent,
            onConfirm: () {
              Supabase.instance.client.auth.signOut();
              Get.back();
            },
          );
        },
        icon: Icon(Icons.logout, size: 18, color: iconColor),
        label: Text('SAIR DO APP', style: TextStyle(color: iconColor, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          backgroundColor: buttonBgColor,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: iconColor.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }
}

