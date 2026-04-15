import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre GPS externo: tenta Waze (`waze://?q=`), depois Google Maps na web.
Future<void> openExternalNavigation(String endereco) async {
  final query = Uri.encodeComponent(endereco.trim());
  if (query.isEmpty) return;

  final wazeUri = Uri.parse('waze://?q=$query');
  try {
    final ok = await launchUrl(
      wazeUri,
      mode: LaunchMode.externalApplication,
    );
    if (ok) return;
  } on Exception catch (e) {
    debugPrint('Waze não abriu: $e');
  }

  final mapsUri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );
  try {
    await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
  } on Exception catch (e) {
    debugPrint('Google Maps não abriu: $e');
  }
}
