import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class DashboardEvent {}

class LoadDashboard extends DashboardEvent {}

class RefreshDashboard extends DashboardEvent {}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;
  final TodayTrips todayTrips;
  final FleetKpi kpi;
  final List<AlertItem> recentAlerts;

  DashboardLoaded({
    required this.summary,
    required this.todayTrips,
    required this.kpi,
    required this.recentAlerts,
  });
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

// ─── Data Models ──────────────────────────────────────────────────────────────

class DashboardSummary {
  final int totalVehicles;
  final int activeVehicles;
  final int vehiclesInMaintenance;
  final int criticalVehicles;
  final int warningVehicles;
  final int totalDrivers;
  final int activeDrivers;
  final int activeAlerts;

  DashboardSummary({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.vehiclesInMaintenance,
    required this.criticalVehicles,
    required this.warningVehicles,
    required this.totalDrivers,
    required this.activeDrivers,
    required this.activeAlerts,
  });

  factory DashboardSummary.mock() => DashboardSummary(
        totalVehicles: 12,
        activeVehicles: 9,
        vehiclesInMaintenance: 2,
        criticalVehicles: 1,
        warningVehicles: 3,
        totalDrivers: 15,
        activeDrivers: 11,
        activeAlerts: 4,
      );
}

class TodayTrips {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;

  TodayTrips({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
  });

  factory TodayTrips.mock() => TodayTrips(
        total: 8,
        completed: 5,
        inProgress: 2,
        pending: 1,
        totalRevenue: 28500,
        totalCost: 14200,
        totalProfit: 14300,
      );
}

class FleetKpi {
  final double utilizationRate;
  final double onTimeRate;
  final double avgFuelEfficiency;
  final double avgDriverScore;
  final List<WeeklyRevenue> weeklyRevenue;

  FleetKpi({
    required this.utilizationRate,
    required this.onTimeRate,
    required this.avgFuelEfficiency,
    required this.avgDriverScore,
    required this.weeklyRevenue,
  });

  factory FleetKpi.mock() => FleetKpi(
        utilizationRate: 0.78,
        onTimeRate: 0.92,
        avgFuelEfficiency: 5.4,
        avgDriverScore: 87,
        weeklyRevenue: [
          WeeklyRevenue('จ', 22000, 11000),
          WeeklyRevenue('อ', 18000, 9500),
          WeeklyRevenue('พ', 25000, 13000),
          WeeklyRevenue('พฤ', 31000, 15500),
          WeeklyRevenue('ศ', 28500, 14200),
          WeeklyRevenue('ส', 15000, 8000),
          WeeklyRevenue('อา', 0, 0),
        ],
      );
}

class WeeklyRevenue {
  final String day;
  final double revenue;
  final double cost;
  WeeklyRevenue(this.day, this.revenue, this.cost);
}

class AlertItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final String severity;
  final DateTime createdAt;

  AlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
  });
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
    on<RefreshDashboard>(_onRefresh);
  }

  Future<void> _onLoad(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(RefreshDashboard event, Emitter<DashboardState> emit) async {
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<DashboardState> emit) async {
    try {
      // TODO: replace with real API call
      await Future.delayed(const Duration(milliseconds: 600));
      emit(DashboardLoaded(
        summary: DashboardSummary.mock(),
        todayTrips: TodayTrips.mock(),
        kpi: FleetKpi.mock(),
        recentAlerts: _mockAlerts(),
      ));
    } catch (e) {
      emit(DashboardError('โหลดข้อมูลไม่สำเร็จ: $e'));
    }
  }

  List<AlertItem> _mockAlerts() => [
        AlertItem(
          id: '1',
          type: 'insurance_expiry',
          title: 'ประกันภัยใกล้หมดอายุ',
          message: 'รถ กท-1234 ประกันหมดอายุ 15/03/2568 (เหลือ 30 วัน)',
          severity: 'warning',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        AlertItem(
          id: '2',
          type: 'maintenance_due',
          title: 'ถึงกำหนดเปลี่ยนน้ำมันเครื่อง',
          message: 'รถ ชม-5678 ครบ 10,000 กม. แล้ว',
          severity: 'warning',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        AlertItem(
          id: '3',
          type: 'act_due',
          title: 'พ.ร.บ. ใกล้หมดอายุ',
          message: 'รถ นค-9012 พ.ร.บ. หมดอายุ 01/04/2568 (เหลือ 1 วัน)',
          severity: 'critical',
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        AlertItem(
          id: '4',
          type: 'license_expiry',
          title: 'ใบขับขี่ใกล้หมดอายุ',
          message: 'คนขับ สมชาย ใจดี ใบขับขี่หมด 20/04/2568',
          severity: 'info',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
}
