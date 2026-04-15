import 'dart:math';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:viper_delivery/src/modules/home/services/viper_routing_service.dart';

class ViperMockService {
  static final Random _random = Random();

  // Coordenadas simuladas para a Grande Florianópolis
  static const Map<String, List<double>> _coords = {
    'Rua João Born, Biguaçu': [-27.4930, -48.6586],
    'Av. Lédio João Martins, São José': [-27.5969, -48.6049],
    'Beira-Mar Norte, Florianópolis': [-27.5855, -48.5520],
    'Avenida Pagani, Palhoça': [-27.6534, -48.6756],
    'Rua Caetano Silveira, Palhoça': [-27.6445, -48.6677],
    'Rua Felipe Schmidt, Florianópolis': [-27.5948, -48.5569],
  };

  static const List<String> _realAddresses = [
    'Rua João Born, Biguaçu',
    'Av. Lédio João Martins, São José',
    'Beira-Mar Norte, Florianópolis',
    'Avenida Pagani, Palhoça',
    'Rua Caetano Silveira, Palhoça',
    'Rua Felipe Schmidt, Florianópolis',
  ];

  static const List<String> _clients = [
    'Madero Bugers',
    'Viper Sushi',
    'Pizza Express',
    'Açaí do Porto',
    'Burger King',
  ];

  /// Gera uma oferta baseada no motor definitivo de roteirização e Viper Math
  static ViperOffer generateOffer() {
    final isSuper = _random.nextBool();
    final qtdPedidos = isSuper ? _random.nextInt(3) + 3 : 1; 
    final mainType = ViperOrderType.values[_random.nextInt(ViperOrderType.values.length)];
    final client = _clients[_random.nextInt(_clients.length)];

    // 1. Simular Posição do Motorista (ex: Centro de Floripa)
    const driverLat = -27.5948;
    const driverLng = -48.5569;

    // 2. Definir Ponto de Coleta
    final pickupAddr = _realAddresses[_random.nextInt(_realAddresses.length)];
    final pCoords = _coords[pickupAddr]!;
    final pParts = pickupAddr.split(',');

    // 3. Gerar Pedidos (Entregas)
    final List<ViperOrder> rawOrders = [];
    for (int i = 0; i < qtdPedidos; i++) {
        String dropoffAddr;
        do {
          dropoffAddr = _realAddresses[_random.nextInt(_realAddresses.length)];
        } while (dropoffAddr == pickupAddr);

        final dParts = dropoffAddr.split(',');
        final dCoords = _coords[dropoffAddr]!;

        rawOrders.add(
          ViperOrder(
            id: 'order_${_random.nextInt(10000)}',
            cliente: client,
            enderecoColeta: pParts.first.trim(),
            bairroColeta: pParts.last.trim(),
            enderecoEntrega: dParts.first.trim(),
            bairroEntrega: dParts.last.trim(),
            tipo: mainType,
            valor: 0, // Será calculado após a roteirização
            lat: dCoords[0],
            lng: dCoords[1],
          ),
        );
    }

    // 4. Rodar Motor de Roteirização
    final routingResult = ViperRoutingService.optimize(
      driverLat: driverLat,
      driverLng: driverLng,
      pickupLat: pCoords[0],
      pickupLng: pCoords[1],
      orders: rawOrders,
    );

    // 5. Aplicar Viper Math (Precificação Definitiva)
    // Fator de R$ 0,90 a R$ 1,00 por KM total
    final valorPorKm = 0.90 + (_random.nextDouble() * 0.10);
    final valorTotal = routingResult.totalDistance * valorPorKm;
    final valorFracionado = valorTotal / qtdPedidos;

    // 6. Atualizar os pedidos roteirizados com o valor fracionado
    final List<ViperOrder> finalOrders = routingResult.optimizedOrders.map((o) {
      return ViperOrder(
        id: o.id,
        cliente: o.cliente,
        enderecoColeta: o.enderecoColeta,
        bairroColeta: o.bairroColeta,
        enderecoEntrega: o.enderecoEntrega,
        bairroEntrega: o.bairroEntrega,
        tipo: o.tipo,
        valor: valorFracionado,
        lat: o.lat,
        lng: o.lng,
      );
    }).toList();

    return ViperOffer(
      id: 'offer_${_random.nextInt(10000)}',
      orders: finalOrders,
      distanciaTotal: routingResult.totalDistance,
      distanciaDeslocamento: routingResult.distanceDriverToPickup,
      valorTotal: valorTotal,
      valorPorKm: valorPorKm,
      isSuper: isSuper,
      pickupNeighborhood: finalOrders.first.bairroColeta,
      pickupStreet: finalOrders.first.enderecoColeta,
      dropoffNeighborhood: finalOrders.last.bairroEntrega,
      dropoffStreet: finalOrders.last.enderecoEntrega,
    );
  }

  static List<ViperOrder> generateRandomRide() {
    return generateOffer().orders;
  }
}
