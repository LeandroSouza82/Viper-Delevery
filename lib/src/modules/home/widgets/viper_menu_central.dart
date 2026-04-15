import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/modules/home/widgets/weekly_performance_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViperMenuCentral extends StatefulWidget {
  final SettingsController settingsController;

  const ViperMenuCentral({
    super.key,
    required this.settingsController,
  });

  @override
  State<ViperMenuCentral> createState() => _ViperMenuCentralState();
}

class _ViperMenuCentralState extends State<ViperMenuCentral> {
  final _menuController = ViperMenuController();

  @override
  void initState() {
    super.initState();
    _menuController.fetchAllData();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_menuController, widget.settingsController]),
      builder: (context, child) {
        final isDark = widget.settingsController.isDarkTheme;
        final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final dividerColor = isDark ? Colors.white12 : Colors.black12;

        return Drawer(
          backgroundColor: bgColor,
          width: MediaQuery.of(context).size.width * 0.85,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
          ),
          child: _menuController.isLoading 
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
                              // Base: O gráfico semanal
                              _buildSectionTitle('PERFORMANCE SEMANAL', textColor, isDark),
                              const SizedBox(height: 16),
                              WeeklyPerformanceChart(
                                earnings: _menuController.weeklyEarnings,
                                isDark: isDark,
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
    final photoUrl = _menuController.driverProfile?['foto_url'] as String?;
    final firstName = _menuController.driverProfile?['first_name'] ?? 'Motorista';
    final city = _menuController.driverProfile?['city'] ?? 'Base Não Informada';
    final state = _menuController.driverProfile?['state'] ?? '';

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
              child: photoUrl != null 
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                        errorWidget: (context, url, error) => Icon(Icons.person, color: textColor, size: 35),
                        fit: BoxFit.cover,
                        width: 70,
                        height: 70,
                      ),
                    )
                  : Icon(Icons.person, color: textColor, size: 35),
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
                          color: textColor.withValues(alpha: 0.5),
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
        color: textColor.withValues(alpha: 0.4),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildProfileCard(bool isDark, Color textColor) {
    // FIX DE TIPAGEM: Supabase retorna veículos como uma lista
    final vehicles = _menuController.driverProfile?['vehicles'] as List?;
    final vehicle = (vehicles != null && vehicles.isNotEmpty) ? vehicles.first : null;
    
    final plate = vehicle?['plate'] ?? '-- -- --';
    final model = vehicle?['model'] ?? 'Veículo não cadastrado';
    final cnh = _menuController.driverProfile?['cnh_number'] ?? '**********';
    final cat = _menuController.driverProfile?['cnh_category'] ?? 'A/B';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
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
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          _buildInfoItem(Icons.local_shipping_outlined, 'VEÍCULO ($model)', plate, textColor, isDark, highlight: true),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color textColor, bool isDark, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, color: highlight ? const Color(0xFF00FF88) : textColor.withValues(alpha: 0.5), size: 22),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold)),
            Text(
              value, 
              style: TextStyle(
                color: highlight ? const Color(0xFF00FF88) : textColor, 
                fontSize: 15, 
                fontWeight: highlight ? FontWeight.w900 : FontWeight.bold
              )
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMissionStatic(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0055FF).withValues(alpha: 0.1),
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
              Text('PROGRESSO', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold)),
              const Text('2/5', style: TextStyle(color: Color(0xFF0055FF), fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.4,
            backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            color: const Color(0xFF0055FF),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(
            'Faltam 3 entregas para o bônus de R\$ 50,00',
            style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11),
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
            onPressed: () => Supabase.instance.client.auth.signOut(),
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
}
