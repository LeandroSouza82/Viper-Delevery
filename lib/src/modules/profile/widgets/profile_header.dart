import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String vehicle;
  final String? avatarUrl;

  const ProfileHeader({
    super.key, 
    required this.name, 
    required this.vehicle,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00FF88);

    return Column(
      children: [
        const SizedBox(height: 20),
        // Foto Quadrada Estilizada (Viper Elite Style)
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28), // Bordas arredondadas agressivas
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
            border: Border.all(
              color: primaryColor.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => Icon(Icons.person, size: 60, color: primaryColor),
                  )
                : Icon(Icons.person, size: 60, color: primaryColor),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          name.toUpperCase(), 
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        // A Crosser Verde em destaque (Status do Veículo)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: primaryColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_bike_rounded, color: primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(
                vehicle,
                style: TextStyle(
                  color: primaryColor, 
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
