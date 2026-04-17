import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class DeliveryProofStep extends StatefulWidget {
  final Function(String) onNameChanged;
  final Function(String) onCpfChanged;
  final Function(File?) onPhotoChanged;
  final bool isDark;

  const DeliveryProofStep({
    super.key,
    required this.onNameChanged,
    required this.onCpfChanged,
    required this.onPhotoChanged,
    required this.isDark,
  });

  @override
  State<DeliveryProofStep> createState() => _DeliveryProofStepState();
}

class _DeliveryProofStepState extends State<DeliveryProofStep> {
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  
  File? _photo;
  final _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (image != null) {
      final file = File(image.path);
      setState(() => _photo = file);
      widget.onPhotoChanged(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'IDENTIFICAÇÃO DO RECEBEDOR',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueAccent),
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _nameController,
          label: 'Nome de quem recebeu',
          icon: Icons.person_outline,
          onChanged: widget.onNameChanged,
        ),
        const SizedBox(height: 12),
        _buildField(
          controller: _cpfController,
          label: 'CPF do recebedor',
          icon: Icons.badge_outlined,
          formatters: [_cpfFormatter],
          keyboardType: TextInputType.number,
          onChanged: (val) => widget.onCpfChanged(_cpfFormatter.getUnmaskedText()),
        ),
        const SizedBox(height: 20),
        const Text(
          'PROVA FÍSICA',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueAccent),
        ),
        const SizedBox(height: 12),
        _buildPhotoSelector(),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    List<MaskTextInputFormatter>? formatters,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      inputFormatters: formatters,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(color: widget.isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
        filled: true,
        fillColor: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPhotoSelector() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _photo != null ? Colors.green : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: _photo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(_photo!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.camera_alt_outlined, color: Colors.blueAccent.withOpacity(0.8), size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'FOTOGRAFAR PACOTE ENTREGUE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ],
              ),
      ),
    );
  }
}
