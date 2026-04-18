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
            _buildExpansionFaqItem(
              title: 'Como realizar o seu primeiro saque?',
              isDark: isDark,
              textColor: textColor,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepText('Passo 1:', 'Acesse \'Minha Carteira\' no menu principal.', textColor),
                  _buildStepText('Passo 2:', 'Verifique se o saldo disponível atingiu o mínimo para saque.', textColor),
                  _buildStepText('Passo 3:', 'Toque em \'Solicitar Saque\' e confirme sua chave PIX.', textColor),
                  const SizedBox(height: 8),
                  Text(
                    'O dinheiro cai na conta de forma rápida e segura!',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF00FF88) : Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _buildExpansionFaqItem(
              title: 'O que fazer em caso de acidente?',
              isDark: isDark,
              textColor: textColor,
              iconColorOverride: isDark ? Colors.redAccent : Colors.red[700],
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepText('Passo 1:', 'Mantenha a calma. Sua segurança e do passageiro/carga vêm em primeiro lugar.', textColor),
                  _buildStepText('Passo 2:', 'Se houver feridos, acione imediatamente o SAMU (192) ou a Polícia (190).', textColor),
                  _buildStepText('Passo 3:', 'Assim que estiver seguro, tire fotos do local e dos veículos envolvidos.', textColor),
                  _buildStepText('Passo 4:', 'Entre em contato com o nosso Suporte pelo botão de Emergência no app.', textColor),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.health_and_safety_rounded, color: isDark ? Colors.redAccent : Colors.red[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Protocolo de Segurança Viper: Prioridade Absoluta.',
                          style: TextStyle(
                            color: isDark ? Colors.redAccent : Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildExpansionFaqItem(
              title: 'Como alterar meu veículo cadastrado?',
              isDark: isDark,
              textColor: textColor,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepText('Passo 1:', 'Acesse \'Meu Perfil\' no menu principal.', textColor),
                  _buildStepText('Passo 2:', 'Na seção \'Veículo Ativo\', toque no ícone de edição ou em \'Trocar Veículo\'.', textColor),
                  _buildStepText('Passo 3:', 'Insira os dados do novo veículo (Placa, Modelo, Cor) e envie a foto do documento atualizado (CRLV).', textColor),
                  _buildStepText('Passo 4:', 'Aguarde a nossa equipe validar a documentação. Assim que aprovado, você já pode rodar com o veículo novo!', textColor),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.two_wheeler_rounded, color: isDark ? const Color(0xFF00FF88) : Colors.green[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A troca é concluída após a validação da equipe de suporte.',
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildExpansionFaqItem(
              title: 'Como funciona o cálculo do meu repasse?',
              isDark: isDark,
              textColor: textColor,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepText('Ponto 1:', 'Transparência total: O valor do repasse é calculado assim que a corrida é finalizada.', textColor),
                  _buildStepText('Ponto 2:', 'Taxa do App: O Viper retém apenas uma taxa fixa administrativa sobre o valor total da corrida (consulte os termos vigentes).', textColor),
                  _buildStepText('Ponto 3:', 'Ganhos 100% seus: Valores extras como pedágios ou gorjetas dadas pelo passageiro vão integralmente para a sua carteira.', textColor),
                  _buildStepText('Ponto 4:', 'O saldo é atualizado na sua aba "Minha Carteira" em tempo real.', textColor),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calculate_outlined, color: isDark ? const Color(0xFF00FF88) : Colors.green[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cálculo preciso e auditável a cada quilômetro.',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF00FF88) : Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _buildWhatsAppButton(),

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

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUrl = Uri.parse('https://wa.me/5548996525008?text=Olá,%20preciso%20de%20suporte%20no%20Viper%20Delivery.');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Erro',
        'Não foi possível abrir o WhatsApp. Verifique se o aplicativo está instalado.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildWhatsAppButton() {
    return ElevatedButton(
      onPressed: _launchWhatsApp,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_outlined, size: 20),
          SizedBox(width: 12),
          Text(
            'Falar com um Atendente',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionFaqItem({
    required String title,
    required Widget content,
    required bool isDark,
    required Color textColor,
    Color? iconColorOverride,
  }) {
    final iconColor = iconColorOverride ?? (isDark ? const Color(0xFF00FF88) : Colors.green[700]);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: textColor.withOpacity(0.05))),
      ),
      child: Theme(
        data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(title, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
          iconColor: iconColor,
          collapsedIconColor: textColor.withOpacity(0.3),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepText(String step, String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$step ',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            TextSpan(
              text: text,
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13),
            ),
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
