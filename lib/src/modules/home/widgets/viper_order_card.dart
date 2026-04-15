import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:viper_delivery/src/modules/home/services/external_navigation_service.dart';

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
      // 1. Verificar Geofencing (< 100m)
      final position = await Geolocator.getCurrentPosition();
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        order.lat,
        order.lng,
      );

      if (distance > 100) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você precisa estar no local para registrar falha'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 2. Abrir Bottom Sheet de Motivos
      if (context.mounted) {
        final motivo = await _showFailureReasonSheet(context);
        if (motivo != null) {
          onFailure(order, motivo);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de GPS: $e')),
        );
      }
    }
  }

  Future<String?> _showFailureReasonSheet(BuildContext context) async {
    final reasons = [
      'Cliente Ausente',
      'Endereço não localizado',
      'Local de risco / Sem acesso',
      'Estabelecimento fechado',
      'Recusado pelo destinatário',
      'Outros',
    ];

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF242424) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Motivo da Falha',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              ...reasons.map((reason) => ListTile(
                    title: Text(reason),
                    onTap: () async {
                      if (reason == 'Outros') {
                        final otherReason = await _showOtherReasonDialog(context);
                        if (context.mounted) Navigator.pop(context, otherReason);
                      } else {
                        Navigator.pop(context, reason);
                      }
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _showOtherReasonDialog(BuildContext context) async {
    String text = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descreva o motivo'),
        content: TextField(
          onChanged: (v) => text = v,
          decoration: const InputDecoration(hintText: 'Digite aqui...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(context, text), child: const Text('SALVAR')),
        ],
      ),
    );
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
                // Header: Cliente e Valor (No Topo)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 28), // Espaço para o badge numérico
                        Text(
                          order.cliente,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (isClt)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ORDEM DE SERVIÇO',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      )
                    else
                      Text(
                        'R\$ ${order.valor.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00C853),
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Sub-header: Tipo de Serviço e ID
                Row(
                  children: [
                    const SizedBox(width: 28),
                    Icon(
                      order.tipo == ViperOrderType.coleta ? Icons.storefront : Icons.local_shipping,
                      size: 14,
                      color: serviceColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${order.tipo.label} #${order.id.split('_').last}',
                      style: TextStyle(
                        color: serviceColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // ENDEREÇOS (COLETA -> ENTREGA)
                _buildAddressRow(
                  label: 'COLETA',
                  bairro: order.bairroColeta,
                  endereco: order.enderecoColeta,
                  icon: Icons.radio_button_checked,
                  color: Colors.orange,
                  isDark: isDark,
                  textColor: textColor,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    height: 12,
                    child: VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
                  ),
                ),
                _buildAddressRow(
                  label: 'ENTREGA',
                  bairro: order.bairroEntrega,
                  endereco: order.enderecoEntrega,
                  icon: Icons.location_on,
                  color: Colors.blueAccent,
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(height: 20),

                // Botões de Ação
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ExternalNavigationService.openRoute(order.enderecoEntrega),
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
          
          // Indicador de Reordenação (Icone decorativo no topo direito se desejar, ou apenas omitir pois o ReorderableListView lida com isso)
        ],
      ),
    );
  }

  Widget _buildAddressRow({
    required String label,
    required String bairro,
    required String endereco,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
              ),
              Text(
                bairro,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                endereco,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
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
