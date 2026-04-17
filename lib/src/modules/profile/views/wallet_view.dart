import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/shared/widgets/pix_qr_dialog.dart';

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.find<SettingsController>();
    final ViperMenuController menuController = Get.find<ViperMenuController>();

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
          'Minha Carteira',
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
            // Card de Saldo Principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                    : [Colors.grey[100]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black,
                  width: 2,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SALDO DISPONÍVEL',
                        style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Icon(Icons.account_balance_wallet_rounded, color: accentColor, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${menuController.dailyEarnings.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implementar saque
                            Get.snackbar(
                              'Solicitação de Saque',
                              'Seu pedido de saque foi enviado para análise.',
                              backgroundColor: Colors.black,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: const Text('SACAR AGORA', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Seção de Chave PIX
            _buildSectionTitle('CHAVE PIX PARA REPASSE', textColor),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.pix_rounded, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUA CHAVE ATUAL',
                          style: TextStyle(
                            color: textColor.withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          menuController.driverProfile?.pixKey ?? 'Nenhuma chave cadastrada',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Chamar modal de edição de PIX que já existe no projeto
                      Get.dialog(PixQRDialog(pixKey: menuController.driverProfile?.pixKey ?? 'https://viperdelivery.com.br/pix'));
                    },
                    icon: Icon(Icons.qr_code_scanner_rounded, color: textColor.withOpacity(0.5)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            // Histórico de Lançamentos
            _buildSectionTitle('LANÇAMENTOS RECENTES', textColor),
            const SizedBox(height: 16),
            _buildTransactionItem('Entrega #5421', '+ R\$ 12,50', 'Hoje, 14:20', accentColor, textColor, isDark),
            _buildTransactionItem('Entrega #5419', '+ R\$ 15,00', 'Hoje, 13:45', accentColor, textColor, isDark),
            _buildTransactionItem('Saque Realizado', '- R\$ 150,00', 'Ontem, 18:10', Colors.redAccent, textColor, isDark),
            _buildTransactionItem('Bônus Metas', '+ R\$ 50,00', '15 Abr, 10:00', accentColor, textColor, isDark),
            
            const SizedBox(height: 40),
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

  Widget _buildTransactionItem(String title, String value, String date, Color valueColor, Color textColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                date,
                style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 11),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
