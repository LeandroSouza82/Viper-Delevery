import 'package:flutter/material.dart';

/// Modal de falha na entrega com Dropdown de motivos e campo de observação.
///
/// Ao confirmar, retorna um [FailureResult] contendo o motivo selecionado
/// e a observação extra. A lógica de mover para logística reversa é
/// responsabilidade do chamador.
class FailureResult {
  final String motivo;
  final String? observacao;

  const FailureResult({required this.motivo, this.observacao});

  @override
  String toString() => 'FailureResult(motivo: $motivo, obs: $observacao)';
}

class FailureModal {
  static const List<String> _defaultReasons = [
    'Cliente Ausente',
    'Endereço não encontrado',
    'Recusado pelo destinatário',
    'Local de risco / Sem acesso',
    'Estabelecimento fechado',
  ];

  /// Exibe o modal de falha. Retorna [FailureResult] ou `null` se cancelado.
  static Future<FailureResult?> show(
    BuildContext context, {
    required bool isDark,
    required String clienteName,
  }) {
    return showModalBottomSheet<FailureResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FailureSheet(
        isDark: isDark,
        clienteName: clienteName,
      ),
    );
  }
}

class _FailureSheet extends StatefulWidget {
  final bool isDark;
  final String clienteName;

  const _FailureSheet({required this.isDark, required this.clienteName});

  @override
  State<_FailureSheet> createState() => _FailureSheetState();
}

class _FailureSheetState extends State<_FailureSheet> {
  String? _selectedReason;
  final _obsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o motivo da falha.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = FailureResult(
      motivo: _selectedReason!,
      observacao: _obsController.text.isNotEmpty ? _obsController.text : null,
    );

    // Mock: Log da falha
    debugPrint('══════════════════════════════════════════════');
    debugPrint('❌ [FALHA] Entrega não realizada');
    debugPrint('   Cliente: ${widget.clienteName}');
    debugPrint('   Motivo: ${result.motivo}');
    debugPrint('   Obs: ${result.observacao ?? "—"}');
    debugPrint('══════════════════════════════════════════════');

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black;
    final cardBorder = widget.isDark ? Colors.white12 : Colors.black12;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24, 12, 24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cardBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'REGISTRAR FALHA',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliente: ${widget.clienteName}',
                  style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Dropdown de Motivos
                Text(
                  'MOTIVO DA FALHA',
                  style: TextStyle(
                    color: textColor.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedReason,
                      hint: Text(
                        'Selecione o motivo...',
                        style: TextStyle(color: textColor.withOpacity(0.4)),
                      ),
                      dropdownColor: widget.isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      style: TextStyle(color: textColor, fontSize: 14),
                      icon: Icon(Icons.expand_more, color: textColor.withOpacity(0.4)),
                      items: FailureModal._defaultReasons.map((reason) {
                        return DropdownMenuItem(
                          value: reason,
                          child: Text(reason),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedReason = value),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de Observação
                Text(
                  'OBSERVAÇÃO (OPCIONAL)',
                  style: TextStyle(
                    color: textColor.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _obsController,
                  maxLines: 3,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Descreva detalhes adicionais se necessário...',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
                    filled: true,
                    fillColor: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor.withOpacity(0.6),
                          side: BorderSide(color: cardBorder, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _confirm,
                        icon: const Icon(Icons.report_problem, size: 18),
                        label: const Text('CONFIRMAR FALHA', style: TextStyle(fontWeight: FontWeight.w900)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
