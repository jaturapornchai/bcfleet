import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://smlfleet.satistang.com/api/v1/fleet';

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

  factory FleetAlert.fromJson(Map<String, dynamic> json) => FleetAlert(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        entity: json['entity']?.toString() ?? '',
        entityId: json['entity_id']?.toString() ?? json['entityId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        severity: json['severity']?.toString() ?? 'info',
        dueDate: json['due_date'] != null
            ? DateTime.tryParse(json['due_date'].toString())
            : null,
        daysRemaining: json['days_remaining'] as int?,
        status: json['status']?.toString() ?? 'active',
        acknowledgedBy: json['acknowledged_by']?.toString(),
        acknowledgedAt: json['acknowledged_at'] != null
            ? DateTime.tryParse(json['acknowledged_at'].toString())
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AlertState {}

class AlertInitial extends AlertState {}

class AlertLoading extends AlertState {}

class AlertLoaded extends AlertState {
  final List<FleetAlert> alerts;

  AlertLoaded({required this.alerts});

  List<FleetAlert> get active =>
      alerts.where((a) => a.status == 'active').toList();
  List<FleetAlert> get critical =>
      alerts.where((a) => a.severity == 'critical' && a.status == 'active').toList();
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

  Future<void> _onAcknowledge(
      AcknowledgeAlert event, Emitter<AlertState> emit) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiBase/dashboard/alerts/${event.alertId}/acknowledge'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'acknowledged_by': event.acknowledgedBy}),
      );
      if (response.statusCode == 200) {
        emit(AlertActionSuccess('รับทราบแจ้งเตือนแล้ว'));
        add(LoadAlerts());
      } else {
        emit(AlertError('ดำเนินการไม่สำเร็จ: ${response.statusCode}'));
      }
    } catch (e) {
      emit(AlertError('ดำเนินการไม่สำเร็จ: $e'));
    }
  }

  Future<void> _fetchAndEmit(Emitter<AlertState> emit) async {
    try {
      final response = await http.get(Uri.parse('$_apiBase/dashboard/alerts'));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final list = body['data'] as List? ?? [];
        final alerts = list
            .whereType<Map<String, dynamic>>()
            .map(FleetAlert.fromJson)
            .toList();
        emit(AlertLoaded(alerts: alerts));
      } else {
        emit(AlertError('API error: ${response.statusCode}'));
      }
    } catch (e) {
      emit(AlertError('โหลดแจ้งเตือนไม่สำเร็จ: $e'));
    }
  }
}
