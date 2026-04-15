import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/services/viper_mock_service.dart';

/// Card de parada na Super Rota (cores por tipo de serviço).
class ViperOrderCard extends StatelessWidget {
  const ViperOrderCard({
    super.key,
    required this.order,
    required this.accent,
    required this.cardGradient,
    required this.isDark,
    required this.onRota,
    required this.onFalha,
    required this.onOk,
  });

  final ViperOrder order;
  final Color accent;
  final List<Color> cardGradient;
  final bool isDark;
  final VoidCallback onRota;
  final VoidCallback onFalha;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final textOnCard = Colors.white;
    final enderecoColor = Colors.white.withValues(alpha: isDark ? 0.95 : 0.9);
    final noteBg = Colors.black.withValues(alpha: isDark ? 0.35 : 0.18);
    final noteBorder = Colors.white.withValues(alpha: isDark ? 0.28 : 0.35);
    final noteText = isDark
        ? const Color(0xFFFFF8E1)
        : const Color(0xFF4A3728);
    final noteIcon = isDark ? Colors.amber.shade200 : Colors.amber.shade800;
    final buttonFill = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.tipoLabel,
              style: TextStyle(
                color: textOnCard,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              order.cliente,
              style: TextStyle(
                color: textOnCard,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              order.endereco,
              style: TextStyle(
                color: enderecoColor,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: noteBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: noteBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 18,
                    color: noteIcon,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.observacao,
                      style: TextStyle(
                        color: noteText,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ServiceOutlinedButton(
                      label: 'Rota',
                      color: accent,
                      fillColor: buttonFill,
                      onPressed: onRota,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ServiceOutlinedButton(
                      label: 'Falha',
                      color: accent,
                      fillColor: buttonFill,
                      onPressed: onFalha,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ServiceOutlinedButton(
                      label: 'OK',
                      color: accent,
                      fillColor: buttonFill,
                      onPressed: onOk,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (Color accent, List<Color> gradient) paletteFor(ViperTipoPedido tipo) {
    switch (tipo) {
      case ViperTipoPedido.coleta:
        return (
          const Color(0xFFFF6B2C),
          [const Color(0xFFFF8A50), const Color(0xFFE85A1C)],
        );
      case ViperTipoPedido.entrega:
        return (
          const Color(0xFF1E6FF4),
          [const Color(0xFF4A9FFF), const Color(0xFF0D52D4)],
        );
      case ViperTipoPedido.outros:
        return (
          const Color(0xFF9D6BFF),
          [const Color(0xFFB794FF), const Color(0xFF7C4DFF)],
        );
    }
  }
}

class _ServiceOutlinedButton extends StatelessWidget {
  const _ServiceOutlinedButton({
    required this.label,
    required this.color,
    required this.fillColor,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color fillColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.6),
        backgroundColor: fillColor,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
