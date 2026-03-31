import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ──────────────────────────────────────────────
abstract class GpsEvent {}

class StartTracking extends GpsEvent {
  final String tripId;
  StartTracking({required this.tripId});
}

class StopTracking extends GpsEvent {}

class GpsLocationUpdated extends GpsEvent {
  final double lat;
  final double lng;
  final double speed;
  GpsLocationUpdated({required this.lat, required this.lng, required this.speed});
}

// ── States ──────────────────────────────────────────────
abstract class GpsState {}

class GpsIdle extends GpsState {}

class GpsTracking extends GpsState {
  final String tripId;
  final double? lat;
  final double? lng;
  final double? speed;
  GpsTracking({required this.tripId, this.lat, this.lng, this.speed});
}

class GpsError extends GpsState {
  final String message;
  GpsError(this.message);
}

// ── BLoC ────────────────────────────────────────────────
class GpsBloc extends Bloc<GpsEvent, GpsState> {
  GpsBloc() : super(GpsIdle()) {
    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
    on<GpsLocationUpdated>(_onLocationUpdated);
  }

  Future<void> _onStartTracking(
      StartTracking event, Emitter<GpsState> emit) async {
    emit(GpsTracking(tripId: event.tripId));
    // BackgroundGPSService.instance.startTracking(event.tripId) — เรียกจาก UI layer
  }

  Future<void> _onStopTracking(
      StopTracking event, Emitter<GpsState> emit) async {
    emit(GpsIdle());
    // BackgroundGPSService.instance.stopTracking()
  }

  Future<void> _onLocationUpdated(
      GpsLocationUpdated event, Emitter<GpsState> emit) async {
    final current = state;
    if (current is GpsTracking) {
      emit(GpsTracking(
        tripId: current.tripId,
        lat: event.lat,
        lng: event.lng,
        speed: event.speed,
      ));
    }
  }
}
