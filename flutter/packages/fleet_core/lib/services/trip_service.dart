import '../models/trip.dart';
import 'api_client.dart';

/// TripService — จัดการเที่ยววิ่ง
class TripService {
  final FleetApiClient _api;

  TripService(this._api);

  /// ดึงรายการเที่ยววิ่ง
  Future<(List<Trip>, int)> list({
    String? status,
    String? driverId,
    String? vehicleId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get('/fleet/trips', queryParams: {
      if (status != null) 'status': status,
      if (driverId != null) 'driver_id': driverId,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
      if (dateTo != null) 'date_to': dateTo.toIso8601String(),
      'page': page,
      'limit': limit,
    });
    final trips = (response.data as List).map((e) => Trip.fromJson(e)).toList();
    return (trips, response.total ?? 0);
  }

  /// ดึงเที่ยววิ่ง by ID
  Future<Trip> getById(String id) async {
    final response = await _api.get('/fleet/trips/$id');
    return Trip.fromJson(response.data);
  }

  /// สร้างเที่ยววิ่งใหม่
  Future<Trip> create(Map<String, dynamic> data) async {
    final response = await _api.post('/fleet/trips', data: data);
    return Trip.fromJson(response.data);
  }

  /// เปลี่ยนสถานะเที่ยววิ่ง
  Future<void> updateStatus(String id, String status) async {
    await _api.put('/fleet/trips/$id/status', data: {'status': status});
  }

  /// มอบหมายคนขับ + รถ
  Future<void> assign(String id, String vehicleId, String driverId) async {
    await _api.post('/fleet/trips/$id/assign', data: {
      'vehicle_id': vehicleId,
      'driver_id': driverId,
    });
  }

  /// อัปโหลด POD
  Future<void> uploadPod(String id, String photoPath) async {
    await _api.upload('/fleet/trips/$id/pod', photoPath);
  }
}
