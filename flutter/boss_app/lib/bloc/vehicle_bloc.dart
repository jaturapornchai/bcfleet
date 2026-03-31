import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fleet_core/models/vehicle.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class VehicleEvent {}

class LoadVehicles extends VehicleEvent {
  final String? statusFilter; // null = ทั้งหมด
  LoadVehicles({this.statusFilter});
}

class RefreshVehicles extends VehicleEvent {}

class FilterVehicles extends VehicleEvent {
  final String? status;
  FilterVehicles({this.status});
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class VehicleState {}

class VehicleInitial extends VehicleState {}

class VehicleLoading extends VehicleState {}

class VehicleLoaded extends VehicleState {
  final List<Vehicle> vehicles;
  final String? activeFilter;

  VehicleLoaded({required this.vehicles, this.activeFilter});

  List<Vehicle> get filtered {
    if (activeFilter == null || activeFilter == 'all') return vehicles;
    return vehicles.where((v) => v.status == activeFilter).toList();
  }
}

class VehicleError extends VehicleState {
  final String message;
  VehicleError(this.message);
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  VehicleBloc() : super(VehicleInitial()) {
    on<LoadVehicles>(_onLoad);
    on<RefreshVehicles>(_onRefresh);
    on<FilterVehicles>(_onFilter);
  }

  Future<void> _onLoad(LoadVehicles event, Emitter<VehicleState> emit) async {
    emit(VehicleLoading());
    await _fetchAndEmit(emit, event.statusFilter);
  }

  Future<void> _onRefresh(RefreshVehicles event, Emitter<VehicleState> emit) async {
    final current = state is VehicleLoaded ? (state as VehicleLoaded).activeFilter : null;
    await _fetchAndEmit(emit, current);
  }

  Future<void> _onFilter(FilterVehicles event, Emitter<VehicleState> emit) async {
    if (state is VehicleLoaded) {
      final current = state as VehicleLoaded;
      emit(VehicleLoaded(vehicles: current.vehicles, activeFilter: event.status));
    }
  }

  Future<void> _fetchAndEmit(Emitter<VehicleState> emit, String? filter) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(VehicleLoaded(vehicles: _mockVehicles(), activeFilter: filter));
    } catch (e) {
      emit(VehicleError('โหลดข้อมูลรถไม่สำเร็จ: $e'));
    }
  }

  List<Vehicle> _mockVehicles() {
    final now = DateTime.now();
    return [
      Vehicle(
        id: 'v1', shopId: 's1', plate: 'กท-1234', brand: 'ISUZU',
        model: 'FRR 210', type: '6ล้อ', year: 2023, color: 'ขาว',
        fuelType: 'ดีเซล', maxWeightKg: 6000, ownership: 'own',
        status: 'active', currentDriverId: 'd1', mileageKm: 85000,
        healthStatus: 'green',
        insuranceExpiry: now.add(const Duration(days: 30)),
        createdAt: now, updatedAt: now,
      ),
      Vehicle(
        id: 'v2', shopId: 's1', plate: 'ชม-5678', brand: 'HINO',
        model: '500', type: '10ล้อ', year: 2021, color: 'แดง',
        fuelType: 'ดีเซล', maxWeightKg: 15000, ownership: 'own',
        status: 'active', currentDriverId: 'd2', mileageKm: 120000,
        healthStatus: 'yellow',
        taxDueDate: now.add(const Duration(days: 15)),
        createdAt: now, updatedAt: now,
      ),
      Vehicle(
        id: 'v3', shopId: 's1', plate: 'นค-9012', brand: 'TOYOTA',
        model: 'Revo', type: 'กระบะ', year: 2022, color: 'เทา',
        fuelType: 'ดีเซล', maxWeightKg: 1000, ownership: 'own',
        status: 'maintenance', mileageKm: 45000,
        healthStatus: 'red',
        actDueDate: now.add(const Duration(days: 1)),
        createdAt: now, updatedAt: now,
      ),
      Vehicle(
        id: 'v4', shopId: 's1', plate: 'พย-3456', brand: 'ISUZU',
        model: 'NKR', type: '4ล้อ', year: 2020, color: 'น้ำเงิน',
        fuelType: 'ดีเซล', maxWeightKg: 3000, ownership: 'own',
        status: 'active', currentDriverId: 'd3', mileageKm: 98000,
        healthStatus: 'green',
        createdAt: now, updatedAt: now,
      ),
    ];
  }
}
