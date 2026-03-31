import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Offline Sync Service
/// เก็บข้อมูลที่ยังส่งไม่ได้ไว้ใน local buffer
/// แล้ว sync ขึ้น API เมื่อกลับมา online
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  // In-memory queue (ในระบบจริงใช้ SQLite หรือ ObjectBox)
  final List<Map<String, dynamic>> _pendingQueue = [];
  bool _isOnline = true;
  bool _isSyncing = false;
  Timer? _syncTimer;

  bool get isOnline => _isOnline;
  int get pendingCount => _pendingQueue.length;

  /// เริ่ม service — ตรวจสอบ connectivity และ sync ทุก 30 วินาที
  void start() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivityAndSync();
    });
    debugPrint('[OfflineSync] Service started');
  }

  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('[OfflineSync] Service stopped');
  }

  /// เพิ่มข้อมูลเข้า queue (เรียกเมื่อ network ล้มเหลว)
  Future<void> enqueue({
    required String type,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type,
      'endpoint': endpoint,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    };

    _pendingQueue.add(entry);

    // TODO: persist ลง SQLite
    // await _db.insert('offline_queue', entry);

    debugPrint('[OfflineSync] Enqueued: $type (queue size: ${_pendingQueue.length})');
  }

  /// บันทึก GPS point เมื่อ offline
  Future<void> enqueueGpsPoint({
    required String tripId,
    required double lat,
    required double lng,
    required double speed,
    required double heading,
  }) async {
    await enqueue(
      type: 'gps_location',
      endpoint: '/fleet/gps/location',
      payload: {
        'trip_id': tripId,
        'lat': lat,
        'lng': lng,
        'speed': speed,
        'heading': heading,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// บันทึก expense เมื่อ offline
  Future<void> enqueueExpense(Map<String, dynamic> expenseData) async {
    await enqueue(
      type: 'expense',
      endpoint: '/fleet/expenses',
      payload: expenseData,
    );
  }

  /// บันทึก trip status update เมื่อ offline
  Future<void> enqueueTripStatusUpdate({
    required String tripId,
    required String newStatus,
  }) async {
    await enqueue(
      type: 'trip_status',
      endpoint: '/fleet/trips/$tripId/status',
      payload: {'status': newStatus},
    );
  }

  /// บันทึก checklist submission เมื่อ offline
  Future<void> enqueueChecklist({
    required String tripId,
    required List<Map<String, dynamic>> items,
  }) async {
    await enqueue(
      type: 'checklist',
      endpoint: '/fleet/trips/$tripId/checklist',
      payload: {'items': items},
    );
  }

  /// ตรวจสอบ connectivity แล้ว sync ถ้า online
  Future<void> _checkConnectivityAndSync() async {
    // TODO: ใช้ connectivity_plus package
    // final result = await Connectivity().checkConnectivity();
    // _isOnline = result != ConnectivityResult.none;

    _isOnline = true; // mock — assume always online

    if (_isOnline && _pendingQueue.isNotEmpty) {
      await syncNow();
    }
  }

  /// Force sync ทันที
  Future<SyncResult> syncNow() async {
    if (_isSyncing) {
      debugPrint('[OfflineSync] Already syncing, skipping');
      return SyncResult(synced: 0, failed: 0);
    }

    if (_pendingQueue.isEmpty) {
      return SyncResult(synced: 0, failed: 0);
    }

    _isSyncing = true;
    int synced = 0;
    int failed = 0;

    debugPrint('[OfflineSync] Syncing ${_pendingQueue.length} items...');

    final toProcess = List<Map<String, dynamic>>.from(_pendingQueue);

    for (final entry in toProcess) {
      try {
        await _uploadEntry(entry);
        _pendingQueue.remove(entry);

        // TODO: ลบจาก SQLite
        // await _db.delete('offline_queue', where: 'id = ?', whereArgs: [entry['id']]);

        synced++;
        debugPrint('[OfflineSync] Synced: ${entry['type']}');
      } catch (e) {
        final retryCount = (entry['retry_count'] as int) + 1;
        entry['retry_count'] = retryCount;

        if (retryCount >= 5) {
          // ลบออกถ้าล้มเหลว 5 ครั้ง
          _pendingQueue.remove(entry);
          debugPrint('[OfflineSync] Dropped after 5 retries: ${entry['type']}');
        }

        failed++;
        debugPrint('[OfflineSync] Failed: ${entry['type']} — $e');
      }
    }

    _isSyncing = false;
    debugPrint('[OfflineSync] Sync complete: $synced synced, $failed failed');

    return SyncResult(synced: synced, failed: failed);
  }

  /// อัปโหลด entry เดียวไป API
  Future<void> _uploadEntry(Map<String, dynamic> entry) async {
    // TODO: เรียก ApiClient จริง
    // await ApiClient.instance.post(
    //   entry['endpoint'] as String,
    //   entry['payload'] as Map<String, dynamic>,
    // );

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Mock success — throw exception เพื่อ test retry
    debugPrint('[OfflineSync] Uploaded to ${entry['endpoint']}');
  }

  /// ล้าง queue ทั้งหมด (ใช้ในกรณี logout)
  Future<void> clearQueue() async {
    _pendingQueue.clear();
    // TODO: ลบจาก SQLite
    // await _db.delete('offline_queue');
    debugPrint('[OfflineSync] Queue cleared');
  }

  /// Export queue เป็น JSON (สำหรับ debug)
  String exportQueueJson() {
    return jsonEncode(_pendingQueue);
  }

  void dispose() {
    stop();
  }
}

/// ผลลัพธ์การ sync
class SyncResult {
  final int synced;
  final int failed;

  const SyncResult({required this.synced, required this.failed});

  bool get hasErrors => failed > 0;
  bool get allSuccess => failed == 0;

  @override
  String toString() => 'SyncResult(synced: $synced, failed: $failed)';
}
