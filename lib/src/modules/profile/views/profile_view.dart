import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/profile/controllers/profile_controller.dart';
import 'package:viper_delivery/src/modules/profile/widgets/emergency_contact_modal.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:viper_delivery/src/core/services/haptic_service.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // Injeção do Controller
    final controller = Get.put(ProfileController());
    final isDark = Get.find<SettingsController>().isDarkTheme;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = const Color(0xFF00FF88);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('MEU PERFIL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF88)));
        }

        final profile = controller.driverProfile.value;
        final firstName = profile?.firstName ?? 'Motorista';
        final vehicle = (profile?.vehicles?.isNotEmpty == true) ? profile!.vehicles!.first.model : 'Viper Pilot';

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER (Profile Info)
              _buildHeader(profile, firstName, vehicle, textColor, primaryColor, isDark),
              
              const SizedBox(height: 32),

              // 2. VEÍCULO ATIVO
              _buildSectionTitle('VEÍCULO ATIVO', textColor),
              const SizedBox(height: 16),
              _buildActiveVehicleCard(vehicle, textColor, primaryColor, isDark, () => _showTrocaVeiculoModal(context, controller)),

              const SizedBox(height: 32),

              // 3. CONTATO DE EMERGÊNCIA
              _buildSectionTitle('CONTATO DE EMERGÊNCIA', textColor),
              const SizedBox(height: 16),
              Obx(() => _buildEmergencyContactCard(
                controller.emergencyName.value,
                controller.emergencyPhone.value,
                textColor,
                isDark,
                onEdit: () {
                  HapticService.vibrateViperPulse();
                  Get.bottomSheet(
                    EmergencyContactModal(controller: controller),
                    isScrollControlled: true,
                    ignoreSafeArea: false,
                  );
                },
                onPanic: () {
                  print('🚀 [SOS] Clicou onTap'); 
                  controller.dispararSosElite(); 
                },
              )),

              const SizedBox(height: 40),
              
              // 4. CONQUISTAS / TROFÉUS
              _buildSectionTitle('CONQUISTAS E TROFÉUS', textColor),
              const SizedBox(height: 16),
              _buildTrophiesRow(controller, isDark, textColor),
              
              const SizedBox(height: 40),
              
              // 3. GRÁFICO DE ESTRELAS
              _buildSectionTitle('RESUMO DE AVALIAÇÕES', textColor),
              const SizedBox(height: 24),
              _buildStarChart(controller, primaryColor, textColor, isDark),
              
              const SizedBox(height: 40),
              
              // 4. FEEDBACK LIST
              _buildSectionTitle('ÚLTIMOS COMENTÁRIOS', textColor),
              const SizedBox(height: 16),
              _buildReviewsList(controller, isDark, textColor),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        color: textColor.withOpacity(0.5),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildHeader(dynamic profile, String name, String? vehicle, Color textColor, Color primaryColor, bool isDark) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 54,
            backgroundColor: primaryColor,
            child: CircleAvatar(
              radius: 51,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
              backgroundImage: (profile?.avatarUrl != null) 
                  ? CachedNetworkImageProvider(profile.avatarUrl) 
                  : null,
              child: (profile?.avatarUrl == null)
                  ? Icon(Icons.person, size: 50, color: textColor.withOpacity(0.2))
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            vehicle ?? 'Viper Pilot',
            style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeaderStat('⭐ 4.98', 'NOTA GERAL', textColor, primaryColor),
              Container(width: 1, height: 30, color: textColor.withOpacity(0.1), margin: const EdgeInsets.symmetric(horizontal: 32)),
              _buildHeaderStat('1.250', 'CORRIDAS', textColor, primaryColor),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label, Color textColor, Color primaryColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTrophiesRow(ProfileController controller, bool isDark, Color textColor) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: controller.trophies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final trophy = controller.trophies[index];
          return Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(trophy.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                Text(
                  trophy.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor, fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStarChart(ProfileController controller, Color primaryColor, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        children: List.generate(5, (index) {
          final star = 5 - index;
          final pct = controller.getStarPercentage(star);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 25,
                  child: Text('$star', style: TextStyle(color: textColor.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                Icon(Icons.star_rounded, color: primaryColor.withOpacity(0.3), size: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor.withOpacity(0.8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 35,
                  child: Text(
                    '${(pct * 100).toInt()}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveVehicleCard(String? vehicle, Color textColor, Color primaryColor, bool isDark, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.two_wheeler_rounded, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle ?? 'Nenhum Veículo Ativo', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Status: Validado', style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text('TROCAR', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showTrocaVeiculoModal(BuildContext context, ProfileController controller) {
    HapticService.vibrateViperPulse();
    final isDark = Get.find<SettingsController>().isDarkTheme;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = const Color(0xFF00FF88);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: textColor.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 24),
              Text('Trocar Veículo', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900)),
              Text('Informe os novos dados para análise.', style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)),
              const SizedBox(height: 32),
              
              _buildModalTextField('Modelo do Veículo', controller.modeloController, isDark, textColor),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildModalTextField('Cor', controller.corController, isDark, textColor)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildModalTextField('Placa', controller.placaController, isDark, textColor)),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionLabel('DOCUMENTO (CRLV)', textColor),
              const SizedBox(height: 12),
              Obx(() => _buildInspectionSlot(
                label: 'Foto do CRLV',
                icon: Icons.assignment_rounded,
                isFilled: controller.crlvFile.value != null,
                onTap: () => controller.escolherFotoVistoria('crlv', true),
                primaryColor: primaryColor,
                textColor: textColor,
                isDark: isDark,
              )),
              
              const SizedBox(height: 32),
              _buildSectionLabel('VISTORIA DO VEÍCULO', textColor),
              const SizedBox(height: 12),
              
              // Grid de Vistoria (4 Fotos)
              Column(
                children: [
                   Row(
                    children: [
                      Expanded(
                        child: Obx(() => _buildInspectionSlot(
                          label: 'Frente',
                          icon: Icons.front_loader,
                          isFilled: controller.vehicleFrontFile.value != null,
                          onTap: () => controller.escolherFotoVistoria('front', false),
                          primaryColor: primaryColor,
                          textColor: textColor,
                          isDark: isDark,
                        )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(() => _buildInspectionSlot(
                          label: 'Traseira',
                          icon: Icons.back_hand,
                          isFilled: controller.vehicleRearFile.value != null,
                          onTap: () => controller.escolherFotoVistoria('rear', false),
                          primaryColor: primaryColor,
                          textColor: textColor,
                          isDark: isDark,
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() => _buildInspectionSlot(
                          label: 'Lado Direito',
                          icon: Icons.arrow_forward_rounded,
                          isFilled: controller.vehicleRightFile.value != null,
                          onTap: () => controller.escolherFotoVistoria('right', false),
                          primaryColor: primaryColor,
                          textColor: textColor,
                          isDark: isDark,
                        )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(() => _buildInspectionSlot(
                          label: 'Lado Esquerdo',
                          icon: Icons.arrow_back_rounded,
                          isFilled: controller.vehicleLeftFile.value != null,
                          onTap: () => controller.escolherFotoVistoria('left', false),
                          primaryColor: primaryColor,
                          textColor: textColor,
                          isDark: isDark,
                        )),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
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
                    : const Text('ENVIAR PARA ANÁLISE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSectionLabel(String label, Color textColor) {
    return Text(
      label,
      style: TextStyle(
        color: textColor.withOpacity(0.4),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildInspectionSlot({
    required String label,
    required IconData icon,
    required bool isFilled,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color textColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFilled ? primaryColor : (isDark ? Colors.white12 : Colors.black12),
            width: isFilled ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFilled ? Icons.check_circle_rounded : icon,
              color: isFilled ? primaryColor : textColor.withOpacity(0.2),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isFilled ? primaryColor : textColor.withOpacity(0.5),
                fontSize: 11,
                fontWeight: isFilled ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalTextField(String label, TextEditingController controller, bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label, textColor),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyContactCard(String name, String phone, Color textColor, bool isDark, {required VoidCallback onEdit, required VoidCallback onPanic}) {
    bool hasContact = name.isNotEmpty && phone.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPanic,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.emergency_rounded, color: Colors.red, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPanic,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasContact ? name : 'Não Cadastrado',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    hasContact ? phone : 'Toque em configurar para ativar o SOS',
                    style: TextStyle(
                      color: hasContact ? textColor.withOpacity(0.5) : Colors.red.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: hasContact ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Text(
              hasContact ? 'EDITAR' : 'CONFIGURAR',
              style: const TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(ProfileController controller, bool isDark, Color textColor) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final review = controller.reviews[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        child: Icon(Icons.person, size: 14, color: textColor.withOpacity(0.2)),
                      ),
                      const SizedBox(width: 8),
                      // REGRA DE SEGURANÇA: Nome sempre Anônimo
                      Text('Anônimo', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  Text(review.date, style: TextStyle(color: textColor.withOpacity(0.3), fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (starIdx) {
                  return Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: starIdx < review.rating.floor() ? const Color(0xFF00FF88) : textColor.withOpacity(0.1),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text(
                review.comment,
                style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13, height: 1.4, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }
}
