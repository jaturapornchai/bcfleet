/// Expense model — ค่าใช้จ่าย
class Expense {
  final String id;
  final String shopId;
  final String? tripId;
  final String? vehicleId;
  final String? driverId;
  final String type; // "fuel", "toll", "parking", "repair", "fine", "other"
  final String? description;
  final double amount;
  final double? fuelLiters;
  final double? fuelPricePerLiter;
  final int? odometerKm;
  final String? receiptUrl;
  final DateTime? recordedAt;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.shopId,
    this.tripId,
    this.vehicleId,
    this.driverId,
    required this.type,
    this.description,
    required this.amount,
    this.fuelLiters,
    this.fuelPricePerLiter,
    this.odometerKm,
    this.receiptUrl,
    this.recordedAt,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      tripId: json['trip_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      driverId: json['driver_id'] as String?,
      type: json['type'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      fuelLiters: (json['fuel_liters'] as num?)?.toDouble(),
      fuelPricePerLiter: (json['fuel_price_per_liter'] as num?)?.toDouble(),
      odometerKm: json['odometer_km'] as int?,
      receiptUrl: json['receipt_url'] as String?,
      recordedAt: json['recorded_at'] != null ? DateTime.parse(json['recorded_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'trip_id': tripId,
    'vehicle_id': vehicleId,
    'driver_id': driverId,
    'type': type,
    'description': description,
    'amount': amount,
    'fuel_liters': fuelLiters,
    'fuel_price_per_liter': fuelPricePerLiter,
    'odometer_km': odometerKm,
  };

  /// ประเภทค่าใช้จ่ายเป็นภาษาไทย
  String get typeThai {
    switch (type) {
      case 'fuel': return 'น้ำมัน';
      case 'toll': return 'ทางด่วน';
      case 'parking': return 'ที่จอดรถ';
      case 'repair': return 'ซ่อมบำรุง';
      case 'fine': return 'ค่าปรับ';
      case 'other': return 'อื่นๆ';
      default: return type;
    }
  }
}
