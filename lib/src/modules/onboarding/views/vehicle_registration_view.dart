import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:validatorless/validatorless.dart';
import 'package:viper_delivery/src/modules/onboarding/controllers/vehicle_controller.dart';
import 'package:viper_delivery/src/modules/onboarding/views/pending_approval_view.dart';
import 'package:viper_delivery/src/modules/onboarding/views/vehicle_inspection_view.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleRegistrationView extends StatefulWidget {
  const VehicleRegistrationView({super.key});

  @override
  State<VehicleRegistrationView> createState() => _VehicleRegistrationViewState();
}

class _VehicleRegistrationViewState extends State<VehicleRegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _vehicleController = VehicleController();
  final _picker = ImagePicker();

  String _selectedVehicleType = 'Moto';

  Future<void> _pickAndUpload(String type) async {
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
                if (!mounted) return;
                Navigator.pop(context, file);
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
                if (!mounted) return;
                Navigator.pop(context, file);
              },
            ),
          ],
        ),
      ),
    );

    if (pickedFile != null) {
      try {
        await _vehicleController.uploadDocument(type, File(pickedFile.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento enviado com sucesso!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao enviar documento: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_vehicleController.cnhFrontUrl == null ||
          _vehicleController.criminalRecordUrl == null ||
          _vehicleController.addressProofUrl == null ||
          _vehicleController.crlvUrl == null ||
          !_vehicleController.isInspectionComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, envie todos os documentos e complete a vistoria.')),
        );
        return;
      }

      try {
        await _vehicleController.submitVehicleData(
          vehicleType: _selectedVehicleType,
          plate: _plateController.text,
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PendingApprovalView()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${_vehicleController.errorMessage}')),
          );
        }
      }
    }
  }

  Widget _buildDocCard({
    required String title,
    required String? url,
    required String type,
    required IconData icon,
  }) {
    final bool isDone = url != null;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDone ? Colors.blue.shade700 : Colors.grey.shade300, width: 1.5),
      ),
      child: ListTile(
        onTap: () => _pickAndUpload(type),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDone ? Colors.blue.shade50 : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isDone ? Colors.blue.shade700 : Colors.grey.shade500),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(isDone ? 'Documento enviado' : 'Toque para enviar agora',
            style: TextStyle(color: isDone ? Colors.green : Colors.grey, fontSize: 12)),
        trailing: isDone
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Cadastro de Veículo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ListenableBuilder(
              listenable: _vehicleController,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Segurança e Veículo',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Envie seus documentos para aprovação do cadastro',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVehicleType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Veículo',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Moto', 'Carro'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          if (newValue != null) _selectedVehicleType = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _plateController,
                      decoration: const InputDecoration(
                        labelText: 'Placa do Veículo',
                        border: OutlineInputBorder(),
                        hintText: 'ABC1D23',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: Validatorless.multiple([
                        Validatorless.required('A placa é obrigatória'),
                        Validatorless.min(7, 'Placa inválida'),
                      ]),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Documentos e Vistoria',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildDocCard(
                        title: 'Foto da CNH (Frente)',
                        url: _vehicleController.cnhFrontUrl,
                        type: 'cnh',
                        icon: Icons.contact_page),
                    _buildDocCard(
                        title: 'Antecedentes Criminais',
                        url: _vehicleController.criminalRecordUrl,
                        type: 'criminal',
                        icon: Icons.security),
                    if (_vehicleController.criminalRecordUrl == null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb, size: 20, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dica: Emita sua certidão no site da Polícia Civil de SC. Baixe o PDF e envie o arquivo ou print.',
                                    style: TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () async {
                                      final url = Uri.parse('https://www.pc.sc.gov.br/');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          'Abrir site oficial',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.open_in_new, size: 14, color: Colors.blue.shade700),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildDocCard(
                        title: 'Comprovante de Endereço',
                        url: _vehicleController.addressProofUrl,
                        type: 'address',
                        icon: Icons.home),
                    _buildDocCard(
                        title: 'Documento do Veículo (CRLV)',
                        url: _vehicleController.crlvUrl,
                        type: 'crlv',
                        icon: Icons.file_present),
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: _vehicleController.isInspectionComplete ? Colors.blue.shade700 : Colors.grey.shade300,
                            width: 1.5),
                      ),
                      child: ListTile(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VehicleInspectionView()),
                          );
                          if (result != null) {
                            _vehicleController.setVehicleInspectionData(
                              model: result['model'],
                              color: result['color'],
                              frontUrl: result['front'],
                              backUrl: result['back'],
                              leftUrl: result['left'],
                              rightUrl: result['right'],
                            );
                          }
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _vehicleController.isInspectionComplete ? Colors.blue.shade50 : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt,
                              color: _vehicleController.isInspectionComplete ? Colors.blue.shade700 : Colors.grey.shade500),
                        ),
                        title: const Text('Vistoria do Veículo (360º)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                            _vehicleController.isInspectionComplete
                                ? 'Vistoria: ${_vehicleController.vehicleModel} (${_vehicleController.vehicleColor})'
                                : 'Toque para iniciar a vistoria',
                            style: TextStyle(
                                color: _vehicleController.isInspectionComplete ? Colors.green : Colors.grey, fontSize: 12)),
                        trailing: _vehicleController.isInspectionComplete
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: (_vehicleController.isLoading) ? null : _submit,
                      child: _vehicleController.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Enviar para Análise',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      ),
    );
  }
}
