import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';

class ViperOfferOverlay extends StatefulWidget {
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
  State<ViperOfferOverlay> createState() => _ViperOfferOverlayState();
}

class _ViperOfferOverlayState extends State<ViperOfferOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 450), // Ciclo suave de pulsar
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05, // Aumento de 5%
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black;

    // Identidade visual baseada no tipo de pedido (ou Super Rota)
    final mainType = widget.offer.orders.isNotEmpty ? widget.offer.orders.first.tipo : ViperOrderType.entrega;
    final serviceColor = widget.offer.isSuper ? Colors.tealAccent[400]! : mainType.color;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              alignment: Alignment.center,
              child: child,
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: widget.offer.priorityBoost > 0 ? Colors.orangeAccent : serviceColor, 
                    width: (widget.offer.isSuper || widget.offer.priorityBoost > 0) ? 3 : 2
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.offer.priorityBoost > 0 ? Colors.orangeAccent : serviceColor).withAlpha(widget.isDark ? 80 : 40),
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
                    if (widget.offer.isSuper)
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
                            color: widget.offer.priorityBoost > 0 ? Colors.orangeAccent : serviceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.offer.priorityBoost > 0 ? 'OFERTA PRIORITÁRIA' : mainType.label,
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
                      'R\$ ${widget.offer.valorTotal.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.offer.isSuper ? 54 : 32,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ida: R\$ 0,85/km  |  Rota: R\$ ${widget.offer.valorKmRota.toStringAsFixed(2)}/km',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor.withOpacity(0.5),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.offer.priorityBoost > 0) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.bolt, color: Colors.greenAccent, size: 14),
                          Text(
                            '+ R\$ ${widget.offer.priorityBoost.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
  
                    // Print Style Body
                    _buildStatRow('Distância Total', '${widget.offer.distanciaTotal.toStringAsFixed(1)} KM', widget.isDark),
                    _buildStatRow('Deslocamento até Coleta', '${widget.offer.distanciaDeslocamento.toStringAsFixed(1)} KM', widget.isDark),
                    _buildStatRow('Valor por KM', 'R\$ ${widget.offer.valorPorKm.toStringAsFixed(2)}', widget.isDark),
                    const Divider(height: 32),
  
                    // Locations
                    _buildLocationRow(
                      Icons.radio_button_checked,
                      'Origem (Coleta)',
                      widget.offer.pickupNeighborhood,
                      widget.offer.pickupStreet,
                      serviceColor,
                      widget.isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildLocationRow(
                      Icons.location_on,
                      'Destino Final',
                      widget.offer.dropoffNeighborhood,
                      widget.offer.dropoffStreet,
                      widget.offer.isSuper ? serviceColor : Colors.green,
                      widget.isDark,
                    ),
                    const SizedBox(height: 20),
  
                    // Summary Info
                    if (widget.offer.isSuper)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: serviceColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Rota otimizada com ${widget.offer.qtdPedidos} entregas sequenciais.',
                            style: TextStyle(color: serviceColor, fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
  
                    // Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBadge(Icons.motorcycle, 'Moto', widget.isDark),
                        const SizedBox(width: 8),
                        _buildBadge(Icons.pix, 'Pix', widget.isDark),
                        if (widget.offer.isSuper) ...[
                          const SizedBox(width: 8),
                          _buildBadge(Icons.layers, '${widget.offer.qtdPedidos} Pedidos', widget.isDark),
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
                            widget.onDecline();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: widget.isDark ? Colors.white10 : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.close, color: Colors.red, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ACEITAR
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C853).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Material(
                                color: const Color(0xFF00C853).withOpacity(0.15), // Base light green
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.vibrate();
                                    widget.onAccept();
                                  },
                                  child: Stack(
                                    children: [
                                      // Camada de Progresso (Vibrante)
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 1.0, end: 0.0),
                                        duration: const Duration(seconds: 12),
                                        builder: (context, value, child) {
                                          return FractionallySizedBox(
                                            widthFactor: value,
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF00C853),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Texto por cima de tudo
                                      const Center(
                                        child: Text(
                                          'ACEITAR',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black26,
                                                offset: Offset(0, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge de Boost (URGENTE)
              if (widget.offer.priorityBoost > 0)
                Positioned(
                  top: -12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.priority_high, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'URGENTE + R\$ ${widget.offer.priorityBoost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
