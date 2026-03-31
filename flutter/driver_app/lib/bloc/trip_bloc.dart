import 'package:flutter_bloc/flutter_bloc.dart';

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
      // TODO: เรียก API จริง — ตอนนี้ใช้ข้อมูลจำลอง
      await Future.delayed(const Duration(milliseconds: 800));
      final mockTrips = _mockTrips();
      emit(TripLoaded(mockTrips));
    } catch (e) {
      emit(TripError('โหลดข้อมูลไม่สำเร็จ: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateStatus(
      UpdateTripStatus event, Emitter<TripState> emit) async {
    final current = state;
    if (current is! TripLoaded) return;
    try {
      // TODO: เรียก API PUT /fleet/trips/:id/status
      final updated = current.trips.map((t) {
        if (t['id'] == event.tripId) {
          return {...t, 'status': event.newStatus};
        }
        return t;
      }).toList();
      emit(TripLoaded(updated));
    } catch (e) {
      emit(TripError('อัปเดตสถานะไม่สำเร็จ'));
    }
  }

  Future<void> _onAcceptTrip(
      AcceptTrip event, Emitter<TripState> emit) async {
    add(UpdateTripStatus(tripId: event.tripId, newStatus: 'accepted'));
  }

  List<Map<String, dynamic>> _mockTrips() => [
        {
          'id': 'trip_001',
          'trip_no': 'TRIP-2026-000001',
          'status': 'pending',
          'origin_name': 'คลังสินค้า ABC เชียงใหม่',
          'destination_name': 'ร้าน XYZ วัสดุ ลำพูน',
          'cargo_description': 'ปูนซีเมนต์ 200 ถุง',
          'cargo_weight_kg': 10000,
          'distance_km': 45.0,
          'planned_start': '2026-03-31T06:00:00',
          'planned_end': '2026-03-31T12:00:00',
          'revenue': 2500.0,
        },
        {
          'id': 'trip_002',
          'trip_no': 'TRIP-2026-000002',
          'status': 'started',
          'origin_name': 'โรงงาน DEF ลำปาง',
          'destination_name': 'ห้างสรรพสินค้า GHI เชียงราย',
          'cargo_description': 'เฟอร์นิเจอร์ 50 ชิ้น',
          'cargo_weight_kg': 3500,
          'distance_km': 120.0,
          'planned_start': '2026-03-31T08:00:00',
          'planned_end': '2026-03-31T14:00:00',
          'revenue': 4500.0,
        },
        {
          'id': 'trip_003',
          'trip_no': 'TRIP-2026-000003',
          'status': 'completed',
          'origin_name': 'ท่าเรือ A เชียงใหม่',
          'destination_name': 'คลังสินค้า B ลำพูน',
          'cargo_description': 'อาหารแห้ง 500 กล่อง',
          'cargo_weight_kg': 8000,
          'distance_km': 30.0,
          'planned_start': '2026-03-31T04:00:00',
          'planned_end': '2026-03-31T08:00:00',
          'revenue': 1800.0,
        },
      ];
}
