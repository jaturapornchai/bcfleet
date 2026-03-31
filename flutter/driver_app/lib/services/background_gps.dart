import 'dart:async';
import 'package:flutter/foundation.dart';

/// Background GPS tracking service
/// ส่งตำแหน่ง GPS ทุก 30 วินาทีระหว่างที่มีเที่ยววิ่ง in_progress
class BackgroundGpsService {
  static final BackgroundGpsService _instance =
      BackgroundGpsService._internal();
  factory BackgroundGpsService() => _instance;
  BackgroundGpsService._internal();

  Timer? _timer;
  String? _activeTripId;
  bool _isTracking = false;

  bool get isTracking => _isTracking;
  String? get activeTripId => _activeTripId;

  /// เริ่ม tracking สำหรับ tripId ที่กำหนด
  void startTracking(String tripId, {VoidCallback? onTick}) {
    if (_isTracking && _activeTripId == tripId) {
      debugPrint('[GPS] Already tracking trip $tripId');
      return;
    }

    stopTracking(); // หยุด trip เดิมถ้ามี

    _activeTripId = tripId;
    _isTracking = true;

    debugPrint('[GPS] Started tracking trip $tripId');

    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _sendLocation(tripId);
      onTick?.call();
    });

    // ส่งทันทีตอนเริ่ม
    _sendLocation(tripId);
  }

  /// หยุด tracking
  void stopTracking() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      debugPrint('[GPS] Stopped tracking trip $_activeTripId');
    }
    _activeTripId = null;
    _isTracking = false;
  }

  /// ส่งตำแหน่งไป API
  Future<void> _sendLocation(String tripId) async {
    try {
      final position = await _getCurrentPosition();

      debugPrint(
        '[GPS] Sending location for trip $tripId: '
        'lat=${position['lat']}, lng=${position['lng']}, '
        'speed=${position['speed']}',
      );

      // TODO: เรียก API จริง
      // await ApiClient.instance.post('/fleet/gps/location', {
      //   'trip_id': tripId,
      //   'lat': position['lat'],
      //   'lng': position['lng'],
      //   'speed': position['speed'],
      //   'heading': position['heading'],
      //   'accuracy': position['accuracy'],
      //   'timestamp': DateTime.now().toIso8601String(),
      // });
    } catch (e) {
      debugPrint('[GPS] Error sending location: $e');
      // Buffer ไว้ใน offline_sync ถ้า network ล้มเหลว
    }
  }

  /// รับตำแหน่ง GPS ปัจจุบัน
  /// ในโปรดักชันใช้ geolocator package
  Future<Map<String, dynamic>> _getCurrentPosition() async {
    // Mock position — ในระบบจริงใช้ Geolocator.getCurrentPosition()
    // final position = await Geolocator.getCurrentPosition(
    //   desiredAccuracy: LocationAccuracy.high,
    // );
    return {
      'lat': 18.7883 + (DateTime.now().millisecond * 0.000001),
      'lng': 98.9853 + (DateTime.now().millisecond * 0.000001),
      'speed': 65.0,
      'heading': 180.0,
      'accuracy': 10.0,
    };
  }

  /// ขอ permission GPS (เรียกก่อน startTracking)
  Future<bool> requestPermission() async {
    // TODO: ใช้ geolocator package
    // final permission = await Geolocator.requestPermission();
    // return permission == LocationPermission.always ||
    //        permission == LocationPermission.whileInUse;
    debugPrint('[GPS] Permission granted (mock)');
    return true;
  }

  /// ตรวจสอบว่า GPS เปิดอยู่หรือไม่
  Future<bool> isLocationServiceEnabled() async {
    // TODO: ใช้ geolocator package
    // return await Geolocator.isLocationServiceEnabled();
    return true;
  }

  void dispose() {
    stopTracking();
  }
}
