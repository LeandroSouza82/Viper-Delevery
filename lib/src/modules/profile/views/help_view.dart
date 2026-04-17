import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        'Erro',
        'Não foi possível abrir o link: $url',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.find<SettingsController>();

    final isDark = settingsController.isDarkTheme;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final accentColor = const Color(0xFF00FF88);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Ajuda e Suporte',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de Suporte Rápido
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accentColor, width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(Icons.support_agent_rounded, color: accentColor, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Como podemos ajudar?',
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nossa equipe está pronta para te atender.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _buildSectionTitle('CANAIS DE ATENDIMENTO', textColor),
            const SizedBox(height: 16),
            _buildSupportTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Chat em Tempo Real',
              subtitle: 'Tempo médio de espera: 5 min',
              textColor: textColor,
              isDark: isDark,
              onTap: () {
                // Preparado para url_launcher ou chat interno
                // _launchURL('https://suporte.viperdelivery.com.br/chat');
                Get.snackbar('Em Breve', 'O chat em tempo real estará disponível na próxima atualização.');
              },
            ),
            const SizedBox(height: 12),
            _buildSupportTile(
              icon: Icons.language_rounded,
              title: 'Central de Ajuda (Web)',
              subtitle: 'Manuais e tutoriais completos',
              textColor: textColor,
              isDark: isDark,
              onTap: () => _launchURL('https://viperdelivery.com.br/ajuda'),
            ),

            const SizedBox(height: 40),

            _buildSectionTitle('DÚVIDAS FREQUENTES', textColor),
            const SizedBox(height: 16),
            _buildFaqItem('Como realizar o primeiro saque?', textColor),
            _buildFaqItem('O que fazer em caso de acidente?', textColor),
            _buildFaqItem('Como alterar meu veículo cadastrado?', textColor),
            _buildFaqItem('Dúvidas sobre o cálculo de repasses', textColor),

            const SizedBox(height: 40),
            
            Center(
              child: Text(
                'Viper Delivery v1.0.0 (Beta)',
                style: TextStyle(color: textColor.withOpacity(0.3), fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
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

  Widget _buildSupportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00FF88), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textColor.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: textColor.withOpacity(0.05))),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(question, style: TextStyle(color: textColor, fontSize: 14)),
        trailing: Icon(Icons.add, color: textColor.withOpacity(0.3), size: 20),
        onTap: () {
          // TODO: Expandir resposta
        },
      ),
    );
  }
}
