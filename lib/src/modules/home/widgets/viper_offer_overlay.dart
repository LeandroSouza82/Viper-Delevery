import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';

class ViperOfferOverlay extends StatelessWidget {
  final ViperOffer offer;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isDark;

  const ViperOfferOverlay({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onDecline,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    // Identidade visual baseada no tipo de pedido (ou Super Rota)
    final mainType = offer.orders.isNotEmpty ? offer.orders.first.tipo : ViperOrderType.entrega;
    final serviceColor = offer.isSuper ? Colors.tealAccent[400]! : mainType.color;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: serviceColor, width: offer.isSuper ? 3 : 2),
          boxShadow: [
            BoxShadow(
              color: serviceColor.withAlpha(isDark ? 80 : 40),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título Superior (Apenas em Super Rota)
            if (offer.isSuper)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'SUPER ROTA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: serviceColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              )
            else
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: serviceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    mainType.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            
            // VALOR (Destaque Máximo)
            Text(
              'R\$ ${offer.valorTotal.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: offer.isSuper ? 54 : 32,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),

            // Print Style Body
            _buildStatRow('Distância Total', '${offer.distanciaTotal.toStringAsFixed(1)} KM', isDark),
            if (offer.isSuper)
              _buildStatRow('Deslocamento até Coleta', '${offer.distanciaDeslocamento.toStringAsFixed(1)} KM', isDark),
            _buildStatRow('Valor por KM', 'R\$ ${offer.valorPorKm.toStringAsFixed(2)}', isDark),
            const Divider(height: 32),

            // Locations
            _buildLocationRow(
              Icons.radio_button_checked,
              'Origem (Coleta)',
              offer.pickupNeighborhood,
              offer.pickupStreet,
              serviceColor,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildLocationRow(
              Icons.location_on,
              'Destino Final',
              offer.dropoffNeighborhood,
              offer.dropoffStreet,
              offer.isSuper ? serviceColor : Colors.green,
              isDark,
            ),
            const SizedBox(height: 20),

            // Summary Info
            if (offer.isSuper)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: serviceColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Rota otimizada com ${offer.qtdPedidos} entregas sequenciais.',
                    style: TextStyle(color: serviceColor, fontSize: 12, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge(Icons.motorcycle, 'Moto', isDark),
                const SizedBox(width: 8),
                _buildBadge(Icons.pix, 'Pix', isDark),
                if (offer.isSuper) ...[
                  const SizedBox(width: 8),
                  _buildBadge(Icons.layers, '${offer.qtdPedidos} Pedidos', isDark),
                ],
              ],
            ),
            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                // RECUSAR
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onDecline();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close, color: Colors.red, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                // ACEITAR
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.vibrate();
                      onAccept();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'ACEITAR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
          Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    String type,
    String barrio,
    String street,
    Color color,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                barrio,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                street,
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
    );
  }

  Widget _buildBadge(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white54 : Colors.black54),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
