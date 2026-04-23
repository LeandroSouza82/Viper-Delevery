import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:viper_delivery/src/modules/home/services/external_navigation_service.dart';
import 'package:viper_delivery/src/modules/home/widgets/modals/failure_modal.dart';

class ViperOrderCard extends StatelessWidget {
  final ViperOrder order;
  final bool isDark;
  final VoidCallback onRemove;
  final Function(ViperOrder, String) onFailure;
  final VoidCallback onFinish;
  final int index;
  final bool isClt;

  const ViperOrderCard({
    required Key key,
    required this.order,
    required this.isDark,
    required this.onRemove,
    required this.onFailure,
    required this.onFinish,
    required this.index,
    this.isClt = false,
  }) : super(key: key);

  Future<void> _processDeliveryFailure(BuildContext context) async {
    try {
      // TODO: VOLTAR TRAVA DE CHEGADA AQUI DEPOIS DOS TESTES.
      if (context.mounted) {
        await FailureModal.show(context, rideId: order.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar falha: $e')),
        );
      }
    }
  }

  /// Texto da observação do gestor. Usa o campo [order.observacao] ou
  /// simula um exemplo padrão para demonstração.
  String get _observacaoText {
    if (order.observacao != null && order.observacao!.isNotEmpty) {
      return order.observacao!;
    }
    // Simulação: frase de exemplo alternada pelo index
    const exemplos = [
      'Entregar em mãos ao destinatário',
      'Cuidado com o cão — portão lateral',
      'Tocar interfone 2x e aguardar',
      'Deixar na portaria se ausente',
    ];
    return exemplos[index % exemplos.length];
  }

  @override
  Widget build(BuildContext context) {
    final serviceColor = order.tipo.color;
    final cardBg = isDark ? Colors.white.withAlpha(5) : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: serviceColor, width: 1.5),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── A. NOME DO CLIENTE ──
                Row(
                  children: [
                    const SizedBox(width: 28), // Espaço para o badge numérico
                    Expanded(
                      child: Text(
                        order.cliente,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Sub-header: Tipo de Serviço e ID
                Row(
                  children: [
                    const SizedBox(width: 28),
                    Icon(Icons.local_shipping, size: 14, color: serviceColor),
                    const SizedBox(width: 6),
                    Text(
                      'ENTREGA #${order.id.split('_').last}',
                      style: TextStyle(
                        color: serviceColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // ── B. ENDEREÇO DO CLIENTE (DESTINO FINAL — ÚNICO) ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 18, color: serviceColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.bairroEntrega,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.enderecoEntrega,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── C. BLOCO DE OBSERVAÇÃO DO GESTOR (ALERTA LARANJA) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withAlpha(60), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.info_outline, color: Colors.deepOrange, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _observacaoText,
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── D. BOTÕES DE AÇÃO ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ExternalNavigationService.abrirNavegador(
                          lat: order.lat,
                          lng: order.lng,
                          context: context,
                        ),
                        icon: const Icon(Icons.navigation, size: 18),
                        label: const Text('ROTA', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: serviceColor,
                          side: BorderSide(color: serviceColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.close,
                      color: Colors.red,
                      onPressed: () => _processDeliveryFailure(context),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.check,
                      color: const Color(0xFF00C853),
                      onPressed: onFinish,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Badge Numérico (Posição na Rota)
          Positioned(
            top: 14,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: serviceColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 4),
                ],
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(100), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
