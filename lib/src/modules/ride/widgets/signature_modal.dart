import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:viper_delivery/src/models/ride_model.dart';
import 'package:viper_delivery/src/modules/ride/controllers/ride_state_machine.dart';
import 'package:viper_delivery/src/modules/ride/services/delivery_proof_service.dart';
import 'package:viper_delivery/src/modules/ride/services/upload_queue_service.dart';
import 'package:path_provider/path_provider.dart';

/// Modal de assinatura do cliente estruturado em DOIS PASSOS (Padrão Enterprise):
/// Passo 1: Formulário de Coleta de Dados (Portrait - Vertical).
/// Passo 2: Canvas Maximizada de Assinatura (Landscape - Horizontal).
class SignatureModal {
  /// Exibe o modal. Retorna `true` se assinado com sucesso.
  static Future<bool?> show(BuildContext context, {required bool isDark, required String rideId}) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, _) {
        return _SignatureDialog(isDark: isDark, rideId: rideId);
      },
    );

    // Retorno Obrigatório de hardware: força o app a voltar para vertical
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return result;
  }
}

class _SignatureDialog extends StatefulWidget {
  final bool isDark;
  final String rideId;
  const _SignatureDialog({required this.isDark, required this.rideId});

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  
  // Controle de Fluxo: 1 = Formulário (Portrait), 2 = Canvas (Landscape)
  int _step = 1;

  // Controladores dos campos
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _aptoController = TextEditingController();
  String? _selectedRelation;

  final _proofService = DeliveryProofService();
  XFile? _photoFile;
  bool _isUploading = false;

  bool get _hasSignature => _strokes.isNotEmpty || _currentStroke.isNotEmpty;
  bool get _isPhotoFlow => _selectedRelation == 'Locker' || _selectedRelation == 'Correio';

  @override
  void initState() {
    super.initState();
    // Passo 1 inicializa estritamente em Portrait (Em pé) para digitação
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _aptoController.dispose();
    
    // Restaura a trava global para vertical (Bloqueio em pé) no encerramento
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _avancarParaAcao() async {
    FocusScope.of(context).unfocus(); // Oculta o teclado virtual

    if (_isPhotoFlow) {
      // Fluxo B (Prova Fotográfica)
      await _capturarFoto();
    } else {
      // Fluxo A (Assinatura)
      setState(() {
        _step = 2; // Avança fluxo
      });
      
      // Libera / Força a tela deitada para assinatura (Maximização)
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _capturarFoto() async {
    final picker = ImagePicker();
    // Compressão Extrema
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 30, // 30% da qualidade original (alto ganho de banda)
      maxWidth: 800,    // Hard-limit para economizar bytes Supabase
    );
    
    if (photo != null) {
      setState(() {
        _photoFile = photo;
        _step = 3; // Passo 1.5: Preview View
      });
    }
  }

  Future<void> _enviarProvaFotografica() async {
    if (_photoFile == null) return;

    setState(() => _isUploading = true);
    debugPrint('>>> [MODAL] Finalização Otimista por FOTO para ID: ${widget.rideId}');

    // 1. Update de Status Imediato (Garante a entrega no banco)
    final success = await _proofService.updateStatusOnly(widget.rideId);

    if (success) {
      // 2. Enfileirar Upload em Background
      final queue = Get.find<UploadQueueService>();
      await queue.addTask(
        rideId: widget.rideId,
        filePath: _photoFile!.path,
        receiverName: _nameController.text,
        document: _documentController.text,
        relation: _selectedRelation == 'Morador' ? 'Morador (${_aptoController.text})' : (_selectedRelation ?? 'Locker'),
      );

      // 3. Fechar Imediatamente
      _concluirEFechar('Entrega concluída! Sincronizando comprovante...');
    } else {
      setState(() => _isUploading = false);
      _mostrarErroEnvio();
    }
  }

  void _concluirEFechar(String mensagem) {
    if (!mounted) return;
    
    // 1. Notificação Visual (Snackbar)
    Get.snackbar(
      'Sucesso!',
      mensagem,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );

    // 2. Remover o card da lista localmente (GetX)
    try {
      final rideSM = Get.find<RideStateMachine>();
      rideSM.removerCorridaDaTela(widget.rideId, RideStatus.completed);
    } catch (e) {
      debugPrint('Erro ao encontrar RideStateMachine: $e');
    }

    // 3. Fechar Modal
    Navigator.of(context).pop(true);
  }

  void _mostrarErroEnvio() {
    if (!mounted) return;
    Get.snackbar(
      'Erro na Finalização',
      'Não foi possível atualizar o status da entrega. Verifique sua conexão.',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  Future<void> _confirmSignature() async {
    if (!_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, colete a assinatura antes de confirmar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    debugPrint('>>> [MODAL] Finalização Otimista por ASSINATURA...');

    try {
      // 1. Converter Canvas para Imagem (PNG Bytes)
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      final paint = Paint()
        ..color = widget.isDark ? Colors.white : Colors.black
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final stroke in _strokes) {
        if (stroke.length < 2) continue;
        final path = ui.Path();
        path.moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(1000, 400); 
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // 2. Salvar bytes em arquivo temporário persistente para a fila
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_sig_${widget.rideId}.png');
      await tempFile.writeAsBytes(bytes);

      // 3. Update de Status Imediato
      final success = await _proofService.updateStatusOnly(widget.rideId);

      if (success) {
        // 4. Enfileirar Background Sync
        final queue = Get.find<UploadQueueService>();
        await queue.addTask(
          rideId: widget.rideId,
          filePath: tempFile.path,
          receiverName: _nameController.text,
          document: _documentController.text,
          relation: _selectedRelation ?? 'Próprio',
        );

        _concluirEFechar('Entrega concluída com sucesso!');
      } else {
        _mostrarErroEnvio();
      }
    } catch (e) {
      debugPrint('>>> [MODAL] ERRO CRÍTICO NO PROCESSAMENTO: $e');
      _mostrarErroEnvio();
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Helper criador de Inputs com design dinâmico
  Widget _buildField({
    required String hint, 
    TextInputType? type, 
    required ThemeData theme,
    required Color textColor,
    required Color canvasBg,
    required TextEditingController controller,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: TextStyle(color: textColor, fontSize: 14),
        keyboardType: type,
        inputFormatters: formatters,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textColor.withAlpha(100), fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: canvasBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00C853), width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final canvasBg = theme.colorScheme.onSurface.withValues(alpha: 0.05);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          // Ignora insets do teclado para não amassar o Modal bruscamente
          child: SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.all(_step == 1 ? 24 : 16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF00C853),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: _step == 1 
                    ? _buildPasso1(theme, textColor, canvasBg) 
                    : _step == 3 
                        ? _buildPassoPhotoPreview(theme, textColor, canvasBg)
                        : _buildPasso2(theme, textColor, canvasBg),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // PASSO 1: Formulário Compacto de Coleta em (Portrait)
  // =========================================================================
  Widget _buildPasso1(ThemeData theme, Color textColor, Color canvasBg) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Simples
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: Color(0xFF00C853), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DADOS DO RECEBEDOR',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: textColor.withValues(alpha: 0.5)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campos em Vertical (Como estamos em Portrait, é espaçoso)
          _buildField(
            hint: 'Nome de quem está recebendo', 
            type: TextInputType.name,
            theme: theme, 
            textColor: textColor, 
            canvasBg: canvasBg,
            controller: _nameController,
          ),
          _buildField(
            hint: 'RG ou CPF', 
            type: TextInputType.number, // Otimização de UX: Teclado numérico acelera a digitação
            theme: theme, 
            textColor: textColor, 
            canvasBg: canvasBg,
            controller: _documentController,
            formatters: [CpfRgInputFormatter()],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedRelation,
              dropdownColor: theme.colorScheme.surface,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00C853)),
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Vínculo com o destinatário',
                hintStyle: TextStyle(color: textColor.withAlpha(100), fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: canvasBg,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00C853), width: 1.5),
                ),
              ),
              items: ['Próprio', 'Porteiro', 'Síndico', 'Zelador', 'Faxineiro', 'Morador', 'Locker', 'Correio', 'Outros']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedRelation = newValue;
                });
              },
            ),
          ),
          
          if (_selectedRelation == 'Morador') 
            _buildField(
              hint: 'Número do Apto / Bloco', 
              type: TextInputType.text,
              theme: theme, 
              textColor: textColor, 
              canvasBg: canvasBg,
              controller: _aptoController,
            ),

          const SizedBox(height: 12),

          // Botão de Avanço Dinâmico (Dual Flux)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _avancarParaAcao,
              icon: Icon(_isPhotoFlow ? Icons.camera_alt : Icons.draw, size: 20),
              label: Text(
                _isPhotoFlow ? 'ABRIR CÂMERA E FINALIZAR' : 'AVANÇAR PARA ASSINATURA', 
                style: const TextStyle(fontWeight: FontWeight.w900)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPhotoFlow ? const Color(0xFF0055FF) : const Color(0xFF00C853),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PASSO 1.5: Preview e Garantia da Câmera (Supabase Engine)
  // =========================================================================
  Widget _buildPassoPhotoPreview(ThemeData theme, Color textColor, Color canvasBg) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.camera_alt, color: Color(0xFF0055FF), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PRÉVIA DA FOTOGRAFIA',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: textColor.withValues(alpha: 0.5)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_photoFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_photoFile!.path),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _capturarFoto,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('NOVA FOTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: theme.dividerColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _enviarProvaFotografica,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0055FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isUploading 
                      ? const SizedBox(
                          height: 20, width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: 18),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text('ENVIAR PROVA DIGITAL', 
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                                overflow: TextOverflow.fade,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PASSO 2: Assinatura Gigante em (Landscape)
  // =========================================================================
  Widget _buildPasso2(ThemeData theme, Color textColor, Color canvasBg) {
    // Como estamos na horizontal, precisamos forçar altura para o Canvas
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.draw, color: Color(0xFF00C853), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'ASSINATURA DE ${_nameController.text.toUpperCase()}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: textColor.withValues(alpha: 0.5)),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // ── Canvas de Assinatura Isolado ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          height: screenHeight * 0.45, // Usa 45% do viewport landscape
          decoration: BoxDecoration(
            color: canvasBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onPanStart: (details) {
                setState(() => _currentStroke = [details.localPosition]);
              },
              onPanUpdate: (details) {
                setState(() => _currentStroke.add(details.localPosition));
              },
              onPanEnd: (_) {
                setState(() {
                  _strokes.add(List.from(_currentStroke));
                  _currentStroke = [];
                });
              },
              child: CustomPaint(
                painter: _SignaturePainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                  strokeColor: theme.colorScheme.onSurface,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Botões Inferiores ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _hasSignature ? _clearCanvas : () {
                    setState(() => _step = 1);
                    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                  },
                  icon: Icon(_hasSignature ? Icons.refresh : Icons.arrow_back, size: 18),
                  label: Text(_hasSignature ? 'LIMPAR' : 'VOLTAR', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _hasSignature ? Colors.red : textColor,
                    side: BorderSide(color: _hasSignature ? Colors.red : theme.dividerColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _confirmSignature,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isUploading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 20),
                            SizedBox(width: 8),
                            Text('CONFIRMAR ENTREGA', style: TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Painter customizado para desenhar os traços da assinatura.
class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color strokeColor;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Traços finalizados
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }

    // Traço em andamento
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, paint);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      if (points.isNotEmpty) {
        canvas.drawCircle(points.first, 1.5, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      }
      return;
    }

    final path = ui.Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) => true;
}

/// Formatador Dinâmico Diferenciado para RG (9 chars) e CPF (11 chars)
class CpfRgInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Limpa o texto aceitando apenas números e 'x'/'X'
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9xX]'), '').toUpperCase();

    // 2. Trava o limite em 11 caracteres reais de dados
    if (cleanText.length > 11) {
      cleanText = cleanText.substring(0, 11);
    }

    String formatted = '';

    // 3. Lógica de RG Típico (Até 9 caracteres) format: XX.XXX.XXX-X
    if (cleanText.length <= 9) {
      for (int i = 0; i < cleanText.length; i++) {
        if (i == 2 || i == 5) formatted += '.';
        if (i == 8) formatted += '-';
        formatted += cleanText[i];
      }
    } 
    // 4. Lógica de CPF (10 a 11 caracteres) format: XXX.XXX.XXX-XX
    else {
      // Se for CPF, não há letra 'X', então fazemos um hard-clean de letras
      cleanText = cleanText.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanText.length > 11) cleanText = cleanText.substring(0, 11); // double check

      for (int i = 0; i < cleanText.length; i++) {
        if (i == 3 || i == 6) formatted += '.';
        if (i == 9) formatted += '-';
        formatted += cleanText[i];
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
