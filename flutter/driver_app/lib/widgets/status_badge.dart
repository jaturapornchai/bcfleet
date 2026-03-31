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
      ),
    );
  }

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case 'draft':
        return {'label': 'แบบร่าง', 'color': Colors.grey};
      case 'pending':
        return {'label': 'รอรับงาน', 'color': Colors.orange};
      case 'accepted':
        return {'label': 'รับงานแล้ว', 'color': Colors.blue.shade600};
      case 'started':
        return {'label': 'กำลังวิ่ง', 'color': Colors.indigo};
      case 'arrived':
        return {'label': 'ถึงจุดส่ง', 'color': Colors.teal};
      case 'delivering':
        return {'label': 'กำลังส่ง', 'color': Colors.cyan.shade700};
      case 'completed':
        return {'label': 'เสร็จสิ้น', 'color': Colors.green.shade600};
      case 'cancelled':
        return {'label': 'ยกเลิก', 'color': Colors.red};
      default:
        return {'label': status, 'color': Colors.grey};
    }
  }
}
