import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/profile/controllers/profile_controller.dart';

class VehicleExchangeModal extends StatelessWidget {
  final ProfileController controller;

  const VehicleExchangeModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.find<SettingsController>().isDarkTheme;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = const Color(0xFF00FF88);

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
                      color: textColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.swap_calls_rounded, color: primaryColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solicitar Novo Veículo',
                            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Preencha os dados e realize a vistoria 360º',
                            style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFieldLabel('MODELO DO VEÍCULO', textColor),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.modeloController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: _buildInputDecoration('Ex: Honda CG 160 Fan', isDark, textColor),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('COR', textColor),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller.corController,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: _buildInputDecoration('Ex: Preto', isDark, textColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('PLACA', textColor),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller.placaController,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: _buildInputDecoration('Ex: ABC1D23', isDark, textColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFieldLabel('FOTOS DA VISTORIA (5 OBRIGATÓRIAS)', textColor),
                const SizedBox(height: 12),
                
                // Grid ou lista de fotos
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                  children: [
                    Obx(() => _buildPhotoSlot(
                          'CRLV',
                          controller.crlvFile.value,
                          'crlv',
                          Icons.file_present_rounded,
                          textColor,
                          isDark,
                        )),
                    Obx(() => _buildPhotoSlot(
                          'Frente',
                          controller.vehicleFrontFile.value,
                          'front',
                          Icons.directions_car_rounded,
                          textColor,
                          isDark,
                        )),
                    Obx(() => _buildPhotoSlot(
                          'Lado Dir.',
                          controller.vehicleRightFile.value,
                          'right',
                          Icons.arrow_forward_rounded,
                          textColor,
                          isDark,
                        )),
                    Obx(() => _buildPhotoSlot(
                          'Lado Esq.',
                          controller.vehicleLeftFile.value,
                          'left',
                          Icons.arrow_back_rounded,
                          textColor,
                          isDark,
                        )),
                    Obx(() => _buildPhotoSlot(
                          'Traseira',
                          controller.vehicleRearFile.value,
                          'rear',
                          Icons.backspace_rounded,
                          textColor,
                          isDark,
                        )),
                  ],
                ),
                const SizedBox(height: 32),
                Obx(() => ElevatedButton(
                  onPressed: controller.isSubmitting.value ? null : controller.enviarSolicitacaoVeiculo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: controller.isSubmitting.value
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('ENVIAR VISTORIA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
        color: textColor.withValues(alpha: 0.3),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, bool isDark, Color textColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.2), fontSize: 14),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildPhotoSlot(
    String label,
    dynamic file,
    String side,
    IconData icon,
    Color textColor,
    bool isDark,
  ) {
    final hasPhoto = file != null;

    return GestureDetector(
      onTap: () => controller.escolherFotoVistoria(side, side == 'crlv'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPhoto ? const Color(0xFF00FF88) : textColor.withValues(alpha: 0.1),
            width: hasPhoto ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!hasPhoto)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor.withValues(alpha: 0.3), size: 24),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            if (hasPhoto)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00FF88),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.black, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
