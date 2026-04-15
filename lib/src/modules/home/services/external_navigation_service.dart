import 'package:url_launcher/url_launcher.dart';

class ExternalNavigationService {
  /// Abre a rota no Waze ou Google Maps (Fallback)
  static Future<void> openRoute(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final wazeUri = Uri.parse('waze://?q=$encodedAddress');
    final googleMapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    try {
      // Tenta abrir o Waze primeiro
      if (await canLaunchUrl(wazeUri)) {
        await launchUrl(wazeUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback para Google Maps se o Waze não estiver disponível
        if (await canLaunchUrl(googleMapsUri)) {
          await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Não foi possível encontrar um aplicativo de navegação.';
        }
      }
    } catch (e) {
      // Erro silencioso ou log
      print('Erro ao abrir navegação: $e');
    }
  }
}
