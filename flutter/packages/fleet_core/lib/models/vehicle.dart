/// Vehicle model — ข้อมูลรถขนส่ง
class Vehicle {
  final String id;
  final String shopId;
  final String plate;
  final String? brand;
  final String? model;
  final String type; // "4ล้อ", "6ล้อ", "10ล้อ", "หัวลาก", "กระบะ"
  final int? year;
  final String? color;
  final String? fuelType;
  final int? maxWeightKg;
  final String ownership; // "own", "partner", "rental"
  final String status; // "active", "maintenance", "inactive"
  final String? currentDriverId;
  final int? mileageKm;
  final String healthStatus; // "green", "yellow", "red"
  final DateTime? insuranceExpiry;
  final DateTime? taxDueDate;
  final DateTime? actDueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.shopId,
    required this.plate,
    this.brand,
    this.model,
    required this.type,
    this.year,
    this.color,
    this.fuelType,
    this.maxWeightKg,
    this.ownership = 'own',
    this.status = 'active',
    this.currentDriverId,
    this.mileageKm,
    this.healthStatus = 'green',
    this.insuranceExpiry,
    this.taxDueDate,
    this.actDueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      plate: json['plate'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      type: json['type'] as String,
      year: json['year'] as int?,
      color: json['color'] as String?,
      fuelType: json['fuel_type'] as String?,
      maxWeightKg: json['max_weight_kg'] as int?,
      ownership: json['ownership'] as String? ?? 'own',
      status: json['status'] as String? ?? 'active',
      currentDriverId: json['current_driver_id'] as String?,
      mileageKm: json['mileage_km'] as int?,
      healthStatus: json['health_status'] as String? ?? 'green',
      insuranceExpiry: json['insurance_expiry'] != null ? DateTime.parse(json['insurance_expiry']) : null,
      taxDueDate: json['tax_due_date'] != null ? DateTime.parse(json['tax_due_date']) : null,
      actDueDate: json['act_due_date'] != null ? DateTime.parse(json['act_due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shop_id': shopId,
    'plate': plate,
    'brand': brand,
    'model': model,
    'type': type,
    'year': year,
    'color': color,
    'fuel_type': fuelType,
    'max_weight_kg': maxWeightKg,
    'ownership': ownership,
    'status': status,
    'current_driver_id': currentDriverId,
    'mileage_km': mileageKm,
    'health_status': healthStatus,
  };
}
