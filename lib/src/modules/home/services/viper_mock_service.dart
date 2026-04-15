import 'dart:math';

/// Tipos de parada na rota.
enum ViperTipoPedido {
  coleta,
  entrega,
  outros,
}

/// Pedido / parada exibida nos cards.
class ViperOrder {
  const ViperOrder({
    required this.id,
    required this.tipo,
    required this.cliente,
    required this.endereco,
    required this.observacao,
  });

  final String id;
  final ViperTipoPedido tipo;
  final String cliente;
  final String endereco;
  final String observacao;

  String get tipoLabel {
    switch (tipo) {
      case ViperTipoPedido.coleta:
        return 'COLETA';
      case ViperTipoPedido.entrega:
        return 'ENTREGA';
      case ViperTipoPedido.outros:
        return 'OUTROS';
    }
  }
}

/// Simulação de corridas: chamada única ou Super Rota.
abstract final class ViperMockService {
  static final Random _rng = Random();

  /// Endereços reais da Grande Florianópolis (logradouro + bairro + cidade).
  static const List<String> enderecosGrandeFloripa = [
    'Rua João Born, 245 — Centro — Biguaçu — SC',
    'Av. Lédio João Martins, 1250 — Kobrasol — São José — SC',
    'Rua Caetano Silveira, 340 — Passa Vinte — Palhoça — SC',
    'Av. Beira-Mar Norte, 2600 — Agronômica — Florianópolis — SC',
    'Rua Felipe Schmidt, 600 — Centro — Florianópolis — SC',
    'Av. Madre Benvenuta, 1307 — Santa Mônica — Florianópolis — SC',
    'Rua João Januário Ayres, 812 — Forquilhinha — São José — SC',
    'Rod. SC-407, 4500 — Areias — São José — SC',
    'Rua Alan Kardec, 180 — Centro — Biguaçu — SC',
    'Av. Hercílio Luz, 1100 — Centro — Florianópolis — SC',
  ];

  static const List<String> _nomesCliente = [
    'Maria Lopes',
    'Depósito Sul',
    'Farmácia Popular',
    'TechParts SC',
    'Padaria Real',
    'Clínica Vida',
    'Mercado Central',
    'João Entregas',
  ];

  static const List<String> _observacoes = [
    'Entregar para Maria na recepção.',
    'Deixar na guarita. Documento com porteiro.',
    'Bater interfone 702 — aguardar 2 min.',
    'Falar com o responsável na doca B.',
    'Não tocar campainha — enviar WhatsApp ao chegar.',
    'Fragil — manusear com cuidado.',
    'Retirar com RG na portaria.',
    'Entregar somente para titular do pedido.',
  ];

  static ViperTipoPedido _tipoColetaOuEntrega() =>
      _rng.nextBool() ? ViperTipoPedido.coleta : ViperTipoPedido.entrega;

  static String _novoId(String prefix, int i) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-$i';

  /// **Chamada única:** 1 card (somente entrega ou coleta).
  static List<ViperOrder> randomChamadaUnica() {
    final tipo = _tipoColetaOuEntrega();
    final end =
        enderecosGrandeFloripa[_rng.nextInt(enderecosGrandeFloripa.length)];
    return [
      ViperOrder(
        id: _novoId('cu', 0),
        tipo: tipo,
        cliente: _nomesCliente[_rng.nextInt(_nomesCliente.length)],
        endereco: end,
        observacao: _observacoes[_rng.nextInt(_observacoes.length)],
      ),
    ];
  }

  /// **Super rota:** 5 cards, apenas coleta e entrega mescladas.
  static List<ViperOrder> randomSuperRota() {
    return List<ViperOrder>.generate(5, (i) {
      final tipo = _tipoColetaOuEntrega();
      final end =
          enderecosGrandeFloripa[_rng.nextInt(enderecosGrandeFloripa.length)];
      return ViperOrder(
        id: _novoId('sr', i),
        tipo: tipo,
        cliente: _nomesCliente[_rng.nextInt(_nomesCliente.length)],
        endereco: end,
        observacao: _observacoes[_rng.nextInt(_observacoes.length)],
      );
    });
  }

  /// Escolhe aleatoriamente chamada única ou Super Rota.
  static List<ViperOrder> generateRandomRide() {
    return _rng.nextBool() ? randomChamadaUnica() : randomSuperRota();
  }
}
