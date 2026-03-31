import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fleet_core/models/partner_vehicle.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://bcfleet.satistang.com/api/v1/fleet';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class PartnerEvent {}

class LoadPartners extends PartnerEvent {}

class RefreshPartners extends PartnerEvent {}

class FindAvailablePartners extends PartnerEvent {
  final String zone;
  final String vehicleType;
  final DateTime date;
  FindAvailablePartners(
      {required this.zone, required this.vehicleType, required this.date});
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

  Future<void> _onFindAvailable(
      FindAvailablePartners event, Emitter<PartnerState> emit) async {
    emit(PartnerLoading());
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/partners/find-available'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'zone': event.zone,
          'vehicle_type': event.vehicleType,
          'date': event.date.toIso8601String(),
        }),
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final list = body['data'] as List? ?? [];
        final available = list
            .whereType<Map<String, dynamic>>()
            .map(PartnerVehicle.fromJson)
            .toList();
        emit(PartnerAvailableLoaded(available: available));
      } else {
        emit(PartnerError('ค้นหารถร่วมไม่สำเร็จ: ${response.statusCode}'));
      }
    } catch (e) {
      emit(PartnerError('ค้นหารถร่วมไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onRegister(RegisterPartner event, Emitter<PartnerState> emit) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/partners'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event.data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(PartnerActionSuccess('ลงทะเบียนรถร่วมสำเร็จ'));
        add(LoadPartners());
      } else {
        emit(PartnerError('ลงทะเบียนไม่สำเร็จ: ${response.statusCode}'));
      }
    } catch (e) {
      emit(PartnerError('ลงทะเบียนไม่สำเร็จ: $e'));
    }
  }

  Future<void> _fetchAndEmit(Emitter<PartnerState> emit) async {
    try {
      final response = await http.get(Uri.parse('$_apiBase/partners'));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final list = body['data'] as List? ?? [];
        final partners = list
            .whereType<Map<String, dynamic>>()
            .map(PartnerVehicle.fromJson)
            .toList();
        emit(PartnerLoaded(partners: partners));
      } else {
        emit(PartnerError('API error: ${response.statusCode}'));
      }
    } catch (e) {
      emit(PartnerError('โหลดข้อมูลรถร่วมไม่สำเร็จ: $e'));
    }
  }
}
