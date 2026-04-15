import 'package:flutter/material.dart';

enum ViperOrderType { coleta, entrega, outros }

enum ViperOrderStatus { pending, completed, failed, returned }

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
  final ViperOrderStatus status;
  final String? motivoFalha;

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
    this.status = ViperOrderStatus.pending,
    this.motivoFalha,
  });

  ViperOrder copyWith({
    ViperOrderStatus? status,
    String? motivoFalha,
  }) {
    return ViperOrder(
      id: id,
      cliente: cliente,
      enderecoColeta: enderecoColeta,
      bairroColeta: bairroColeta,
      enderecoEntrega: enderecoEntrega,
      bairroEntrega: bairroEntrega,
      tipo: tipo,
      valor: valor,
      lat: lat,
      lng: lng,
      status: status ?? this.status,
      motivoFalha: motivoFalha ?? this.motivoFalha,
    );
  }
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

class ViperExecutionSummary {
  final double baseValue;
  final double successBonus;
  final double attemptFee;
  final double totalValue;
  final int countSuccess;
  final int countFailed;

  ViperExecutionSummary({
    required this.baseValue,
    required this.successBonus,
    required this.attemptFee,
    required this.totalValue,
    required this.countSuccess,
    required this.countFailed,
  });
}
