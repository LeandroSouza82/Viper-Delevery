import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/modules/ride/widgets/payment_selector.dart';
import 'package:viper_delivery/src/shared/widgets/pix_qr_dialog.dart';
import 'package:viper_delivery/src/modules/ride/widgets/delivery_proof_step.dart';
import 'dart:io';

class ViperReceiptBottomSheet extends StatefulWidget {
  final ViperExecutionSummary summary;
  final bool isDark;
  final bool isClt;
  final ViperMenuController menuController;
  final VoidCallback onFinish;

  const ViperReceiptBottomSheet({
    super.key,
    required this.summary,
    required this.isDark,
    required this.isClt,
    required this.menuController,
    required this.onFinish,
  });

  @override
  State<ViperReceiptBottomSheet> createState() => _ViperReceiptBottomSheetState();
}

class _ViperReceiptBottomSheetState extends State<ViperReceiptBottomSheet> {
  bool _isLoading = false;
  bool _paymentActionTaken = false;
  
  String? _receiverName;
  String? _receiverCpf;
  File? _proofPhoto;

  void _showPixQR() {
    setState(() => _paymentActionTaken = true);
    final pixKey = widget.menuController.driverProfile?.pixKey;
    if (pixKey == null || pixKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chave Pix não configurada nos Ajustes.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => PixQRDialog(
        pixKey: pixKey,
        driverName: '${widget.menuController.driverProfile?.firstName} ${widget.menuController.driverProfile?.lastName}',
      ),
    );
  }

  bool _shouldBlockFinalization() {
    if (widget.isClt) return false;

    return _receiverName == null || 
           _receiverName!.isEmpty || 
           _receiverCpf == null || 
           _receiverCpf!.length < 11 || 
           _proofPhoto == null;
  }

  Future<void> _handleFinalization() async {
    if (_shouldBlockFinalization()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É necessário preencher Nome, CPF e Foto da entrega.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await widget.menuController.finalizeRide(
        summary: widget.summary,
        receiverName: _receiverName,
        receiverCpf: _receiverCpf,
        proofPhoto: _proofPhoto,
      );
      widget.onFinish();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao finalizar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black;
    final accentColor = const Color(0xFF00C853);
    final isPending = widget.summary.paymentStatus == ViperPaymentStatus.pending && !widget.isClt;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 54),
          const SizedBox(height: 16),
          Text(
            widget.isClt ? 'ORDEM DE SERVIÇO FINALIZADA' : 'CORRIDA FINALIZADA',
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
            style: TextStyle(color: widget.isDark ? Colors.white54 : Colors.black54),
          ),
          const SizedBox(height: 32),
          
          if (widget.isClt)
            _buildCltSummary(textColor, widget.isDark)
          else ...[
            _buildFinancialSummary(textColor, accentColor, widget.isDark),
            const SizedBox(height: 24),
            // Resumo de Super Rota (Paradas)
            _buildStopsSummary(textColor, widget.isDark),
            const SizedBox(height: 24),
            // NOVO: Check-out Blindado
            DeliveryProofStep(
              isDark: widget.isDark,
              onNameChanged: (val) => setState(() => _receiverName = val),
              onCpfChanged: (val) => setState(() => _receiverCpf = val),
              onPhotoChanged: (val) => setState(() => _proofPhoto = val),
            ),
            const SizedBox(height: 24),
            PaymentSelector(menuController: widget.menuController),
          ],

          const SizedBox(height: 32),
          
          if (isPending) ...[
             Text(
              'A COBRAR DO CLIENTE: R\$ ${widget.summary.totalValue.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showPixQR,
              icon: const Icon(Icons.qr_code_rounded, color: Color(0xFF00BFA5)),
              label: const Text(
                'RECEBER VIA PIX (QR CODE)',
                style: TextStyle(
                  color: Color(0xFF00BFA5),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF00BFA5), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleFinalization,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0055FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFF0055FF).withOpacity(0.5),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text(
                    'CONCLUIR E SAIR',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStopsSummary(Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStopBadge('${widget.summary.countSuccess} SUCESSOS', Colors.green),
          _buildStopBadge('${widget.summary.countFailed} FALHAS', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStopBadge(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
      ],
    );
  }

  Widget _buildFinancialSummary(Color textColor, Color accentColor, bool isDark) {
    return Column(
      children: [
        _buildReceiptRow('Valor Base da Rota', 'R\$ ${widget.summary.baseValue.toStringAsFixed(2)}', textColor),
        const SizedBox(height: 16),
        _buildReceiptRow(
          'Bônus por Entrega (${widget.summary.countSuccess} pts)', 
          '+ R\$ ${widget.summary.successBonus.toStringAsFixed(2)}', 
          accentColor,
        ),
        const SizedBox(height: 16),
        _buildReceiptRow(
          'Taxa de Tentativa (${widget.summary.countFailed} pts)', 
          '+ R\$ ${widget.summary.attemptFee.toStringAsFixed(2)}', 
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
              'R\$ ${widget.summary.totalValue.toStringAsFixed(2)}',
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
