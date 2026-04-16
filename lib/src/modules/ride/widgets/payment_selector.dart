import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/shared/widgets/pix_qr_dialog.dart';

class PaymentSelector extends StatelessWidget {
  final ViperMenuController menuController;

  const PaymentSelector({
    super.key,
    required this.menuController,
  });

  void _showPixQR(BuildContext context) {
    final pixKey = menuController.driverProfile?.pixKey;
    if (pixKey == null || pixKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chave Pix não cadastrada no perfil.')),
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPixQR(context),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_rounded, color: Color(0xFF00BFA5), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pagar via Pix',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Clique para exibir o QR Code',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
