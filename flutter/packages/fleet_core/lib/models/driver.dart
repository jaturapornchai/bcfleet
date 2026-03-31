/// Driver model — ข้อมูลคนขับรถ
class Driver {
  final String id;
  final String shopId;
  final String? employeeId;
  final String name;
  final String? nickname;
  final String? phone;
  final String? licenseType;
  final DateTime? licenseExpiry;
  final String? employmentType;
  final double? salary;
  final double? dailyAllowance;
  final double? tripBonus;
  final String status;
  final String? assignedVehicleId;
  final int score;
  final int totalTrips;
  final double? onTimeRate;
  final double? fuelEfficiency;
  final double? customerRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  Driver({
    required this.id,
    required this.shopId,
    this.employeeId,
    required this.name,
    this.nickname,
    this.phone,
    this.licenseType,
    this.licenseExpiry,
    this.employmentType,
    this.salary,
    this.dailyAllowance,
    this.tripBonus,
    this.status = 'active',
    this.assignedVehicleId,
    this.score = 0,
    this.totalTrips = 0,
    this.onTimeRate,
    this.fuelEfficiency,
    this.customerRating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      employeeId: json['employee_id'] as String?,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      phone: json['phone'] as String?,
      licenseType: json['license_type'] as String?,
      licenseExpiry: json['license_expiry'] != null ? DateTime.parse(json['license_expiry']) : null,
      employmentType: json['employment_type'] as String?,
      salary: (json['salary'] as num?)?.toDouble(),
      dailyAllowance: (json['daily_allowance'] as num?)?.toDouble(),
      tripBonus: (json['trip_bonus'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'active',
      assignedVehicleId: json['assigned_vehicle_id'] as String?,
      score: json['score'] as int? ?? 0,
      totalTrips: json['total_trips'] as int? ?? 0,
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble(),
      fuelEfficiency: (json['fuel_efficiency'] as num?)?.toDouble(),
      customerRating: (json['customer_rating'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shop_id': shopId,
    'employee_id': employeeId,
    'name': name,
    'nickname': nickname,
    'phone': phone,
    'license_type': licenseType,
    'employment_type': employmentType,
    'salary': salary,
    'daily_allowance': dailyAllowance,
    'trip_bonus': tripBonus,
    'status': status,
    'assigned_vehicle_id': assignedVehicleId,
  };
}
