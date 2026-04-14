import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:validatorless/validatorless.dart';
import 'package:viper_delivery/src/modules/auth/controllers/auth_controller.dart';

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
  final _addressController = TextEditingController();
  final _cnhNumberController = TextEditingController();
  final _pixKeyController = TextEditingController();

  String _selectedCnhCategory = 'A';

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasUppercase = false;
  bool _hasSpecialChar = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _updatePasswordChecklist(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    });
  }

  bool get _isPasswordStrong => _hasMinLength && _hasNumber && _hasUppercase && _hasSpecialChar;

  void _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_isPasswordStrong) {
        _showCustomSnackBar('A senha não atende todos os requisitos de segurança.', isError: true);
        return;
      }
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
          cnhNumber: _cnhNumberController.text,
          cnhCategory: _selectedCnhCategory,
          pixKey: _pixKeyController.text,
        );
        if (mounted) {
          _showCustomSnackBar(
            'Cadastro realizado! Verifique seu e-mail e clique no link para ativar sua conta.',
            isError: false,
          );
          Navigator.popUntil(context, (route) => route.isFirst);
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

  Widget _buildChecklistItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: isValid ? Colors.green : Colors.red.shade300,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            softWrap: true,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? Colors.green : Colors.red.shade300,
            ),
          ),
        ),
      ],
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
        appBar: AppBar(
        title: const Text('Cadastro do Motorista'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Dados Pessoais',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
                  validator: Validatorless.required('Nome obrigatório'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Sobrenome', border: OutlineInputBorder()),
                  validator: Validatorless.required('Sobrenome obrigatório'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cpfController,
                  inputFormatters: [_cpfMask],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CPF', border: OutlineInputBorder()),
                  validator: Validatorless.multiple([
                    Validatorless.required('CPF obrigatório'),
                    Validatorless.min(14, 'CPF inválido'),
                  ]),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  inputFormatters: [_phoneMask],
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder()),
                  validator: Validatorless.multiple([
                    Validatorless.required('Telefone obrigatório'),
                    Validatorless.min(14, 'Telefone inválido'),
                  ]),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Endereço',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Endereço Completo', border: OutlineInputBorder()),
                  validator: Validatorless.required('Endereço obrigatório'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()),
                        validator: Validatorless.required('Obrigatório'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(labelText: 'UF', border: OutlineInputBorder()),
                        textCapitalization: TextCapitalization.characters,
                        validator: Validatorless.required('Obrigatório'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _neighborhoodController,
                  decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder()),
                  validator: Validatorless.required('Bairro obrigatório'),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Habilitação e Financeiro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cnhNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Número da CNH', border: OutlineInputBorder()),
                  validator: Validatorless.required('CNH obrigatória'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCnhCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria da CNH',
                    border: OutlineInputBorder(),
                  ),
                  items: ['A', 'B', 'C', 'D', 'E', 'AB', 'AC', 'AD', 'AE'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedCnhCategory = newValue);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pixKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Chave Pix',
                    border: OutlineInputBorder(),
                    hintText: 'CPF, e-mail, telefone ou chave aleatória',
                  ),
                  validator: Validatorless.required('Chave Pix obrigatória'),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Acesso',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                  validator: Validatorless.multiple([
                    Validatorless.required('E-mail obrigatório'),
                    Validatorless.email('E-mail inválido'),
                  ]),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.blue[700],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  onChanged: _updatePasswordChecklist,
                  validator: Validatorless.required('Senha obrigatória'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.blue[700],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: Validatorless.multiple([
                    Validatorless.required('Confirmação obrigatória'),
                    Validatorless.compare(_passwordController, 'As senhas não coincidem'),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Requisitos da senha:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildChecklistItem('Mínimo 8 caracteres', _hasMinLength),
                      const SizedBox(height: 4),
                      _buildChecklistItem('Pelo menos 1 número', _hasNumber),
                      const SizedBox(height: 4),
                      _buildChecklistItem('Pelo menos 1 letra maiúscula', _hasUppercase),
                      const SizedBox(height: 4),
                      _buildChecklistItem('Pelo menos 1 caractere especial (!@#\$%)', _hasSpecialChar),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _authController,
                  builder: (context, child) {
                    return ElevatedButton(
                      onPressed: _authController.isLoading ? null : _register,
                      child: _authController.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Cadastrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
