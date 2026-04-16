import 'package:flutter/material.dart';
import 'package:validatorless/validatorless.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';

class EditPixModal extends StatefulWidget {
  final ViperMenuController menuController;
  final String initialValue;

  const EditPixModal({
    super.key,
    required this.menuController,
    required this.initialValue,
  });

  @override
  State<EditPixModal> createState() => _EditPixModalState();
}

class _EditPixModalState extends State<EditPixModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pixController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pixController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _pixController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await widget.menuController.updatePixKey(_pixController.text);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Editar Chave Pix',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Insira sua chave Pix (CPF, E-mail, Telefone ou Aleatória) para receber pagamentos nas corridas.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _pixController,
              decoration: InputDecoration(
                labelText: 'Chave Pix',
                hintText: 'Ex: 123.456.789-00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
              validator: Validatorless.required('Chave Pix é obrigatória'),
              autofocus: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'SALVAR CHAVE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
