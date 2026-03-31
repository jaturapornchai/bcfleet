import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fleet_core/models/partner_vehicle.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class PartnerEvent {}

class LoadPartners extends PartnerEvent {}

class RefreshPartners extends PartnerEvent {}

class FindAvailablePartners extends PartnerEvent {
  final String zone;
  final String vehicleType;
  final DateTime date;
  FindAvailablePartners({required this.zone, required this.vehicleType, required this.date});
}

class RegisterPartner extends PartnerEvent {
  final Map<String, dynamic> data;
  RegisterPartner(this.data);
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class PartnerState {}

class PartnerInitial extends PartnerState {}

class PartnerLoading extends PartnerState {}

class PartnerLoaded extends PartnerState {
  final List<PartnerVehicle> partners;
  PartnerLoaded({required this.partners});
}

class PartnerAvailableLoaded extends PartnerState {
  final List<PartnerVehicle> available;
  PartnerAvailableLoaded({required this.available});
}

class PartnerError extends PartnerState {
  final String message;
  PartnerError(this.message);
}

class PartnerActionSuccess extends PartnerState {
  final String message;
  PartnerActionSuccess(this.message);
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class PartnerBloc extends Bloc<PartnerEvent, PartnerState> {
  PartnerBloc() : super(PartnerInitial()) {
    on<LoadPartners>(_onLoad);
    on<RefreshPartners>(_onRefresh);
    on<FindAvailablePartners>(_onFindAvailable);
    on<RegisterPartner>(_onRegister);
  }

  Future<void> _onLoad(LoadPartners event, Emitter<PartnerState> emit) async {
    emit(PartnerLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(RefreshPartners event, Emitter<PartnerState> emit) async {
    await _fetchAndEmit(emit);
  }

  Future<void> _onFindAvailable(FindAvailablePartners event, Emitter<PartnerState> emit) async {
    emit(PartnerLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final all = _mockPartners();
      final available = all.where((p) =>
        p.status == 'active' &&
        (p.vehicleType == event.vehicleType || event.vehicleType == 'all'),
      ).toList();
      emit(PartnerAvailableLoaded(available: available));
    } catch (e) {
      emit(PartnerError('ค้นหารถร่วมไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onRegister(RegisterPartner event, Emitter<PartnerState> emit) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(PartnerActionSuccess('ลงทะเบียนรถร่วมสำเร็จ'));
      add(LoadPartners());
    } catch (e) {
      emit(PartnerError('ลงทะเบียนไม่สำเร็จ: $e'));
    }
  }

  Future<void> _fetchAndEmit(Emitter<PartnerState> emit) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(PartnerLoaded(partners: _mockPartners()));
    } catch (e) {
      emit(PartnerError('โหลดข้อมูลรถร่วมไม่สำเร็จ: $e'));
    }
  }

  List<PartnerVehicle> _mockPartners() {
    final now = DateTime.now();
    return [
      PartnerVehicle(
        id: 'p1', shopId: 's1',
        ownerName: 'นายสมหมาย รถเยอะ',
        ownerCompany: 'บจก.ขนส่งสมหมาย',
        ownerPhone: '081-456-7890',
        plate: '2กร-5678',
        vehicleType: '10ล้อ',
        maxWeightKg: 15000,
        pricingModel: 'per_trip',
        baseRate: 3000,
        rating: 4.5,
        totalTrips: 35,
        status: 'active',
        createdAt: now, updatedAt: now,
      ),
      PartnerVehicle(
        id: 'p2', shopId: 's1',
        ownerName: 'นายวิชัย ขนส่งดี',
        ownerPhone: '089-567-8901',
        plate: '3กข-1234',
        vehicleType: '6ล้อ',
        maxWeightKg: 6000,
        pricingModel: 'per_km',
        baseRate: 1500,
        perKmRate: 15,
        rating: 4.8,
        totalTrips: 62,
        status: 'active',
        createdAt: now, updatedAt: now,
      ),
      PartnerVehicle(
        id: 'p3', shopId: 's1',
        ownerName: 'นางสาวมาลี โลจิสติกส์',
        ownerCompany: 'หจก.มาลีขนส่ง',
        ownerPhone: '082-345-6789',
        plate: '4นก-9876',
        vehicleType: 'หัวลาก',
        maxWeightKg: 25000,
        pricingModel: 'per_trip',
        baseRate: 8000,
        rating: 4.2,
        totalTrips: 18,
        status: 'active',
        createdAt: now, updatedAt: now,
      ),
    ];
  }
}
