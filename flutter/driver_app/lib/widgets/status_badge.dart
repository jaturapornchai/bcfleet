import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config['color'] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config['label'] as String,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case 'draft':
        return {'label': 'แบบร่าง', 'color': const Color(0xFF757575)};
      case 'pending':
        return {'label': 'รอรับงาน', 'color': const Color(0xFFE65100)};
      case 'accepted':
        return {'label': 'รับงานแล้ว', 'color': const Color(0xFFFF8F00)};
      case 'started':
        return {'label': 'กำลังวิ่ง', 'color': const Color(0xFF1565C0)};
      case 'arrived':
        return {'label': 'ถึงจุดส่ง', 'color': const Color(0xFF6A1B9A)};
      case 'delivering':
        return {'label': 'กำลังส่ง', 'color': const Color(0xFF00838F)};
      case 'completed':
        return {'label': 'เสร็จสิ้น', 'color': const Color(0xFF2E7D32)};
      case 'cancelled':
        return {'label': 'ยกเลิก', 'color': const Color(0xFFD32F2F)};
      default:
        return {'label': status, 'color': const Color(0xFF757575)};
    }
  }
}
