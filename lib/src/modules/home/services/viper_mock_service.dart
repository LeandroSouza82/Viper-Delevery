import 'dart:math';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:viper_delivery/src/modules/home/services/viper_routing_service.dart';
import 'package:geolocator/geolocator.dart';

class ViperMockService {
  static final Random _random = Random();

  // Coordenadas simuladas para a Grande Florianópolis
  // Coordenadas simuladas para Palhoça e região (Coerência Regional)
  // Coordenadas simuladas para a Grande Florianópolis (Corredor Logístico)
  static const Map<String, List<double>> _coords = {
    // PALHOÇA
    'Rua Amantino Francisco da Silva, 605, Caminho Novo, Palhoça, Santa Catarina': [-27.6530, -48.6786],
    'Avenida Atílio Pedro Pagani, 270, Pagani, Palhoça, Santa Catarina': [-27.6534, -48.6756],
    'Rua Vereador Jacob Knabben da Silva, 500, Centro, Palhoça, Santa Catarina': [-27.6445, -48.6677],
    
    // SÃO JOSÉ (Entregas Intermediárias)
    'Avenida Presidente Kennedy, 1500, Campinas, São José, Santa Catarina': [-27.5965, -48.6085],
    'Rua Adhemar da Silva, 600, Kobrasol, São José, Santa Catarina': [-27.5925, -48.6185],
    'Rua Juvêncio de Almeida, 120, Campinas, São José, Santa Catarina': [-27.5950, -48.6110],

    // FLORIANÓPOLIS (Destino Final)
    'Rua Felipe Schmidt, 153, Centro, Florianópolis, Santa Catarina': [-27.5960, -48.5520],
    'Avenida Jornalista Rubens de Arruda Ramos, 2000, Beira Mar Norte, Florianópolis, Santa Catarina': [-27.5850, -48.5530],
    'Praça Pereira Oliveira, 50, Centro, Florianópolis, Santa Catarina': [-27.5945, -48.5510],
  };

  static const List<String> _addrPalhoca = [
    'Rua Amantino Francisco da Silva, 605, Caminho Novo, Palhoça, Santa Catarina',
    'Avenida Atílio Pedro Pagani, 270, Pagani, Palhoça, Santa Catarina',
    'Rua Vereador Jacob Knabben da Silva, 500, Centro, Palhoça, Santa Catarina',
  ];

  static const List<String> _addrSaoJose = [
    'Avenida Presidente Kennedy, 1500, Campinas, São José, Santa Catarina',
    'Rua Adhemar da Silva, 600, Kobrasol, São José, Santa Catarina',
    'Rua Juvêncio de Almeida, 120, Campinas, São José, Santa Catarina',
  ];

  static const List<String> _addrFloripa = [
    'Rua Felipe Schmidt, 153, Centro, Florianópolis, Santa Catarina',
    'Avenida Jornalista Rubens de Arruda Ramos, 2000, Beira Mar Norte, Florianópolis, Santa Catarina',
    'Praça Pereira Oliveira, 50, Centro, Florianópolis, Santa Catarina',
  ];

  static const List<String> _clients = [
    'Madero Bugers',
    'Viper Sushi',
    'Pizza Express',
    'Açaí do Porto',
    'Burger King',
  ];

  /// Gera uma oferta baseada no GPS real e motor de precificação variável (Surge Pricing)
  static ViperOffer generateOffer({double? userLat, double? userLng}) {
    final isSuper = _random.nextBool();
    final qtdPedidos = isSuper ? _random.nextInt(3) + 3 : 1; 
    final mainType = ViperOrderType.values[_random.nextInt(ViperOrderType.values.length)];
    final client = _clients[_random.nextInt(_clients.length)];

    // 1. Usar Posição Real do Motorista (Marco Zero)
    // Se não houver coordenadas reais (permissão negada etc), usa fallback de Florianópolis
    final currentLat = userLat ?? -27.5948;
    final currentLng = userLng ?? -48.5569;

    // 2. Definir Ponto de Coleta (Sempre em Palhoça para o Corredor)
    final pickupAddr = _addrPalhoca[_random.nextInt(_addrPalhoca.length)];
    final pCoords = _coords[pickupAddr]!;
    final pParts = pickupAddr.split(',');

    // 3. Gerar Pedidos (Entregas Fluxo Logístico: SJ -> Floripa)
    final List<ViperOrder> rawOrders = [];
    
    if (isSuper) {
      // Super Rota Dinâmica (5 Pontos de Corredor)
      // Parada 1 e 2 em São José
      for (int i = 0; i < 2; i++) {
        final addr = _addrSaoJose[_random.nextInt(_addrSaoJose.length)];
        rawOrders.add(_createOrder(addr, pickupAddr, pParts, client, mainType));
      }
      // Parada 3 e 4 em Florianópolis
      for (int i = 0; i < 2; i++) {
        final addr = _addrFloripa[_random.nextInt(_addrFloripa.length)];
        rawOrders.add(_createOrder(addr, pickupAddr, pParts, client, mainType));
      }
    } else {
      // Rota Simples (Local ou Regional)
      final allAddresses = [..._addrPalhoca, ..._addrSaoJose, ..._addrFloripa];
      String dropoffAddr;
      do {
        dropoffAddr = allAddresses[_random.nextInt(allAddresses.length)];
      } while (dropoffAddr == pickupAddr);
      rawOrders.add(_createOrder(dropoffAddr, pickupAddr, pParts, client, mainType));
    }

    // 4. Rodar Motor de Roteirização baseado na posição REAL
    final routingResult = ViperRoutingService.optimize(
      driverLat: currentLat,
      driverLng: currentLng,
      pickupLat: pCoords[0],
      pickupLng: pCoords[1],
      orders: rawOrders,
    );

    // 5. Algoritmo de Precificação Viper v5 (Odômetro Acumulado)
    // O totalDistance do routingResult já contém: (Motorista -> Coleta) + (Coleta -> Entrega 1 -> Entrega 2...)
    final double distIda = routingResult.distanceDriverToPickup;
    final double distRotaAcumulada = routingResult.distancePickupToDeliveries; 
    final double distTotalOdometro = routingResult.totalDistance;

    // Taxa Fixa de Ida (Deslocamento): R$ 0,85/km
    const double valorKmIda = 0.85;
    
    // Taxa Dinâmica de Rota (Entrega): Sorteio entre R$ 1,35 e R$ 1,60/km 
    // Aumentamos levemente para garantir a média alvo em trajetos mais longos
    final double valorKmRota = 1.35 + (_random.nextDouble() * 0.25);

    // Valor Total = Soma de todas as pernas do odômetro
    double valorFinal = (distIda * valorKmIda) + (distRotaAcumulada * valorKmRota);
    
    // Trava 1: Bandeirada Mínima (R$ 7,50)
    if (valorFinal < 7.50) {
      valorFinal = 7.50;
    }

    // Trava 2: Garantia de Média VIPER (Meta: R$ 1,20 a R$ 1,40 / KM Total)
    final double mediaKmReal = valorFinal / distTotalOdometro;
    
    // Se a média por KM total for menor que R$ 1,20, ajustamos para o alvo comercial de R$ 1,30/km
    if (mediaKmReal < 1.20) {
      valorFinal = distTotalOdometro * 1.30;
    }
    
    final valorKmMedioFinal = valorFinal / distTotalOdometro;
    final valorFracionado = valorFinal / qtdPedidos;

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
      distanciaTotal: distTotalOdometro,
      distanciaDeslocamento: distIda,
      valorTotal: valorFinal,
      valorPorKm: valorKmMedioFinal,
      valorKmIda: valorKmIda,
      valorKmRota: valorKmRota,
      isSuper: isSuper,
      pickupNeighborhood: finalOrders.first.bairroColeta,
      pickupStreet: finalOrders.first.enderecoColeta,
      dropoffNeighborhood: finalOrders.last.bairroEntrega,
      dropoffStreet: finalOrders.last.enderecoEntrega,
      contractType: _random.nextBool() ? ViperContractType.clt : ViperContractType.freelancer,
      routeType: isSuper ? ViperRouteType.super_rota : ViperRouteType.simple,
    );
  }

  static ViperOrder _createOrder(String addr, String pickup, List<String> pParts, String client, ViperOrderType type) {
    final parts = addr.split(',');
    final coords = _coords[addr]!;
    return ViperOrder(
      id: 'order_${_random.nextInt(10000)}',
      cliente: client,
      enderecoColeta: pickup,
      bairroColeta: pParts[2].trim(),
      enderecoEntrega: addr,
      bairroEntrega: parts[2].trim(),
      tipo: type,
      valor: 0,
      lat: coords[0],
      lng: coords[1],
    );
  }

  static List<ViperOrder> generateRandomRide() {
    return generateOffer().orders;
  }
}
