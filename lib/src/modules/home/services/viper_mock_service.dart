import 'dart:math';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:viper_delivery/src/modules/home/services/viper_routing_service.dart';

class ViperMockService {
  static final Random _random = Random();

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

  /// Geradores Determinísticos para Ciclo de Testes
  static ViperOffer getMockEntrega({double? lat, double? lng}) {
    return generateOffer(userLat: lat, userLng: lng, forceSuper: false, forceType: ViperOrderType.entrega);
  }

  static ViperOffer getMockColeta({double? lat, double? lng}) {
    return generateOffer(userLat: lat, userLng: lng, forceSuper: false, forceType: ViperOrderType.coleta);
  }

  static ViperOffer getMockOutros({double? lat, double? lng}) {
    return generateOffer(userLat: lat, userLng: lng, forceSuper: false, forceType: ViperOrderType.outros);
  }

  /// Gera uma oferta baseada no GPS real e motor de precificação v5
  static ViperOffer generateOffer({double? userLat, double? userLng, bool? forceSuper, ViperOrderType? forceType}) {
    final isSuper = forceSuper ?? _random.nextBool();
    final qtdPedidos = isSuper ? _random.nextInt(3) + 3 : 1; 
    final mainType = forceType ?? ViperOrderType.values[_random.nextInt(ViperOrderType.values.length)];
    final client = _clients[_random.nextInt(_clients.length)];

    final currentLat = userLat ?? -27.5948;
    final currentLng = userLng ?? -48.5569;

    final pickupAddr = _addrPalhoca[_random.nextInt(_addrPalhoca.length)];
    final pCoords = _coords[pickupAddr]!;
    final pParts = pickupAddr.split(',');

    final List<ViperOrder> rawOrders = [];
    
    if (isSuper) {
      for (int i = 0; i < 2; i++) {
        final addr = _addrSaoJose[_random.nextInt(_addrSaoJose.length)];
        rawOrders.add(_createOrder(addr, pickupAddr, pParts, client, mainType));
      }
      for (int i = 0; i < 2; i++) {
        final addr = _addrFloripa[_random.nextInt(_addrFloripa.length)];
        rawOrders.add(_createOrder(addr, pickupAddr, pParts, client, mainType));
      }
    } else {
      final allAddresses = [..._addrPalhoca, ..._addrSaoJose, ..._addrFloripa];
      String dropoffAddr;
      do {
        dropoffAddr = allAddresses[_random.nextInt(allAddresses.length)];
      } while (dropoffAddr == pickupAddr);
      rawOrders.add(_createOrder(dropoffAddr, pickupAddr, pParts, client, mainType));
    }

    final routingResult = ViperRoutingService.optimize(
      driverLat: currentLat,
      driverLng: currentLng,
      pickupLat: pCoords[0],
      pickupLng: pCoords[1],
      orders: rawOrders,
    );

    final double distIda = routingResult.distanceDriverToPickup;
    final double distRotaAcumulada = routingResult.distancePickupToDeliveries; 
    final double distTotalOdometro = routingResult.totalDistance;

    const double valorKmIda = 0.85;
    final double valorKmRota = 1.35 + (_random.nextDouble() * 0.25);

    double valorFinal = (distIda * valorKmIda) + (distRotaAcumulada * valorKmRota);
    if (valorFinal < 7.50) valorFinal = 7.50;

    final double mediaKmReal = valorFinal / distTotalOdometro;
    if (mediaKmReal < 1.20) {
      valorFinal = distTotalOdometro * 1.30;
    }
    
    final valorKmMedioFinal = valorFinal / distTotalOdometro;
    final valorFracionado = valorFinal / qtdPedidos;

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
