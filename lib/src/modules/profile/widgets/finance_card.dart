import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/shared/widgets/pix_qr_dialog.dart';
import 'package:viper_delivery/src/modules/profile/widgets/edit_pix_modal.dart';

class FinanceCard extends StatelessWidget {
  final ViperMenuController menuController;

  const FinanceCard({
    super.key,
    required this.menuController,
  });

  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPixModal(
        menuController: menuController,
        initialValue: menuController.driverProfile?.pixKey ?? '',
      ),
    );
  }

  void _showQRDialog(BuildContext context) {
    final pixKey = menuController.driverProfile?.pixKey;
    if (pixKey == null || pixKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre uma chave Pix primeiro.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => PixQRDialog(
        pixKey: pixKey,
        driverName: '${menuController.driverProfile?.firstName} ${menuController.driverProfile?.lastName}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pixKey = menuController.driverProfile?.pixKey ?? 'Não informada';
    final hasPix = menuController.driverProfile?.pixKey != null && menuController.driverProfile!.pixKey!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF00BFA5), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Dados Financeiros',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Pix Key Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHAVE PIX ATUAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : Colors.black54,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pixKey,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: hasPix ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditModal(context),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('EDITAR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showQRDialog(context),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: const Text('QR CODE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
