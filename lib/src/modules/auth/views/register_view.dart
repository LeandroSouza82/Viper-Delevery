import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:validatorless/validatorless.dart';
import 'package:viper_delivery/src/modules/auth/controllers/auth_controller.dart';
import 'package:viper_delivery/src/modules/onboarding/views/vehicle_registration_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _authController = AuthController();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _stateController = TextEditingController();

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  void _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await _authController.signUp(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          cpf: _cpfMask.getUnmaskedText(),
          phone: _phoneMask.getUnmaskedText(),
          email: _emailController.text,
          password: _passwordController.text,
          city: _cityController.text,
          neighborhood: _neighborhoodController.text,
          state: _stateController.text,
        );
        if (mounted) {
          _showCustomSnackBar(
            'Cadastro realizado! Verifique seu e-mail e clique no link para ativar sua conta',
            isError: false,
          );
          Navigator.pop(context); // Volta para o login
        }
      } catch (e) {
        if (mounted) {
          _showCustomSnackBar(
            _authController.errorMessage ?? 'Erro ao registrar.',
            isError: true,
          );
        }
      }
    }
  }

  void _showCustomSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isError ? Colors.redAccent : Colors.blueAccent, width: 2),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
                  validator: Validatorless.required('Nome obrigatÃ³rio'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Sobrenome', border: OutlineInputBorder()),
                  validator: Validatorless.required('Sobrenome obrigatÃ³rio'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cpfController,
                  inputFormatters: [_cpfMask],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CPF', border: OutlineInputBorder()),
                  validator: Validatorless.multiple([
                    Validatorless.required('CPF obrigatÃ³rio'),
                    Validatorless.min(14, 'CPF invÃ¡lido'),
                  ]),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  inputFormatters: [_phoneMask],
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder()),
                  validator: Validatorless.multiple([
                    Validatorless.required('Telefone obrigatÃ³rio'),
                    Validatorless.min(14, 'Telefone invÃ¡lido'),
                  ]),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                  validator: Validatorless.multiple([
                    Validatorless.required('E-mail obrigatÃ³rio'),
                    Validatorless.email('E-mail invÃ¡lido'),
                  ]),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                  validator: Validatorless.multiple([
                    Validatorless.required('Senha obrigatÃ³ria'),
                    Validatorless.min(6, 'Min 6 caracteres'),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()),
                        validator: Validatorless.required('ObrigatÃ³rio'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                        validator: Validatorless.required('ObrigatÃ³rio'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _neighborhoodController,
                  decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder()),
                  validator: Validatorless.required('Bairro obrigatÃ³rio'),
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _authController,
                  builder: (context, child) {
                    return ElevatedButton(
                      onPressed: _authController.isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _authController.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Cadastrar', style: TextStyle(fontSize: 18)),
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
