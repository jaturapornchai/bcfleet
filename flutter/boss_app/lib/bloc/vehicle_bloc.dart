import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fleet_core/models/vehicle.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://smlfleet.satistang.com/api/v1/fleet';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class VehicleEvent {}

class LoadVehicles extends VehicleEvent {
  final String? statusFilter;
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
      final uri = Uri.parse('$_apiBase/vehicles');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final list = body['data'] as List? ?? [];
        final vehicles = list
            .whereType<Map<String, dynamic>>()
            .map(Vehicle.fromJson)
            .toList();
        emit(VehicleLoaded(vehicles: vehicles, activeFilter: filter));
      } else {
        emit(VehicleError('API error: ${response.statusCode}'));
      }
    } catch (e) {
      emit(VehicleError('โหลดข้อมูลรถไม่สำเร็จ: $e'));
    }
  }
}
