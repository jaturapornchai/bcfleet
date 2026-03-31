import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://bcfleet.satistang.com/api/v1/fleet';

// ── Events ──────────────────────────────────────────────
abstract class TripEvent {}

class LoadTrips extends TripEvent {}

class UpdateTripStatus extends TripEvent {
  final String tripId;
  final String newStatus;
  UpdateTripStatus({required this.tripId, required this.newStatus});
}

class AcceptTrip extends TripEvent {
  final String tripId;
  AcceptTrip({required this.tripId});
}

// ── States ──────────────────────────────────────────────
abstract class TripState {}

class TripLoading extends TripState {}

class TripLoaded extends TripState {
  final List<Map<String, dynamic>> trips;
  TripLoaded(this.trips);
}

class TripError extends TripState {
  final String message;
  TripError(this.message);
}

// ── BLoC ────────────────────────────────────────────────
class TripBloc extends Bloc<TripEvent, TripState> {
  TripBloc() : super(TripLoading()) {
    on<LoadTrips>(_onLoadTrips);
    on<UpdateTripStatus>(_onUpdateStatus);
    on<AcceptTrip>(_onAcceptTrip);
  }

  Future<void> _onLoadTrips(LoadTrips event, Emitter<TripState> emit) async {
    emit(TripLoading());
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/trips?limit=50'),
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data =
            (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        emit(TripLoaded(data));
      } else {
        emit(TripError('API error: ${response.statusCode}'));
      }
    } catch (e) {
      emit(TripError('เชื่อมต่อ API ไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onUpdateStatus(
      UpdateTripStatus event, Emitter<TripState> emit) async {
    final current = state;
    if (current is! TripLoaded) return;
    try {
      final response = await http.put(
        Uri.parse('$_apiBase/trips/${event.tripId}/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': event.newStatus}),
      );
      if (response.statusCode == 200) {
        final updated = current.trips.map((t) {
          if (t['id'] == event.tripId) {
            return {...t, 'status': event.newStatus};
          }
          return t;
        }).toList();
        emit(TripLoaded(updated));
      } else {
        emit(TripError('อัปเดตสถานะไม่สำเร็จ: ${response.statusCode}'));
      }
    } catch (e) {
      emit(TripError('อัปเดตสถานะไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onAcceptTrip(
      AcceptTrip event, Emitter<TripState> emit) async {
    add(UpdateTripStatus(tripId: event.tripId, newStatus: 'accepted'));
  }
}
