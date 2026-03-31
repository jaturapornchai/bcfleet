/// PartnerVehicle model — รถร่วม
class PartnerVehicle {
  final String id;
  final String shopId;
  final String? ownerName;
  final String? ownerCompany;
  final String? ownerPhone;
  final String? ownerTaxId;
  final String? plate;
  final String? vehicleType;
  final int? maxWeightKg;
  final String? pricingModel; // "per_trip", "per_km", "per_day"
  final double? baseRate;
  final double? perKmRate;
  final double? rating;
  final int totalTrips;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PartnerVehicle({
    required this.id,
    required this.shopId,
    this.ownerName,
    this.ownerCompany,
    this.ownerPhone,
    this.ownerTaxId,
    this.plate,
    this.vehicleType,
    this.maxWeightKg,
    this.pricingModel,
    this.baseRate,
    this.perKmRate,
    this.rating,
    this.totalTrips = 0,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartnerVehicle.fromJson(Map<String, dynamic> json) {
    return PartnerVehicle(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      ownerName: json['owner_name'] as String?,
      ownerCompany: json['owner_company'] as String?,
      ownerPhone: json['owner_phone'] as String?,
      ownerTaxId: json['owner_tax_id'] as String?,
      plate: json['plate'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      maxWeightKg: json['max_weight_kg'] as int?,
      pricingModel: json['pricing_model'] as String?,
      baseRate: (json['base_rate'] as num?)?.toDouble(),
      perKmRate: (json['per_km_rate'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      totalTrips: json['total_trips'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'owner_name': ownerName,
    'owner_company': ownerCompany,
    'owner_phone': ownerPhone,
    'plate': plate,
    'vehicle_type': vehicleType,
    'max_weight_kg': maxWeightKg,
    'pricing_model': pricingModel,
    'base_rate': baseRate,
    'per_km_rate': perKmRate,
  };
}
