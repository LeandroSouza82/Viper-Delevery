class VehicleModel {
  final String id;
  final String driverId;
  final String? vehicleType;
  final String plate;
  final String? model;
  final String? color;
  final String? crlvUrl;

  VehicleModel({
    required this.id,
    required this.driverId,
    this.vehicleType,
    required this.plate,
    this.model,
    this.color,
    this.crlvUrl,
  });

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: map['id'] ?? '',
      driverId: map['driver_id'] ?? '',
      vehicleType: map['vehicle_type'],
      plate: map['plate'] ?? '-- -- --',
      model: map['model'] ?? 'NÃO CADASTRADO',
      color: map['color'] ?? 'N/A',
      crlvUrl: map['crlv_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'vehicle_type': vehicleType,
      'plate': plate,
      'model': model,
      'color': color,
      'crlv_url': crlvUrl,
    };
  }
}
