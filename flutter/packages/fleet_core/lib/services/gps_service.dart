import 'api_client.dart';

/// GPSService — จัดการ GPS tracking
class GPSService {
  final FleetApiClient _api;

  GPSService(this._api);

  /// ส่ง GPS location จาก driver app
  Future<void> sendLocation({
    required String tripId,
    required double lat,
    required double lng,
    required double speed,
    required double heading,
    required double accuracy,
    required int battery,
  }) async {
    await _api.post('/fleet/gps/location', data: {
      'trip_id': tripId,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'heading': heading,
      'accuracy': accuracy,
      'battery': battery,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// ดึงตำแหน่งรถทุกคัน real-time
  Future<List<Map<String, dynamic>>> getAllVehicleLocations() async {
    final response = await _api.get('/fleet/gps/vehicles');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  /// ดึงเส้นทางย้อนหลังของรถ
  Future<List<Map<String, dynamic>>> getTrail(String vehicleId, {DateTime? from, DateTime? to}) async {
    final response = await _api.get('/fleet/gps/vehicle/$vehicleId/trail', queryParams: {
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    });
    return (response.data as List).cast<Map<String, dynamic>>();
  }
}
