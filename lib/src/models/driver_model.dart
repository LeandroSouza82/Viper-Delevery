import 'package:viper_delivery/src/models/vehicle_model.dart';

class DriverModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? cpf;
  final String? city;
  final String? neighborhood;
  final String? state;
  final String? phone;
  final String? email;
  final String? cnhNumber;
  final String? cnhCategory;
  final String? pixKey;
  final String? avatarUrl;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool? isClt;
  final List<VehicleModel>? vehicles;

  DriverModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.cpf,
    this.city,
    this.neighborhood,
    this.state,
    this.phone,
    this.email,
    this.cnhNumber,
    this.cnhCategory,
    this.pixKey,
    this.avatarUrl,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.isClt,
    this.vehicles,
  });

  DriverModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? cpf,
    String? city,
    String? neighborhood,
    String? state,
    String? phone,
    String? email,
    String? cnhNumber,
    String? cnhCategory,
    String? pixKey,
    String? avatarUrl,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool? isClt,
    List<VehicleModel>? vehicles,
  }) {
    return DriverModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      cpf: cpf ?? this.cpf,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      state: state ?? this.state,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      cnhNumber: cnhNumber ?? this.cnhNumber,
      cnhCategory: cnhCategory ?? this.cnhCategory,
      pixKey: pixKey ?? this.pixKey,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      isClt: isClt ?? this.isClt,
      vehicles: vehicles ?? this.vehicles,
    );
  }

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      id: map['id'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      cpf: map['cpf'],
      city: map['city'],
      neighborhood: map['neighborhood'],
      state: map['state'],
      phone: map['phone'],
      email: map['email'],
      cnhNumber: map['cnh_number'],
      cnhCategory: map['cnh_category'],
      pixKey: map['pix_key'],
      avatarUrl: map['avatar_url'],
      emergencyContactName: map['emergency_contact_name'],
      emergencyContactPhone: map['emergency_contact_phone'],
      isClt: map['is_clt'],
      vehicles: (map['vehicles'] as List<dynamic>?)
          ?.map((v) => VehicleModel.fromMap(v as Map<String, dynamic>))
          .toList(),
    );
  }
}
