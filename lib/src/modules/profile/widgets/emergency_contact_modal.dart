import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:viper_delivery/src/modules/profile/controllers/profile_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

class EmergencyContactModal extends StatelessWidget {
  final ProfileController controller;

  const EmergencyContactModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.find<SettingsController>().isDarkTheme;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = const Color(0xFF00FF88);

    final maskFormatter = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BARRINHA DE ARRASTE
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.emergency_share_rounded, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contato de Emergência',
                            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Para quem devemos ligar em caso de SOS?',
                            style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFieldLabel('NOME DO CONTATO', textColor),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.emergencyNameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  decoration: _buildInputDecoration('Ex: Maria (Esposa)', isDark, textColor),
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('TELEFONE / WHATSAPP', textColor),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [maskFormatter],
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  decoration: _buildInputDecoration('(00) 00000-0000', isDark, textColor),
                ),
                const SizedBox(height: 32),
                Obx(() => ElevatedButton(
                  onPressed: controller.isSubmitting.value ? null : controller.salvarContatoEmergencia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: controller.isSubmitting.value
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('SALVAR CONTATO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color textColor) {
    return Text(
      label,
      style: TextStyle(
        color: textColor.withOpacity(0.3),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, bool isDark, Color textColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textColor.withOpacity(0.2), fontSize: 14),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
