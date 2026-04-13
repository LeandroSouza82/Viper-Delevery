import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:validatorless/validatorless.dart';
import 'package:viper_delivery/src/modules/onboarding/services/upload_service.dart';

class VehicleInspectionView extends StatefulWidget {
  const VehicleInspectionView({super.key});

  @override
  State<VehicleInspectionView> createState() => _VehicleInspectionViewState();
}

class _VehicleInspectionViewState extends State<VehicleInspectionView> {
  final _modelController = TextEditingController();
  final _uploadService = UploadService();
  final _picker = ImagePicker();
  
  String? _frontUrl;
  String? _backUrl;
  String? _leftUrl;
  String? _rightUrl;
  
  File? _frontFile;
  File? _backFile;
  File? _leftFile;
  File? _rightFile;
  
  String? _selectedColor;
  
  bool _isUploading = false;

  bool get _isComplete =>
      _modelController.text.isNotEmpty &&
      _selectedColor != null &&
      _frontUrl != null &&
      _backUrl != null &&
      _leftUrl != null &&
      _rightUrl != null;

  Future<void> _pickAndUpload(String angle) async {
    final pickedFile = await showModalBottomSheet<XFile>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar Foto'),
              onTap: () async {
                final file = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                  maxWidth: 1280,
                  maxHeight: 1280,
                );
                if (mounted) Navigator.pop(context, file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da Galeria'),
              onTap: () async {
                final file = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                  maxWidth: 1280,
                  maxHeight: 1280,
                );
                if (mounted) Navigator.pop(context, file);
              },
            ),
          ],
        ),
      ),
    );

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return;

        final url = await _uploadService.uploadVehiclePhoto(
          userId: user.id,
          angle: angle,
          file: File(pickedFile.path),
        );

        setState(() {
          final file = File(pickedFile.path);
          switch (angle) {
            case 'front': 
              _frontFile = file;
              _frontUrl = url; 
              break;
            case 'back': 
              _backFile = file;
              _backUrl = url; 
              break;
            case 'left': 
              _leftFile = file;
              _leftUrl = url; 
              break;
            case 'right': 
              _rightFile = file;
              _rightUrl = url; 
              break;
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao enviar foto: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildPhotoSlot(String label, File? localFile, String angle, IconData guideIcon) {
    return GestureDetector(
      onTap: _isUploading ? null : () => _pickAndUpload(angle),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: localFile != null ? Colors.blue.shade700 : Colors.grey.shade300, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (localFile == null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(guideIcon, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  localFile,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.error_outline, color: Colors.red),
                  ),
                ),
              ),
            if (localFile != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vistoria 360º')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Vistoria do Veículo',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Precisamos de 4 fotos do seu veículo para garantir a segurança.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Modelo do Veículo',
                        hintText: 'Ex: Honda CG 160 Fan',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedColor,
                      decoration: const InputDecoration(
                        labelText: 'Cor do Veículo',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Branco', 'Preto', 'Prata', 'Cinza', 'Vermelho', 'Azul', 'Amarelo', 'Verde', 'Outro'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedColor = newValue;
                        });
                      },
                      validator: Validatorless.required('A cor é obrigatória'),
                    ),
                    const SizedBox(height: 32),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                      children: [
                        _buildPhotoSlot('Frente', _frontFile, 'front', Icons.directions_car),
                        _buildPhotoSlot('Traseira', _backFile, 'back', Icons.back_hand),
                        _buildPhotoSlot('Lado Esquerdo', _leftFile, 'left', Icons.arrow_back),
                        _buildPhotoSlot('Lado Direito', _rightFile, 'right', Icons.arrow_forward),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: (_isComplete && !_isUploading)
                    ? () {
                        Navigator.pop(context, {
                          'model': _modelController.text,
                          'color': _selectedColor,
                          'front': _frontUrl,
                          'back': _backUrl,
                          'left': _leftUrl,
                          'right': _rightUrl,
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Finalizar Vistoria'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
