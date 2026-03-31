/// WorkOrder model — ใบสั่งซ่อม
class WorkOrder {
  final String id;
  final String shopId;
  final String? woNo;
  final String vehicleId;
  final String? type; // "preventive", "corrective", "emergency"
  final String? priority; // "low", "medium", "high", "critical"
  final String status;
  final String? reportedBy;
  final String? description;
  final int? mileageAtReport;
  final String? serviceProviderType;
  final String? serviceProviderName;
  final double? partsCost;
  final double? laborCost;
  final double? totalCost;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkOrder({
    required this.id,
    required this.shopId,
    this.woNo,
    required this.vehicleId,
    this.type,
    this.priority,
    required this.status,
    this.reportedBy,
    this.description,
    this.mileageAtReport,
    this.serviceProviderType,
    this.serviceProviderName,
    this.partsCost,
    this.laborCost,
    this.totalCost,
    this.approvedBy,
    this.approvedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      woNo: json['wo_no'] as String?,
      vehicleId: json['vehicle_id'] as String,
      type: json['type'] as String?,
      priority: json['priority'] as String?,
      status: json['status'] as String,
      reportedBy: json['reported_by'] as String?,
      description: json['description'] as String?,
      mileageAtReport: json['mileage_at_report'] as int?,
      serviceProviderType: json['service_provider_type'] as String?,
      serviceProviderName: json['service_provider_name'] as String?,
      partsCost: (json['parts_cost'] as num?)?.toDouble(),
      laborCost: (json['labor_cost'] as num?)?.toDouble(),
      totalCost: (json['total_cost'] as num?)?.toDouble(),
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'vehicle_id': vehicleId,
    'type': type,
    'priority': priority,
    'description': description,
    'mileage_at_report': mileageAtReport,
    'service_provider_type': serviceProviderType,
    'service_provider_name': serviceProviderName,
  };

  /// สถานะเป็นภาษาไทย
  String get statusThai {
    switch (status) {
      case 'draft': return 'แบบร่าง';
      case 'pending_approval': return 'รออนุมัติ';
      case 'approved': return 'อนุมัติแล้ว';
      case 'in_progress': return 'กำลังดำเนินการ';
      case 'completed': return 'เสร็จสิ้น';
      case 'cancelled': return 'ยกเลิก';
      default: return status;
    }
  }
}
