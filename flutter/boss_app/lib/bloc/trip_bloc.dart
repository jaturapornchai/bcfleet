import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fleet_core/models/trip.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://smlfleet.satistang.com/api/v1/fleet';

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
      final response = await http.post(
        Uri.parse('$_apiBase/trips'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event.data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(TripActionSuccess('สร้างเที่ยววิ่งสำเร็จ'));
        add(LoadTrips());
      } else {
        emit(TripError('สร้างเที่ยววิ่งไม่สำเร็จ: ${response.statusCode}'));
      }
    } catch (e) {
      emit(TripError('สร้างเที่ยววิ่งไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onAssign(AssignTrip event, Emitter<TripState> emit) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/trips/${event.tripId}/assign'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'vehicle_id': event.vehicleId,
          'driver_id': event.driverId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(TripActionSuccess('มอบหมายงานสำเร็จ'));
        add(LoadTrips());
      } else {
        emit(TripError('มอบหมายงานไม่สำเร็จ: ${response.statusCode}'));
      }
    } catch (e) {
      emit(TripError('มอบหมายงานไม่สำเร็จ: $e'));
    }
  }

  Future<void> _fetchAndEmit(Emitter<TripState> emit, String? filter) async {
    try {
      final response = await http.get(Uri.parse('$_apiBase/trips'));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final list = body['data'] as List? ?? [];
        final trips = list
            .whereType<Map<String, dynamic>>()
            .map(Trip.fromJson)
            .toList();
        emit(TripLoaded(trips: trips, activeFilter: filter));
      } else {
        emit(TripError('API error: ${response.statusCode}'));
      }
    } catch (e) {
      emit(TripError('โหลดเที่ยววิ่งไม่สำเร็จ: $e'));
    }
  }
}
