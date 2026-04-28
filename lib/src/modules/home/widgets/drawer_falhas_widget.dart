import 'package:flutter/material.dart';
import 'package:viper_delivery/src/models/ride_model.dart';

/// Widget do Drawer lateral para visualização de pacotes com falha
/// e funcionalidade de Logística Reversa (devolver ao Centro de Distribuição).
///
/// Projetado para ser embutido no menu central (ViperMenuCentral)
/// como uma seção dedicada.
class DrawerFalhasWidget extends StatelessWidget {
  final List<RideModel> failedOrders;
  final bool isDark;
  final bool hasActiveRoute;
  final VoidCallback onReturnToCD;
  final Function(RideModel) onItemTap;

  const DrawerFalhasWidget({
    super.key,
    required this.failedOrders,
    required this.isDark,
    required this.hasActiveRoute,
    required this.onReturnToCD,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;

    if (failedOrders.isEmpty) {
      return _buildEmptyState(textColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildSectionHeader(textColor),
        const SizedBox(height: 12),

        // Lista de pacotes com falha
        ...failedOrders.map((order) => _buildFailedOrderTile(order, textColor)),

        // Botão "Voltar para o CD" — visível apenas quando a rota principal acabou
        if (!hasActiveRoute && failedOrders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildReturnToCDButton(textColor),
          ),
      ],
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 32,
            color: const Color(0xFF00C853).withOpacity(0.6),
          ),
          const SizedBox(height: 10),
          Text(
            'Sem devoluções pendentes',
            style: TextStyle(
              color: textColor.withOpacity(0.5),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Todas as entregas foram finalizadas.',
            style: TextStyle(color: textColor.withOpacity(0.3), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(Color textColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: Colors.red, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOGÍSTICA REVERSA',
                style: TextStyle(
                  color: textColor.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '${failedOrders.length} pacote${failedOrders.length > 1 ? "s" : ""} para devolução',
                style: TextStyle(
                  color: Colors.red.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFailedOrderTile(RideModel order, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: InkWell(
        onTap: () => onItemTap(order),
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // Ícone de status
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: Colors.red, size: 16),
            ),
            const SizedBox(width: 12),
            // Dados do pedido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.clientName,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.failureReason ?? 'Motivo não informado',
                    style: TextStyle(
                      color: Colors.red.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // ID do pedido
            Text(
              '#${order.id.split('_').last}',
              style: TextStyle(
                color: textColor.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnToCDButton(Color textColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onReturnToCD,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.keyboard_return, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'VOLTAR PARA O CD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
