import 'package:flutter/material.dart';

enum ViperOrderType { coleta, entrega, outros }

extension ViperOrderTypeExtension on ViperOrderType {
  Color get color {
    switch (this) {
      case ViperOrderType.entrega:
        return Colors.blueAccent;
      case ViperOrderType.coleta:
        return Colors.orange;
      case ViperOrderType.outros:
        return Colors.purpleAccent;
    }
  }

  String get label {
    switch (this) {
      case ViperOrderType.entrega:
        return 'ENTREGA';
      case ViperOrderType.coleta:
        return 'COLETA';
      case ViperOrderType.outros:
        return 'SERVIÇO';
    }
  }
}

class ViperOrder {
  final String id;
  final String cliente;
  final String enderecoColeta;
  final String bairroColeta;
  final String enderecoEntrega;
  final String bairroEntrega;
  final ViperOrderType tipo;
  final double valor;
  final double lat;
  final double lng;

  ViperOrder({
    required this.id,
    required this.cliente,
    required this.enderecoColeta,
    required this.bairroColeta,
    required this.enderecoEntrega,
    required this.bairroEntrega,
    required this.tipo,
    required this.valor,
    required this.lat,
    required this.lng,
  });
}

class ViperOffer {
  final String id;
  final List<ViperOrder> orders;
  final double distanciaTotal;
  final double valorTotal;
  final double valorPorKm;
  final bool isSuper;
  final String pickupNeighborhood;
  final String pickupStreet;
  final String dropoffNeighborhood;
  final String dropoffStreet;
  final double distanciaDeslocamento;

  ViperOffer({
    required this.id,
    required this.orders,
    required this.distanciaTotal,
    required this.valorTotal,
    required this.valorPorKm,
    required this.isSuper,
    required this.pickupNeighborhood,
    required this.pickupStreet,
    required this.dropoffNeighborhood,
    required this.dropoffStreet,
    required this.distanciaDeslocamento,
  });

  int get qtdPedidos => orders.length;
}
