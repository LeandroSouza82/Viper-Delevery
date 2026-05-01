import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gerador modular de marcadores de mapa (PointAnnotations) para o Mapbox.
class MarkerGenerator {
  /// Desenha programaticamente o clássico pino "Gota Invertida" (Teardrop).
  /// [color] - Cor de fundo do pino (dependente do tipo de serviço).
  /// [text] - Número ou caractere que será desenhado no centro.
  static Future<Uint8List> generateTeardropMarker({
    required Color color,
    required String text,
  }) async {
    const double size = 140.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    final double cx = size / 2;
    final double cy = size * 0.4;
    final double radius = size * 0.35;

    // 1. Sombra projetada
    final shadowPath = Path();
    shadowPath.addOval(Rect.fromCenter(center: Offset(cx, size - 10), width: radius * 1.5, height: 16));
    canvas.drawShadow(shadowPath, Colors.black, 6, true);

    // 2. Caminho matemático da Gota Invertida
    final path = Path();
    path.moveTo(cx, size - 12); // Ponta inferior (bico)
    
    // Curva lateral esquerda subindo
    path.quadraticBezierTo(cx - radius, size * 0.75, cx - radius, cy);
    
    // Semicírculo superior
    path.arcToPoint(
      Offset(cx + radius, cy),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    
    // Curva lateral direita descendo
    path.quadraticBezierTo(cx + radius, size * 0.75, cx, size - 12);
    path.close();

    // 3. Preenchimento Dinâmico (Color Coding)
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 4. Borda (Stroke) Premium
    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // 5. Máscara circular interna sutil para contraste
    final innerPaint = Paint()..color = Colors.black.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(cx, cy), radius * 0.65, innerPaint);

    // 6. Texto / Numeração
    if (text.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: text.length > 1 ? 46 : 54,
            fontWeight: FontWeight.w900,
            letterSpacing: -1, // Compacta números com 2 dígitos
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          cx - (textPainter.width / 2),
          cy - (textPainter.height / 2),
        ),
      );
    }

    // 7. Rasterização
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}

