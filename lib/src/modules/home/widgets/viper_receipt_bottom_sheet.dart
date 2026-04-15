import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';

class ViperReceiptBottomSheet extends StatelessWidget {
  final ViperExecutionSummary summary;
  final bool isDark;
  final bool isClt;
  final VoidCallback onFinish;

  const ViperReceiptBottomSheet({
    super.key,
    required this.summary,
    required this.isDark,
    required this.isClt,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final accentColor = const Color(0xFF00C853);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 54),
          const SizedBox(height: 16),
          Text(
            isClt ? 'ORDEM DE SERVIÇO FINALIZADA' : 'CORRIDA FINALIZADA',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Resumo de execução e ganhos',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
          ),
          const SizedBox(height: 32),
          
          if (isClt)
            _buildCltSummary(textColor, isDark)
          else
            _buildFinancialSummary(textColor, accentColor, isDark),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0055FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'CONCLUIR E SAIR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(Color textColor, Color accentColor, bool isDark) {
    return Column(
      children: [
        _buildReceiptRow('Valor Base da Rota', 'R\$ ${summary.baseValue.toStringAsFixed(2)}', textColor),
        const SizedBox(height: 16),
        _buildReceiptRow(
          'Bônus por Entrega (${summary.countSuccess} pts)', 
          '+ R\$ ${summary.successBonus.toStringAsFixed(2)}', 
          accentColor,
        ),
        const SizedBox(height: 16),
        _buildReceiptRow(
          'Taxa de Tentativa (${summary.countFailed} pts)', 
          '+ R\$ ${summary.attemptFee.toStringAsFixed(2)}', 
          accentColor,
        ),
        const SizedBox(height: 20),
        Divider(color: isDark ? Colors.white12 : Colors.black12),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOTAL LÍQUIDO',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'R\$ ${summary.totalValue.toStringAsFixed(2)}',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 24),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCltSummary(Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withAlpha(50)),
      ),
      child: Column(
        children: [
          const Icon(Icons.business_center_outlined, color: Colors.blue),
          const SizedBox(height: 12),
          Text(
            'EXECUÇÃO REGISTRADA',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Os dados desta rota foram transmitidos para o painel administrativo da empresa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
