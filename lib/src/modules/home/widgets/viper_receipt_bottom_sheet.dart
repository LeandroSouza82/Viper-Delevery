import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/models/ride_model.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/modules/ride/controllers/ride_state_machine.dart';
import 'package:viper_delivery/src/modules/ride/widgets/payment_selector.dart';
import 'package:viper_delivery/src/shared/widgets/pix_qr_dialog.dart';

class ViperReceiptBottomSheet extends StatefulWidget {
  final RideExecutionSummary summary;
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
  
  String? _receiverName;
  String? _receiverCpf;
  String? _receiverRelation;

  @override
  void initState() {
    super.initState();
    try {
      final rideSM = Get.find<RideStateMachine>();
      _receiverName = rideSM.lastReceiverName.value.isNotEmpty ? rideSM.lastReceiverName.value : null;
      _receiverCpf = rideSM.lastReceiverCpf.value.isNotEmpty ? rideSM.lastReceiverCpf.value : null;
      _receiverRelation = rideSM.lastReceiverRelation.value.isNotEmpty ? rideSM.lastReceiverRelation.value : null;
    } catch (_) {}
  }

  void _showPixQR() {
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

  Future<void> _handleFinalization() async {
    // ── Guard Clauses com feedback visual explícito ──
    if (!widget.isClt) {
      if (_receiverName == null || _receiverName!.trim().isEmpty) {
        Get.snackbar(
          'Dados Incompletos',
          'O nome do recebedor é obrigatório.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          icon: const Icon(Icons.warning_amber, color: Colors.white),
        );
        return;
      }
      if (_receiverCpf == null || _receiverCpf!.replaceAll(RegExp(r'[^0-9]'), '').length < 11) {
        Get.snackbar(
          'Dados Incompletos',
          'O CPF/RG do recebedor precisa ter no mínimo 11 dígitos.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          icon: const Icon(Icons.warning_amber, color: Colors.white),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    debugPrint('>>> [RECEIPT] PASSO 1: Botão CONCLUIR E SAIR pressionado.');
    
    try {
      debugPrint('>>> [RECEIPT] PASSO 2: Chamando finalizeRide...');
      await widget.menuController.finalizeRide(
        summary: widget.summary,
        rideIds: widget.summary.rideIds,
        receiverName: _receiverName,
        receiverCpf: _receiverCpf,
        proofPhoto: null,
      );
      
      debugPrint('>>> [RECEIPT] PASSO 3: finalizeRide retornou com sucesso!');
      
      // Feedback visual
      Get.snackbar(
        'Sucesso',
        'Entrega finalizada com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );

      debugPrint('>>> [RECEIPT] PASSO 4: Navegando para /home...');
      
      // Navegação definitiva — Get.offAllNamed destrói a widget tree,
      // então o código abaixo deste ponto NÃO executa no contexto deste widget.
      Get.offAllNamed('/home');

    } catch (e, stacktrace) {
      debugPrint('🚨 [RECEIPT] ERRO CRÍTICO: $e');
      debugPrint('🚨 [RECEIPT] STACKTRACE: $stacktrace');
      if (mounted) {
        Get.snackbar(
          'Erro',
          'Não foi possível finalizar. Tente novamente.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      debugPrint('>>> [RECEIPT] PASSO FINAL: Liberando botão (finally).');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildReadOnlyProofCard(Color textColor, bool isDark, String? name, String? cpf, String? relation) {
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    final labelColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DADOS DO COMPROVANTE (COLETADOS)',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueAccent,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField('Recebedor', name ?? 'Não informado', textColor, labelColor),
          const SizedBox(height: 12),
          _buildReadOnlyField('Documento (CPF/RG)', cpf ?? 'Não informado', textColor, labelColor),
          if (relation != null && relation.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildReadOnlyField('Vínculo', relation, textColor, labelColor),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, Color textColor, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black;
    final accentColor = const Color(0xFF00C853);
    final isPending = widget.summary.paymentStatus == RidePaymentStatus.pending && !widget.isClt;

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
            // Comprovante de entrega em modo leitura
            _buildReadOnlyProofCard(textColor, widget.isDark, _receiverName, _receiverCpf, _receiverRelation),
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
                disabledBackgroundColor: const Color(0xFF0055FF).withValues(alpha: 0.5),
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
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
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

