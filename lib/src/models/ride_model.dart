import 'package:flutter/material.dart';

enum RideType { entrega, coleta, outros }

extension RideTypeExtension on RideType {
  Color get color {
    switch (this) {
      case RideType.entrega:
        return Colors.blueAccent;
      case RideType.coleta:
        return Colors.orange;
      case RideType.outros:
        return Colors.purpleAccent;
    }
  }

  String get label {
    switch (this) {
      case RideType.entrega:
        return 'ENTREGA';
      case RideType.coleta:
        return 'COLETA';
      case RideType.outros:
        return 'SERVIÇO';
    }
  }
}

enum RideStatus { pending, assigned, goingToPickup, arrivedAtPickup, onDeliveryRoute, completed, failed, returned }
enum RidePaymentStatus { paid_online, pending }
enum RideContractType { clt, freelancer }

class RideModel {
  final String id;
  final String driverId;
  final String clientName;
  final String pickupAddress;
  final String deliveryAddress;
  final String deliveryNeighborhood;
  final RideType serviceType;
  final double driverValue;
  final double lat;
  final double lng;
  final RideStatus status;
  final String? observations;
  final String? failureReason;

  RideModel({
    required this.id,
    required this.driverId,
    required this.clientName,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.deliveryNeighborhood,
    required this.serviceType,
    required this.driverValue,
    required this.lat,
    required this.lng,
    this.status = RideStatus.pending,
    this.observations,
    this.failureReason,
  });

  factory RideModel.fromMap(Map<String, dynamic> map) {
    // Parser for RideType
    RideType type = RideType.entrega;
    final String typeStr = (map['service_type'] ?? '').toString().toLowerCase();
    if (typeStr.contains('coleta')) type = RideType.coleta;
    if (typeStr.contains('serviço') || typeStr.contains('outros')) type = RideType.outros;

    // Parser for RideStatus
    RideStatus rStatus = RideStatus.pending;
    final String statusStr = (map['status'] ?? 'pending').toString().toLowerCase();
    switch (statusStr) {
      case 'assigned': rStatus = RideStatus.assigned; break;
      case 'going_to_pickup': rStatus = RideStatus.goingToPickup; break;
      case 'arrived_at_pickup': rStatus = RideStatus.arrivedAtPickup; break;
      case 'on_delivery_route': rStatus = RideStatus.onDeliveryRoute; break;
      case 'completed': rStatus = RideStatus.completed; break;
      case 'failed': rStatus = RideStatus.failed; break;
      case 'returned': rStatus = RideStatus.returned; break;
    }

    return RideModel(
      id: map['id']?.toString() ?? '',
      driverId: map['driver_id']?.toString() ?? '',
      clientName: map['client_name']?.toString() ?? 'Cliente',
      pickupAddress: map['pickup_address']?.toString() ?? '',
      deliveryAddress: map['delivery_address']?.toString() ?? '',
      deliveryNeighborhood: map['delivery_neighborhood']?.toString() ?? '',
      serviceType: type,
      driverValue: double.tryParse(map['driver_value']?.toString() ?? '0.0') ?? 0.0,
      lat: double.tryParse(map['lat']?.toString() ?? '0.0') ?? 0.0,
      lng: double.tryParse(map['lng']?.toString() ?? '0.0') ?? 0.0,
      status: rStatus,
      observations: map['observations']?.toString(),
      failureReason: map['failure_reason']?.toString(),
    );
  }

  RideModel copyWith({
    RideStatus? status,
    String? failureReason,
  }) {
    return RideModel(
      id: id,
      driverId: driverId,
      clientName: clientName,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      deliveryNeighborhood: deliveryNeighborhood,
      serviceType: serviceType,
      driverValue: driverValue,
      lat: lat,
      lng: lng,
      status: status ?? this.status,
      observations: observations,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}

class RideExecutionSummary {
  final double baseValue;
  final double successBonus;
  final double attemptFee;
  final double totalValue;
  final int countSuccess;
  final int countFailed;
  final RidePaymentStatus paymentStatus;
  final RideContractType contractType;

  RideExecutionSummary({
    required this.baseValue,
    required this.successBonus,
    required this.attemptFee,
    required this.totalValue,
    required this.countSuccess,
    required this.countFailed,
    this.paymentStatus = RidePaymentStatus.paid_online,
    this.contractType = RideContractType.freelancer,
  });
}
