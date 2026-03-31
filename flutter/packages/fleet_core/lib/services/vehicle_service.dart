import '../models/vehicle.dart';
import 'api_client.dart';

/// VehicleService — จัดการรถขนส่ง
class VehicleService {
  final FleetApiClient _api;

  VehicleService(this._api);

  /// ดึงรายการรถ
  Future<(List<Vehicle>, int)> list({String? status, String? type, int page = 1, int limit = 20}) async {
    final response = await _api.get('/fleet/vehicles', queryParams: {
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      'page': page,
      'limit': limit,
    });
    final vehicles = (response.data as List).map((e) => Vehicle.fromJson(e)).toList();
    return (vehicles, response.total ?? 0);
  }

  /// ดึงข้อมูลรถ by ID
  Future<Vehicle> getById(String id) async {
    final response = await _api.get('/fleet/vehicles/$id');
    return Vehicle.fromJson(response.data);
  }

  /// สร้างรถใหม่
  Future<Vehicle> create(Map<String, dynamic> data) async {
    final response = await _api.post('/fleet/vehicles', data: data);
    return Vehicle.fromJson(response.data);
  }

  /// อัปเดตรถ
  Future<Vehicle> update(String id, Map<String, dynamic> data) async {
    final response = await _api.put('/fleet/vehicles/$id', data: data);
    return Vehicle.fromJson(response.data);
  }

  /// ลบรถ (soft delete)
  Future<void> delete(String id) async {
    await _api.delete('/fleet/vehicles/$id');
  }

  /// ดึงสถานะสุขภาพรถ
  Future<Map<String, dynamic>> getHealth(String id) async {
    final response = await _api.get('/fleet/vehicles/$id/health');
    return response.data;
  }
}
