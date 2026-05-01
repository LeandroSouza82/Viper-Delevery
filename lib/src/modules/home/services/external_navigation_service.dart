import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';

class ExternalNavigationService {
  /// Abre a navegação por coordenadas, respeitando a preferência do motorista.
  /// Lê [NavigationApp] do [SettingsController] (Google Maps ou Waze).
  /// Se o app preferido não estiver instalado, tenta o outro.
  /// Se nenhum estiver disponível, exibe alerta em [context].
  static Future<void> abrirNavegador({
    required double lat,
    required double lng,
    required BuildContext context,
    String? address,
  }) async {
    // [VUP CHECKLIST] Validação de Coordenadas (Trava 0,0)
    if (lat == 0.0 || lng == 0.0) {
      debugPrint('[ViperNav] Coordenadas inválidas (0,0). Tentando fallback por endereço...');
      if (address != null && address.isNotEmpty) {
        await openRoute(address);
        return;
      } else {
        if (context.mounted) {
          _showInvalidCoordsAlert(context);
        }
        return;
      }
    }

    final settings = SettingsController();
    final preferido = settings.navApp;

    // URIs para cada navegador
    final googleUri = Uri.parse(
      'google.navigation:q=$lat,$lng&mode=d',
    );
    final wazeUri = Uri.parse(
      'waze://?ll=$lat,$lng&navigate=yes',
    );

    // Fallback genérico (web browser)
    final fallbackUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    // Ordena tentativas: preferido primeiro, depois alternativo
    final List<({Uri uri, String nome})> tentativas;
    if (preferido == NavigationApp.waze) {
      tentativas = [
        (uri: wazeUri, nome: 'Waze'),
        (uri: googleUri, nome: 'Google Maps'),
      ];
    } else {
      tentativas = [
        (uri: googleUri, nome: 'Google Maps'),
        (uri: wazeUri, nome: 'Waze'),
      ];
    }

    try {
      for (final t in tentativas) {
        if (await canLaunchUrl(t.uri)) {
          await launchUrl(t.uri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // Nenhum app instalado — tenta fallback no browser
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        return;
      }

      // Sem navegador disponível
      if (context.mounted) {
        _showNoNavigatorAlert(context);
      }
    } catch (e) {
      debugPrint('[ViperNav] Erro ao abrir navegação: $e');
      if (context.mounted) {
        _showNoNavigatorAlert(context);
      }
    }
  }

  /// Método legado por endereço (mantido para compatibilidade com ViperOrderCard)
  static Future<void> openRoute(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final settings = SettingsController();
    final preferido = settings.navApp;

    final googleUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    );
    final wazeUri = Uri.parse('waze://?q=$encodedAddress');

    final List<Uri> tentativas;
    if (preferido == NavigationApp.waze) {
      tentativas = [wazeUri, googleUri];
    } else {
      tentativas = [googleUri, wazeUri];
    }

    try {
      for (final uri in tentativas) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
    } catch (e) {
      debugPrint('[ViperNav] Erro ao abrir rota por endereço: $e');
    }
  }

  static void _showInvalidCoordsAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gps_off, color: Colors.red),
            SizedBox(width: 10),
            Text('GPS Indisponível'),
          ],
        ),
        content: const Text(
          'Endereço sem coordenadas GPS válidas.\n'
          'Tente usar o endereço de texto para navegar ou aguarde a sincronização.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ENTENDI', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void _showNoNavigatorAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.navigation_outlined, color: Colors.orange),
            SizedBox(width: 10),
            Text('Navegação'),
          ],
        ),
        content: const Text(
          'Nenhum aplicativo de navegação encontrado.\n'
          'Instale o Google Maps ou Waze para usar esta função.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ENTENDI', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

