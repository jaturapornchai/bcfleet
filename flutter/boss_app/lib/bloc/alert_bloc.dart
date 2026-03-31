import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class AlertEvent {}

class LoadAlerts extends AlertEvent {}

class RefreshAlerts extends AlertEvent {}

class AcknowledgeAlert extends AlertEvent {
  final String alertId;
  final String acknowledgedBy;
  AcknowledgeAlert({required this.alertId, required this.acknowledgedBy});
}

// ─── Models ───────────────────────────────────────────────────────────────────

class FleetAlert {
  final String id;
  final String type;
  final String entity;
  final String entityId;
  final String title;
  final String message;
  final String severity; // "info", "warning", "critical"
  final DateTime? dueDate;
  final int? daysRemaining;
  final String status; // "active", "acknowledged", "resolved"
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final DateTime createdAt;

  FleetAlert({
    required this.id,
    required this.type,
    required this.entity,
    required this.entityId,
    required this.title,
    required this.message,
    required this.severity,
    this.dueDate,
    this.daysRemaining,
    this.status = 'active',
    this.acknowledgedBy,
    this.acknowledgedAt,
    required this.createdAt,
  });
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AlertState {}

class AlertInitial extends AlertState {}

class AlertLoading extends AlertState {}

class AlertLoaded extends AlertState {
  final List<FleetAlert> alerts;

  AlertLoaded({required this.alerts});

  List<FleetAlert> get active => alerts.where((a) => a.status == 'active').toList();
  List<FleetAlert> get critical => alerts.where((a) => a.severity == 'critical' && a.status == 'active').toList();
  int get activeCount => active.length;
}

class AlertError extends AlertState {
  final String message;
  AlertError(this.message);
}

class AlertActionSuccess extends AlertState {
  final String message;
  AlertActionSuccess(this.message);
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class AlertBloc extends Bloc<AlertEvent, AlertState> {
  AlertBloc() : super(AlertInitial()) {
    on<LoadAlerts>(_onLoad);
    on<RefreshAlerts>(_onRefresh);
    on<AcknowledgeAlert>(_onAcknowledge);
  }

  Future<void> _onLoad(LoadAlerts event, Emitter<AlertState> emit) async {
    emit(AlertLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(RefreshAlerts event, Emitter<AlertState> emit) async {
    await _fetchAndEmit(emit);
  }

  Future<void> _onAcknowledge(AcknowledgeAlert event, Emitter<AlertState> emit) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      emit(AlertActionSuccess('รับทราบแจ้งเตือนแล้ว'));
      add(LoadAlerts());
    } catch (e) {
      emit(AlertError('ดำเนินการไม่สำเร็จ: $e'));
    }
  }

  Future<void> _fetchAndEmit(Emitter<AlertState> emit) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      emit(AlertLoaded(alerts: _mockAlerts()));
    } catch (e) {
      emit(AlertError('โหลดแจ้งเตือนไม่สำเร็จ: $e'));
    }
  }

  List<FleetAlert> _mockAlerts() {
    final now = DateTime.now();
    return [
      FleetAlert(
        id: 'a1', type: 'act_due', entity: 'vehicle', entityId: 'v3',
        title: 'พ.ร.บ. ใกล้หมดอายุ',
        message: 'รถ นค-9012 พ.ร.บ. หมดอายุ 01/04/2568 (เหลือ 1 วัน)',
        severity: 'critical',
        dueDate: now.add(const Duration(days: 1)),
        daysRemaining: 1,
        status: 'active',
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      FleetAlert(
        id: 'a2', type: 'insurance_expiry', entity: 'vehicle', entityId: 'v1',
        title: 'ประกันภัยใกล้หมดอายุ',
        message: 'รถ กท-1234 ประกันหมดอายุ 15/03/2568 (เหลือ 30 วัน)',
        severity: 'warning',
        dueDate: now.add(const Duration(days: 30)),
        daysRemaining: 30,
        status: 'active',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      FleetAlert(
        id: 'a3', type: 'maintenance_due', entity: 'vehicle', entityId: 'v2',
        title: 'ถึงกำหนดเปลี่ยนน้ำมันเครื่อง',
        message: 'รถ ชม-5678 ครบ 10,000 กม. แล้ว (ปัจจุบัน 120,000 กม.)',
        severity: 'warning',
        daysRemaining: 0,
        status: 'active',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      FleetAlert(
        id: 'a4', type: 'license_expiry', entity: 'driver', entityId: 'd1',
        title: 'ใบขับขี่ใกล้หมดอายุ',
        message: 'คนขับ สมชาย ใจดี ใบขับขี่หมด 20/04/2568 (เหลือ 20 วัน)',
        severity: 'info',
        dueDate: now.add(const Duration(days: 20)),
        daysRemaining: 20,
        status: 'active',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      FleetAlert(
        id: 'a5', type: 'tax_due', entity: 'vehicle', entityId: 'v4',
        title: 'ภาษีรถยนต์ใกล้ถึงกำหนด',
        message: 'รถ พย-3456 ภาษีครบกำหนด 15/04/2568 (เหลือ 15 วัน)',
        severity: 'warning',
        dueDate: now.add(const Duration(days: 15)),
        daysRemaining: 15,
        status: 'acknowledged',
        acknowledgedBy: 'admin_001',
        acknowledgedAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
