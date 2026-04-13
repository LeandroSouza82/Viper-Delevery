import 'package:flutter/material.dart';
import 'package:validatorless/validatorless.dart';
import 'package:viper_delivery/src/modules/onboarding/controllers/vehicle_controller.dart';
import 'package:viper_delivery/src/modules/onboarding/views/pending_approval_view.dart';

class VehicleRegistrationView extends StatefulWidget {
  const VehicleRegistrationView({super.key});

  @override
  State<VehicleRegistrationView> createState() => _VehicleRegistrationViewState();
}

class _VehicleRegistrationViewState extends State<VehicleRegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _vehicleController = VehicleController();

  String _selectedVehicleType = 'Moto';

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_vehicleController.documentPhoto == null || _vehicleController.vehiclePhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, adicione ambas as fotos.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de VeÃ­culo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Complete seu cadastro enviando os dados do veÃ­culo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de VeÃ­culo',
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
                      if (newValue != null) {
                        _selectedVehicleType = newValue;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plateController,
                  decoration: const InputDecoration(
                    labelText: 'Placa',
                    border: OutlineInputBorder(),
                  ),
                  validator: Validatorless.multiple([
                    Validatorless.required('A placa Ã© obrigatÃ³ria'),
                    Validatorless.min(7, 'Placa invÃ¡lida'),
                  ]),
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _vehicleController,
                  builder: (context, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _vehicleController.pickDocumentPhoto,
                          icon: Icon(
                            _vehicleController.documentPhoto != null
                                ? Icons.check_circle
                                : Icons.camera_alt,
                            color: _vehicleController.documentPhoto != null
                                ? Colors.green
                                : null,
                          ),
                          label: const Text('Adicionar Foto do Documento'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _vehicleController.pickVehiclePhoto,
                          icon: Icon(
                            _vehicleController.vehiclePhoto != null
                                ? Icons.check_circle
                                : Icons.camera_alt,
                            color: _vehicleController.vehiclePhoto != null
                                ? Colors.green
                                : null,
                          ),
                          label: const Text('Adicionar Foto do VeÃ­culo'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _vehicleController.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _vehicleController.isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Enviar para AprovaÃ§Ã£o', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
