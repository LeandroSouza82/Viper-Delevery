import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/modules/ride/controllers/ride_state_machine.dart';

class FailureModal extends StatefulWidget {
  final String rideId;
  const FailureModal({super.key, required this.rideId});

  /// Exibe o Modal Centralizado de Falha e retorna o motivo reportado.
  static Future<void> show(BuildContext context, {required String rideId}) {
    return Get.dialog(
      FailureModal(rideId: rideId),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }

  @override
  State<FailureModal> createState() => _FailureModalState();
}

class _FailureModalState extends State<FailureModal> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedReason;
  File? _photoFile;
  bool _isLoading = false;
  final TextEditingController _obsController = TextEditingController();

  final List<String> _reasons = [
    'Cliente Ausente',
    'Endereço Não Encontrado',
    'Pacote Avariado',
    'Área de Risco',
    'Outros',
  ];

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 30, // Compressão exigida
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (photo != null) {
      setState(() {
        _photoFile = File(photo.path);
      });
    }
  }

  Future<void> _reportFailure() async {
    if (_selectedReason == null) {
      Get.snackbar('Atenção', 'Selecione um motivo.', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (_photoFile == null) {
      Get.snackbar('Foto Obrigatória', 'Tire uma foto do local/problema.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload para o Storage
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_falha.jpg';
      
      await _supabase.storage.from('driver_documents').upload(
        fileName,
        _photoFile!,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      ).timeout(const Duration(seconds: 15));

      final String publicUrl = _supabase.storage.from('driver_documents').getPublicUrl(fileName);

      // 2. Update na tabela rides
      await _supabase.from('rides').update({
        'failure_reason': _selectedReason,
        'failure_notes': _obsController.text,
        'failure_photo': publicUrl,
        'status': 'falhou',
      }).eq('id', widget.rideId);

      // 3. ATUALIZAÇÃO REATIVA (GetX): Remove o card da tela instantaneamente
      final rideSM = Get.find<RideStateMachine>();
      rideSM.removerCorridaDaTela(widget.rideId);

      Get.back(); // Fecha o modal
      Get.snackbar(
        'Falha registrada', 
        'A tentativa de entrega foi reportada com sucesso.',
        backgroundColor: Colors.orange[800],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      print('>>> ERRO AO REPORTAR FALHA: $e');
      Get.snackbar('Erro no Envio', 'Tivemos um problema com a rede. Tente de novo.', 
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent, width: 2),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 28),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Informar Problema na Entrega',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.redAccent),
                ),
                const SizedBox(height: 24),

                // Dropdown
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Motivo da Falha',
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: textColor.withOpacity(0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                  ),
                  dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  style: TextStyle(color: textColor, fontSize: 15),
                  value: _selectedReason,
                  items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => _selectedReason = val),
                ),
                const SizedBox(height: 16),

                // Observação
                TextField(
                  controller: _obsController,
                  maxLines: 2,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Digite detalhes extras...',
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: textColor.withOpacity(0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 20),

                // Seção de Foto
                if (_photoFile != null)
                  Container(
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: FileImage(_photoFile!), fit: BoxFit.cover),
                    ),
                  ),

                OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_photoFile == null ? 'Tirar Foto do Local (Obrigatório)' : 'Alterar Foto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão Enviar
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _reportFailure,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Reportar Falha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
