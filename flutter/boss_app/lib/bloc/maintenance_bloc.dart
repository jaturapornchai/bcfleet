import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fleet_core/models/maintenance.dart';

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
      return workOrders.where((w) => w.status == 'in_progress' || w.status == 'approved').toList();
    }
    if (activeFilter == 'completed') {
      return workOrders.where((w) => w.status == 'completed').toList();
    }
    return workOrders.where((w) => w.status == activeFilter).toList();
  }

  int get pendingCount => workOrders.where((w) => w.status == 'pending_approval').length;
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
    final filter = state is MaintenanceLoaded ? (state as MaintenanceLoaded).activeFilter : null;
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
      await Future.delayed(const Duration(milliseconds: 400));
      emit(MaintenanceActionSuccess('อนุมัติใบสั่งซ่อมสำเร็จ'));
      add(LoadWorkOrders());
    } catch (e) {
      emit(MaintenanceError('อนุมัติไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onReject(RejectWorkOrder event, Emitter<MaintenanceState> emit) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      emit(MaintenanceActionSuccess('ปฏิเสธใบสั่งซ่อมแล้ว'));
      add(LoadWorkOrders());
    } catch (e) {
      emit(MaintenanceError('ดำเนินการไม่สำเร็จ: $e'));
    }
  }

  Future<void> _fetchAndEmit(Emitter<MaintenanceState> emit, String? filter) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(MaintenanceLoaded(workOrders: _mockWorkOrders(), activeFilter: filter));
    } catch (e) {
      emit(MaintenanceError('โหลดข้อมูลไม่สำเร็จ: $e'));
    }
  }

  List<WorkOrder> _mockWorkOrders() {
    final now = DateTime.now();
    return [
      WorkOrder(
        id: 'wo1', shopId: 's1', woNo: 'WO-2568-0001',
        vehicleId: 'v1', type: 'preventive', priority: 'medium',
        status: 'pending_approval', reportedBy: 'd1',
        description: 'น้ำมันเครื่องครบรอบ 10,000 กม.',
        mileageAtReport: 90000,
        serviceProviderType: 'internal',
        serviceProviderName: 'ช่างสมศักดิ์',
        partsCost: 3040, laborCost: 1000, totalCost: 4040,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      WorkOrder(
        id: 'wo2', shopId: 's1', woNo: 'WO-2568-0002',
        vehicleId: 'v3', type: 'corrective', priority: 'high',
        status: 'in_progress', reportedBy: 'd3',
        description: 'เบรคหลังมีเสียงดัง ผ้าเบรคสึกหรอ',
        mileageAtReport: 45200,
        serviceProviderType: 'external',
        serviceProviderName: 'อู่เชียงใหม่มอเตอร์',
        partsCost: 2500, laborCost: 800, totalCost: 3300,
        approvedBy: 'admin_001',
        approvedAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      WorkOrder(
        id: 'wo3', shopId: 's1', woNo: 'WO-2568-0003',
        vehicleId: 'v2', type: 'preventive', priority: 'low',
        status: 'completed',
        description: 'เปลี่ยนกรองอากาศ + กรองน้ำมันเชื้อเพลิง',
        mileageAtReport: 120000,
        serviceProviderType: 'internal',
        serviceProviderName: 'ช่างสมศักดิ์',
        partsCost: 1200, laborCost: 500, totalCost: 1700,
        approvedBy: 'admin_001',
        approvedAt: now.subtract(const Duration(days: 3)),
        completedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      WorkOrder(
        id: 'wo4', shopId: 's1', woNo: 'WO-2568-0004',
        vehicleId: 'v4', type: 'emergency', priority: 'critical',
        status: 'pending_approval', reportedBy: 'd4',
        description: 'ยางแบนระหว่างทาง ต้องเปลี่ยนยางใหม่ 2 เส้น',
        mileageAtReport: 98500,
        serviceProviderType: 'external',
        serviceProviderName: 'ร้านยาง 24 ชม.',
        partsCost: 6000, laborCost: 400, totalCost: 6400,
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      ),
    ];
  }
}
