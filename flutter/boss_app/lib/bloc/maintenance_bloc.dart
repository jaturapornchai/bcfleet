import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fleet_core/models/maintenance.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://bcfleet.satistang.com/api/v1/fleet';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class MaintenanceEvent {}

class LoadWorkOrders extends MaintenanceEvent {
  final String? statusFilter;
  LoadWorkOrders({this.statusFilter});
}

class RefreshWorkOrders extends MaintenanceEvent {}

class FilterWorkOrders extends MaintenanceEvent {
  final String? status;
  FilterWorkOrders({this.status});
}

class ApproveWorkOrder extends MaintenanceEvent {
  final String workOrderId;
  final String approvedBy;
  ApproveWorkOrder({required this.workOrderId, required this.approvedBy});
}

class RejectWorkOrder extends MaintenanceEvent {
  final String workOrderId;
  final String reason;
  RejectWorkOrder({required this.workOrderId, required this.reason});
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class MaintenanceState {}

class MaintenanceInitial extends MaintenanceState {}

class MaintenanceLoading extends MaintenanceState {}

class MaintenanceLoaded extends MaintenanceState {
  final List<WorkOrder> workOrders;
  final String? activeFilter;

  MaintenanceLoaded({required this.workOrders, this.activeFilter});

  List<WorkOrder> get filtered {
    if (activeFilter == null || activeFilter == 'all') return workOrders;
    if (activeFilter == 'pending_approval') {
      return workOrders.where((w) => w.status == 'pending_approval').toList();
    }
    if (activeFilter == 'in_progress') {
      return workOrders
          .where((w) => w.status == 'in_progress' || w.status == 'approved')
          .toList();
    }
    if (activeFilter == 'completed') {
      return workOrders.where((w) => w.status == 'completed').toList();
    }
    return workOrders.where((w) => w.status == activeFilter).toList();
  }

  int get pendingCount =>
      workOrders.where((w) => w.status == 'pending_approval').length;
}

class MaintenanceError extends MaintenanceState {
  final String message;
  MaintenanceError(this.message);
}

class MaintenanceActionSuccess extends MaintenanceState {
  final String message;
  MaintenanceActionSuccess(this.message);
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class MaintenanceBloc extends Bloc<MaintenanceEvent, MaintenanceState> {
  MaintenanceBloc() : super(MaintenanceInitial()) {
    on<LoadWorkOrders>(_onLoad);
    on<RefreshWorkOrders>(_onRefresh);
    on<FilterWorkOrders>(_onFilter);
    on<ApproveWorkOrder>(_onApprove);
    on<RejectWorkOrder>(_onReject);
  }

  Future<void> _onLoad(LoadWorkOrders event, Emitter<MaintenanceState> emit) async {
    emit(MaintenanceLoading());
    await _fetchAndEmit(emit, event.statusFilter);
  }

  Future<void> _onRefresh(RefreshWorkOrders event, Emitter<MaintenanceState> emit) async {
    final filter =
        state is MaintenanceLoaded ? (state as MaintenanceLoaded).activeFilter : null;
    await _fetchAndEmit(emit, filter);
  }

  Future<void> _onFilter(FilterWorkOrders event, Emitter<MaintenanceState> emit) async {
    if (state is MaintenanceLoaded) {
      final current = state as MaintenanceLoaded;
      emit(MaintenanceLoaded(workOrders: current.workOrders, activeFilter: event.status));
    }
  }

  Future<void> _onApprove(ApproveWorkOrder event, Emitter<MaintenanceState> emit) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiBase/maintenance/work-orders/${event.workOrderId}/approve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'approved_by': event.approvedBy}),
      );
      if (response.statusCode == 200) {
        emit(MaintenanceActionSuccess('อนุมัติใบสั่งซ่อมสำเร็จ'));
        add(LoadWorkOrders());
      } else {
        emit(MaintenanceError('อนุมัติไม่สำเร็จ: ${response.statusCode}'));
      }
    } catch (e) {
      emit(MaintenanceError('อนุมัติไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onReject(RejectWorkOrder event, Emitter<MaintenanceState> emit) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiBase/maintenance/work-orders/${event.workOrderId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': 'cancelled', 'reason': event.reason}),
      );
      if (response.statusCode == 200) {
        emit(MaintenanceActionSuccess('ปฏิเสธใบสั่งซ่อมแล้ว'));
        add(LoadWorkOrders());
      } else {
        emit(MaintenanceError('ดำเนินการไม่สำเร็จ: ${response.statusCode}'));
      }
    } catch (e) {
      emit(MaintenanceError('ดำเนินการไม่สำเร็จ: $e'));
    }
  }

  Future<void> _fetchAndEmit(Emitter<MaintenanceState> emit, String? filter) async {
    try {
      final response =
          await http.get(Uri.parse('$_apiBase/maintenance/work-orders'));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final list = body['data'] as List? ?? [];
        final workOrders = list
            .whereType<Map<String, dynamic>>()
            .map(WorkOrder.fromJson)
            .toList();
        emit(MaintenanceLoaded(workOrders: workOrders, activeFilter: filter));
      } else {
        emit(MaintenanceError('API error: ${response.statusCode}'));
      }
    } catch (e) {
      emit(MaintenanceError('โหลดข้อมูลไม่สำเร็จ: $e'));
    }
  }
}
