import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:validatorless/validatorless.dart';
import 'package:viper_delivery/src/modules/onboarding/services/upload_service.dart';
import 'package:viper_delivery/src/modules/auth/controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _authController = AuthController();
  final _picker = ImagePicker();
  File? _photo;
  String? _registeredUserId; // Persistência para retry de foto
  bool _isUploading = false;

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

  Future<void> _pickSelfie() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _photo = File(pickedFile.path); // Corrigido de _selfieFile para _photo conforme o resto do arquivo
        });
      }
    } catch (e) {
      _showCustomSnackBar('Erro ao acessar a câmera: $e', isError: true);
    }
  }

  void _register() async {
    // Se já criou o usuário mas falhou na foto, vai direto pro upload
    if (_registeredUserId != null) {
      await _uploadAndLinkPhoto(_registeredUserId!);
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (_photo == null) {
        _showCustomSnackBar('A foto de perfil é obrigatória!', isError: true);
        return;
      }
      if (!_isPasswordStrong) {
        _showCustomSnackBar('A senha não atende todos os requisitos de segurança.', isError: true);
        return;
      }
      
      setState(() => _isUploading = true);

      try {
        // 1. Criar Acesso Primeiro (SignUp)
        final String? userId = await _authController.signUp(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          cpf: _cpfMask.getUnmaskedText(),
          phone: _phoneMask.getUnmaskedText(),
          email: _emailController.text,
          password: _passwordController.text,
          city: _cityController.text,
          neighborhood: _neighborhoodController.text,
          state: _stateController.text,
          address: _addressController.text,
          cnhNumber: _cnhNumberController.text,
          cnhCategory: _selectedCnhCategory,
          pixKey: _pixKeyController.text,
          avatarUrl: null, // Será enviado no _uploadAndLinkPhoto
        );
        if (userId == null) {
          if (mounted) _showCustomSnackBar(_authController.errorMessage ?? 'Erro no cadastro.', isError: true);
          return;
        }

        setState(() => _registeredUserId = userId);
        
        // 2. Delay de Segurança (Session Warmup)
        await Future.delayed(const Duration(seconds: 1));

        // 3. Tentar Upload e Vínculo
        await _uploadAndLinkPhoto(userId);
        
      } catch (e) {
        if (mounted) {
          _showCustomSnackBar(
            _authController.errorMessage ?? 'Ocorreu um erro no cadastro. Tente novamente.',
            isError: true,
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _uploadAndLinkPhoto(String userId) async {
    // 2. Upload da Foto (Bucket driver_documents)
    // Silently attempt upload; if it fails, we still try to save the profile data
    final String? fotoUrl = await _authController.uploadProfileSelfie(userId, _photo!);
    
    if (fotoUrl == null) {
      debugPrint('[Warning] Selfie upload failed, proceeding with profile registration only.');
    }

    // 3. Sincronização Final do Perfil (Evita dados NULL)
    // Usamos o fotoUrl (que pode ser null se o upload falhou)
    final success = await _authController.finalizeDriverProfile(
      userId: userId,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      cpf: _cpfMask.getUnmaskedText(),
      phone: _phoneMask.getUnmaskedText(),
      city: _cityController.text,
      neighborhood: _neighborhoodController.text,
      state: _stateController.text,
      address: _addressController.text,
      cnhNumber: _cnhNumberController.text,
      cnhCategory: _selectedCnhCategory,
      pixKey: _pixKeyController.text,
      avatarUrl: fotoUrl, // Passamos o URL (ou null)
    );
    
    if (!success) {
      if (mounted) {
        // Se a sincronização do BANCO falhar (PGRST204 ou similar), aí sim mostramos erro
        _showRetryDialog(userId);
      }
      return;
    }

    // Notificação sutil se a foto faltou
    if (fotoUrl == null && mounted) {
      _showCustomSnackBar(
        'Conta criada! Sua foto não pôde ser enviada agora, mas você já pode acessar o app.',
        isError: false,
      );
    }

    if (mounted) {
      _showCustomSnackBar(
        'Cadastro realizado com sucesso! Verifique seu e-mail para ativar sua conta.',
        isError: false,
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _showRetryDialog(String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ops! Quase lá...'),
        content: const Text(
          'Sua conta foi criada no sistema, mas não conseguimos processar sua foto de perfil.\n\nPor favor, tente enviar novamente para completar seu cadastro.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadAndLinkPhoto(userId);
            },
            child: const Text('Tentar Enviar Novamente', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: const Text(
          'Acesso à Câmera Negado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Para capturar sua selfie de segurança, precisamos que você autorize o uso da câmera nas configurações do seu celular.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ABRIR CONFIGURAÇÕES', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue.shade700, width: 2),
                        ),
                        child: CircleAvatar(
                          backgroundImage: _photo != null ? FileImage(_photo!) : null,
                          child: _photo == null
                              ? Icon(Icons.person, size: 60, color: Colors.blue.shade100)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: InkWell(
                          onTap: _pickSelfie,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue.shade700,
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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
                  'Foto de Perfil (Obrigatória)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final status = await Permission.camera.request();
                      
                      if (status.isPermanentlyDenied) {
                        if (mounted) {
                          _showPermissionSettingsDialog();
                        }
                        return;
                      }

                      if (status.isDenied) {
                        if (mounted) {
                          _showCustomSnackBar('Precisamos da sua foto para validar seu perfil e liberar as entregas', isError: true);
                        }
                        return;
                      }

                      final XFile? pickedFile = await _picker.pickImage(
                        source: ImageSource.camera,
                        preferredCameraDevice: CameraDevice.front,
                        imageQuality: 20,
                        maxWidth: 1280,
                        maxHeight: 1280,
                      );
                      if (pickedFile != null) {
                        setState(() => _photo = File(pickedFile.path));
                      }
                    },
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _photo != null ? const Color(0xFF00FF88) : Colors.black,
                          width: 2.0,
                        ),
                      ),
                      child: _photo != null
                          ? ClipOval(
                              child: Image.file(
                                _photo!,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_rounded, size: 40, color: Colors.black54),
                                SizedBox(height: 8),
                                Text('Tirar Selfie', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                              ],
                            ),
                    ),
                  ),
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
                  value: _selectedCnhCategory,
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
                    final isLoading = _authController.isLoading || _isUploading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _register,
                      child: isLoading
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
