class VehicleModel {
  final String? id;
  final String? driverId;
  final String? model;
  final String? color;
  final String? crlvUrl;
  final String? inspectionFrontUrl;
  final String? inspectionBackUrl;
  final String? inspectionLeftUrl;
  final String? inspectionRightUrl;

  VehicleModel({
    this.id,
    this.driverId,
    this.model,
    this.color,
    this.crlvUrl,
    this.inspectionFrontUrl,
    this.inspectionBackUrl,
    this.inspectionLeftUrl,
    this.inspectionRightUrl,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      driverId: json['driver_id'],
      model: json['model'],
      color: json['color'],
      crlvUrl: json['crlv_url'],
      inspectionFrontUrl: json['inspection_front_url'],
      inspectionBackUrl: json['inspection_back_url'],
      inspectionLeftUrl: json['inspection_left_url'],
      inspectionRightUrl: json['inspection_right_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (driverId != null) 'driver_id': driverId,
      'model': model,
      'color': color,
      'crlv_url': crlvUrl,
      'inspection_front_url': inspectionFrontUrl,
      'inspection_back_url': inspectionBackUrl,
      'inspection_left_url': inspectionLeftUrl,
      'inspection_right_url': inspectionRightUrl,
    };
  }
}
