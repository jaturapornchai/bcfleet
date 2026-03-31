/// Trip model — เที่ยววิ่ง
class Trip {
  final String id;
  final String shopId;
  final String? tripNo;
  final String status;
  final String? vehicleId;
  final String? driverId;
  final bool isPartner;
  final String? partnerId;
  final String? originName;
  final double? originLat;
  final double? originLng;
  final int destinationCount;
  final String? cargoDescription;
  final int? cargoWeightKg;
  final DateTime? plannedStart;
  final DateTime? plannedEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final double? distanceKm;
  final double? fuelCost;
  final double? tollCost;
  final double? otherCost;
  final double? driverAllowance;
  final double? totalCost;
  final double? revenue;
  final double? profit;
  final bool hasPod;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.shopId,
    this.tripNo,
    required this.status,
    this.vehicleId,
    this.driverId,
    this.isPartner = false,
    this.partnerId,
    this.originName,
    this.originLat,
    this.originLng,
    this.destinationCount = 1,
    this.cargoDescription,
    this.cargoWeightKg,
    this.plannedStart,
    this.plannedEnd,
    this.actualStart,
    this.actualEnd,
    this.distanceKm,
    this.fuelCost,
    this.tollCost,
    this.otherCost,
    this.driverAllowance,
    this.totalCost,
    this.revenue,
    this.profit,
    this.hasPod = false,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      tripNo: json['trip_no'] as String?,
      status: json['status'] as String,
      vehicleId: json['vehicle_id'] as String?,
      driverId: json['driver_id'] as String?,
      isPartner: json['is_partner'] as bool? ?? false,
      partnerId: json['partner_id'] as String?,
      originName: json['origin_name'] as String?,
      originLat: (json['origin_lat'] as num?)?.toDouble(),
      originLng: (json['origin_lng'] as num?)?.toDouble(),
      destinationCount: json['destination_count'] as int? ?? 1,
      cargoDescription: json['cargo_description'] as String?,
      cargoWeightKg: json['cargo_weight_kg'] as int?,
      plannedStart: json['planned_start'] != null ? DateTime.parse(json['planned_start']) : null,
      plannedEnd: json['planned_end'] != null ? DateTime.parse(json['planned_end']) : null,
      actualStart: json['actual_start'] != null ? DateTime.parse(json['actual_start']) : null,
      actualEnd: json['actual_end'] != null ? DateTime.parse(json['actual_end']) : null,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      fuelCost: (json['fuel_cost'] as num?)?.toDouble(),
      tollCost: (json['toll_cost'] as num?)?.toDouble(),
      otherCost: (json['other_cost'] as num?)?.toDouble(),
      driverAllowance: (json['driver_allowance'] as num?)?.toDouble(),
      totalCost: (json['total_cost'] as num?)?.toDouble(),
      revenue: (json['revenue'] as num?)?.toDouble(),
      profit: (json['profit'] as num?)?.toDouble(),
      hasPod: json['has_pod'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shop_id': shopId,
    'trip_no': tripNo,
    'status': status,
    'vehicle_id': vehicleId,
    'driver_id': driverId,
    'is_partner': isPartner,
    'origin_name': originName,
    'cargo_description': cargoDescription,
    'cargo_weight_kg': cargoWeightKg,
    'planned_start': plannedStart?.toIso8601String(),
    'planned_end': plannedEnd?.toIso8601String(),
    'revenue': revenue,
  };

  /// สถานะที่แสดงเป็นภาษาไทย
  String get statusThai {
    switch (status) {
      case 'draft': return 'แบบร่าง';
      case 'pending': return 'รอดำเนินการ';
      case 'accepted': return 'รับงานแล้ว';
      case 'started': return 'เริ่มวิ่งแล้ว';
      case 'arrived': return 'ถึงจุดส่ง';
      case 'delivering': return 'กำลังส่งมอบ';
      case 'completed': return 'เสร็จสิ้น';
      case 'cancelled': return 'ยกเลิก';
      default: return status;
    }
  }
}
