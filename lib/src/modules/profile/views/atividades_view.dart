import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/profile/views/history_view.dart';
import 'package:viper_delivery/src/modules/profile/views/wallet_view.dart';
import 'package:viper_delivery/src/modules/profile/views/acceptance_rate_view.dart';

class AtividadesView extends StatefulWidget {
  const AtividadesView({super.key});

  @override
  State<AtividadesView> createState() => _AtividadesViewState();
}

class _AtividadesViewState extends State<AtividadesView> {
  @override
  Widget build(BuildContext context) {
    // Busca controllers existentes
    final SettingsController settingsController = Get.find<SettingsController>();

    final isDark = settingsController.isDarkTheme;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Atividades',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 1.1,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xFF00FF88),
            indicatorWeight: 3,
            labelColor: const Color(0xFF00FF88),
            unselectedLabelColor: textColor.withOpacity(0.4),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Hoje'),
              Tab(text: 'Semanal'),
              Tab(text: 'Mensal'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHojeTab(isDark, textColor),
            _buildPlaceholderTab('Performance Semanal', Icons.insights_rounded, isDark, textColor),
            _buildPlaceholderTab('Performance Mensal', Icons.calendar_month_rounded, isDark, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHojeTab(bool isDark, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // Header de Ganhos
          Column(
            children: [
              Text(
                'Ganhos totais',
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ 0,00',
                style: TextStyle(
                  color: textColor,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Grid de Performance (3 colunas)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.local_shipping_rounded,
                  'Corridas',
                  '0',
                  const Color(0xFF0055FF),
                  textColor,
                ),
                _buildStatItem(
                  Icons.access_time_filled_rounded,
                  'Tempo Online',
                  '0h 00m',
                  const Color(0xFF00FF88),
                  textColor,
                ),
                _buildStatItem(
                  Icons.timer_rounded,
                  'Trabalhado',
                  '0h 00m',
                  Colors.orangeAccent,
                  textColor,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Seção de Ações Rápidas
          _buildActionSection(isDark, textColor),
          
          const SizedBox(height: 32),
          
          Text(
            'Fique online para começar a lucrar!',
            style: TextStyle(
              color: textColor.withOpacity(0.3),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color iconColor, Color textColor) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor.withOpacity(0.4),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AÇÕES RÁPIDAS',
          style: TextStyle(
            color: textColor.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.list_alt_rounded,
          label: 'Histórico de Corridas',
          isDark: isDark,
          textColor: textColor,
          onPressed: () => Get.to(() => const HistoryView()),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Minha Carteira',
          isDark: isDark,
          textColor: textColor,
          onPressed: () => Get.to(() => const WalletView()),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.fact_check_rounded,
          label: 'Taxa de Aceitação',
          isDark: isDark,
          textColor: textColor,
          onPressed: () => Get.to(() => const AcceptanceRateView()),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDark ? const Color(0xFF00FF88) : const Color(0xFF0055FF), size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: textColor.withOpacity(0.2), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon, bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: textColor.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: textColor.withOpacity(0.3),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gráficos em breve...',
            style: TextStyle(
              color: textColor.withOpacity(0.2),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
