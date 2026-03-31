import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://bcfleet.satistang.com/api/v1/fleet';

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

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        totalVehicles: (json['total_vehicles'] ?? json['totalVehicles'] ?? 0) as int,
        activeVehicles: (json['active_vehicles'] ?? json['activeVehicles'] ?? 0) as int,
        vehiclesInMaintenance:
            (json['vehicles_in_maintenance'] ?? json['vehiclesInMaintenance'] ?? 0) as int,
        criticalVehicles: (json['critical_vehicles'] ?? json['criticalVehicles'] ?? 0) as int,
        warningVehicles: (json['warning_vehicles'] ?? json['warningVehicles'] ?? 0) as int,
        totalDrivers: (json['total_drivers'] ?? json['totalDrivers'] ?? 0) as int,
        activeDrivers: (json['active_drivers'] ?? json['activeDrivers'] ?? 0) as int,
        activeAlerts: (json['active_alerts'] ?? json['activeAlerts'] ?? 0) as int,
      );

  factory DashboardSummary.empty() => DashboardSummary(
        totalVehicles: 0,
        activeVehicles: 0,
        vehiclesInMaintenance: 0,
        criticalVehicles: 0,
        warningVehicles: 0,
        totalDrivers: 0,
        activeDrivers: 0,
        activeAlerts: 0,
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

  factory TodayTrips.fromJson(Map<String, dynamic> json) => TodayTrips(
        total: (json['total'] ?? 0) as int,
        completed: (json['completed'] ?? 0) as int,
        inProgress: (json['in_progress'] ?? json['inProgress'] ?? 0) as int,
        pending: (json['pending'] ?? 0) as int,
        totalRevenue:
            ((json['total_revenue'] ?? json['totalRevenue'] ?? 0) as num).toDouble(),
        totalCost: ((json['total_cost'] ?? json['totalCost'] ?? 0) as num).toDouble(),
        totalProfit: ((json['total_profit'] ?? json['totalProfit'] ?? 0) as num).toDouble(),
      );

  factory TodayTrips.empty() => TodayTrips(
        total: 0,
        completed: 0,
        inProgress: 0,
        pending: 0,
        totalRevenue: 0,
        totalCost: 0,
        totalProfit: 0,
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

  factory FleetKpi.fromJson(Map<String, dynamic> json) {
    final weeklyRaw = json['weekly_revenue'] ?? json['weeklyRevenue'];
    final weekly = weeklyRaw is List ? weeklyRaw : [];
    return FleetKpi(
      utilizationRate:
          ((json['utilization_rate'] ?? json['utilizationRate'] ?? 0) as num).toDouble(),
      onTimeRate: ((json['on_time_rate'] ?? json['onTimeRate'] ?? 0) as num).toDouble(),
      avgFuelEfficiency:
          ((json['avg_fuel_efficiency'] ?? json['avgFuelEfficiency'] ?? 0) as num).toDouble(),
      avgDriverScore:
          ((json['avg_driver_score'] ?? json['avgDriverScore'] ?? 0) as num).toDouble(),
      weeklyRevenue: weekly
          .map((e) => WeeklyRevenue(
                (e as Map<String, dynamic>)['day']?.toString() ?? '',
                ((e['revenue'] ?? 0) as num).toDouble(),
                ((e['cost'] ?? 0) as num).toDouble(),
              ))
          .toList(),
    );
  }

  factory FleetKpi.empty() => FleetKpi(
        utilizationRate: 0,
        onTimeRate: 0,
        avgFuelEfficiency: 0,
        avgDriverScore: 0,
        weeklyRevenue: [],
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

  factory AlertItem.fromJson(Map<String, dynamic> json) => AlertItem(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        severity: json['severity']?.toString() ?? 'info',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
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
      final results = await Future.wait([
        http.get(Uri.parse('$_apiBase/dashboard/summary')),
        http.get(Uri.parse('$_apiBase/dashboard/kpi')),
        http.get(Uri.parse('$_apiBase/dashboard/alerts')),
      ]);

      final summaryRes = results[0];
      final kpiRes = results[1];
      final alertsRes = results[2];

      DashboardSummary summary = DashboardSummary.empty();
      TodayTrips todayTrips = TodayTrips.empty();
      FleetKpi kpi = FleetKpi.empty();
      List<AlertItem> recentAlerts = [];

      if (summaryRes.statusCode == 200) {
        final body = json.decode(summaryRes.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          final summaryMap = data['summary'];
          summary = DashboardSummary.fromJson(
            summaryMap is Map<String, dynamic> ? summaryMap : data,
          );
          final todayMap = data['today_trips'] ?? data['todayTrips'];
          if (todayMap is Map<String, dynamic>) {
            todayTrips = TodayTrips.fromJson(todayMap);
          }
        }
      }

      if (kpiRes.statusCode == 200) {
        final body = json.decode(kpiRes.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          kpi = FleetKpi.fromJson(data);
        }
      }

      if (alertsRes.statusCode == 200) {
        final body = json.decode(alertsRes.body) as Map<String, dynamic>;
        final list = body['data'];
        if (list is List) {
          recentAlerts = list
              .take(5)
              .whereType<Map<String, dynamic>>()
              .map(AlertItem.fromJson)
              .toList();
        }
      }

      emit(DashboardLoaded(
        summary: summary,
        todayTrips: todayTrips,
        kpi: kpi,
        recentAlerts: recentAlerts,
      ));
    } catch (e) {
      emit(DashboardError('โหลดข้อมูลไม่สำเร็จ: $e'));
    }
  }
}
