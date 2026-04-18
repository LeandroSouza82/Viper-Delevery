import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/profile/controllers/profile_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
              
              const SizedBox(height: 40),
              
              // 2. CONQUISTAS / TROFÉUS
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
                  Text(review.customerName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(review.date, style: TextStyle(color: textColor.withOpacity(0.3), fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
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
