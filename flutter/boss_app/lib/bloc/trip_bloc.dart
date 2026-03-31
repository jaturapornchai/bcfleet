import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fleet_core/models/trip.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class TripEvent {}

class LoadTrips extends TripEvent {
  final String? statusFilter;
  final DateTime? dateFilter;
  LoadTrips({this.statusFilter, this.dateFilter});
}

class RefreshTrips extends TripEvent {}

class FilterTrips extends TripEvent {
  final String? status;
  FilterTrips({this.status});
}

class CreateTrip extends TripEvent {
  final Map<String, dynamic> data;
  CreateTrip(this.data);
}

class AssignTrip extends TripEvent {
  final String tripId;
  final String vehicleId;
  final String driverId;
  AssignTrip({required this.tripId, required this.vehicleId, required this.driverId});
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class TripState {}

class TripInitial extends TripState {}

class TripLoading extends TripState {}

class TripLoaded extends TripState {
  final List<Trip> trips;
  final String? activeFilter;

  TripLoaded({required this.trips, this.activeFilter});

  List<Trip> get filtered {
    if (activeFilter == null || activeFilter == 'all') return trips;
    if (activeFilter == 'today') {
      final today = DateTime.now();
      return trips.where((t) =>
        t.plannedStart != null &&
        t.plannedStart!.year == today.year &&
        t.plannedStart!.month == today.month &&
        t.plannedStart!.day == today.day,
      ).toList();
    }
    if (activeFilter == 'pending') {
      return trips.where((t) => t.status == 'pending' || t.status == 'draft').toList();
    }
    if (activeFilter == 'completed') {
      return trips.where((t) => t.status == 'completed').toList();
    }
    return trips.where((t) => t.status == activeFilter).toList();
  }
}

class TripError extends TripState {
  final String message;
  TripError(this.message);
}

class TripActionSuccess extends TripState {
  final String message;
  TripActionSuccess(this.message);
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class TripBloc extends Bloc<TripEvent, TripState> {
  TripBloc() : super(TripInitial()) {
    on<LoadTrips>(_onLoad);
    on<RefreshTrips>(_onRefresh);
    on<FilterTrips>(_onFilter);
    on<CreateTrip>(_onCreate);
    on<AssignTrip>(_onAssign);
  }

  Future<void> _onLoad(LoadTrips event, Emitter<TripState> emit) async {
    emit(TripLoading());
    await _fetchAndEmit(emit, event.statusFilter);
  }

  Future<void> _onRefresh(RefreshTrips event, Emitter<TripState> emit) async {
    final filter = state is TripLoaded ? (state as TripLoaded).activeFilter : null;
    await _fetchAndEmit(emit, filter);
  }

  Future<void> _onFilter(FilterTrips event, Emitter<TripState> emit) async {
    if (state is TripLoaded) {
      final current = state as TripLoaded;
      emit(TripLoaded(trips: current.trips, activeFilter: event.status));
    }
  }

  Future<void> _onCreate(CreateTrip event, Emitter<TripState> emit) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      emit(TripActionSuccess('สร้างเที่ยววิ่งสำเร็จ'));
      add(LoadTrips());
    } catch (e) {
      emit(TripError('สร้างเที่ยววิ่งไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onAssign(AssignTrip event, Emitter<TripState> emit) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      emit(TripActionSuccess('มอบหมายงานสำเร็จ'));
      add(LoadTrips());
    } catch (e) {
      emit(TripError('มอบหมายงานไม่สำเร็จ: $e'));
    }
  }

  Future<void> _fetchAndEmit(Emitter<TripState> emit, String? filter) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(TripLoaded(trips: _mockTrips(), activeFilter: filter));
    } catch (e) {
      emit(TripError('โหลดเที่ยววิ่งไม่สำเร็จ: $e'));
    }
  }

  List<Trip> _mockTrips() {
    final now = DateTime.now();
    return [
      Trip(
        id: 't1', shopId: 's1', tripNo: 'TRIP-2568-0001',
        status: 'in_progress', vehicleId: 'v1', driverId: 'd1',
        originName: 'คลังสินค้า ABC เชียงใหม่',
        destinationCount: 1,
        cargoDescription: 'ปูนซีเมนต์ 200 ถุง',
        cargoWeightKg: 10000,
        plannedStart: now.subtract(const Duration(hours: 2)),
        plannedEnd: now.add(const Duration(hours: 2)),
        actualStart: now.subtract(const Duration(hours: 2)),
        distanceKm: 45.5,
        revenue: 2500, totalCost: 1160, profit: 1340,
        createdAt: now, updatedAt: now,
      ),
      Trip(
        id: 't2', shopId: 's1', tripNo: 'TRIP-2568-0002',
        status: 'completed', vehicleId: 'v2', driverId: 'd2',
        originName: 'โรงงาน XYZ ลำปาง',
        destinationCount: 2,
        cargoDescription: 'เหล็กเส้น 5 ตัน',
        cargoWeightKg: 5000,
        plannedStart: now.subtract(const Duration(hours: 6)),
        plannedEnd: now.subtract(const Duration(hours: 1)),
        actualStart: now.subtract(const Duration(hours: 6)),
        actualEnd: now.subtract(const Duration(hours: 1)),
        distanceKm: 98.0,
        revenue: 4500, totalCost: 2800, profit: 1700,
        hasPod: true,
        createdAt: now, updatedAt: now,
      ),
      Trip(
        id: 't3', shopId: 's1', tripNo: 'TRIP-2568-0003',
        status: 'pending', vehicleId: null, driverId: null,
        originName: 'ท่าเรือเชียงแสน',
        destinationCount: 1,
        cargoDescription: 'สินค้าอิเล็กทรอนิกส์',
        cargoWeightKg: 800,
        plannedStart: now.add(const Duration(hours: 4)),
        plannedEnd: now.add(const Duration(hours: 10)),
        revenue: 3200,
        createdAt: now, updatedAt: now,
      ),
      Trip(
        id: 't4', shopId: 's1', tripNo: 'TRIP-2568-0004',
        status: 'completed', vehicleId: 'v4', driverId: 'd3',
        originName: 'คลังสินค้า DEF เชียงราย',
        destinationCount: 3,
        cargoDescription: 'ผลไม้สด 2 ตัน',
        cargoWeightKg: 2000,
        plannedStart: now.subtract(const Duration(hours: 10)),
        plannedEnd: now.subtract(const Duration(hours: 4)),
        actualEnd: now.subtract(const Duration(hours: 4)),
        distanceKm: 180.0,
        revenue: 6800, totalCost: 4100, profit: 2700,
        hasPod: true,
        createdAt: now, updatedAt: now,
      ),
    ];
  }
}
