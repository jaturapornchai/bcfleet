import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/trip_bloc.dart';
import '../widgets/status_badge.dart';
import 'navigation_screen.dart';
import 'pod_screen.dart';
import 'checklist_screen.dart';

class TripDetailScreen extends StatelessWidget {
  final Map<String, dynamic> trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final status = trip['status'] as String? ?? 'pending';
    final tripNo = trip['trip_no'] as String? ?? '-';
    final origin = trip['origin_name'] as String? ?? '-';
    final destination = trip['destination_name'] as String? ?? '-';
    final cargo = trip['cargo_description'] as String? ?? '-';
    final weight = trip['cargo_weight_kg'];
    final distance = trip['distance_km'];
    final revenue = trip['revenue'];
    final plannedStart = trip['planned_start'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(tripNo),
        actions: [
          StatusBadge(status: status),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('เส้นทาง',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _RouteRow(icon: Icons.circle, color: Colors.green, label: 'ต้นทาง', value: origin),
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: SizedBox(
                        height: 20,
                        child: VerticalDivider(width: 2, color: Colors.grey),
                      ),
                    ),
                    _RouteRow(icon: Icons.location_on, color: Colors.red, label: 'ปลายทาง', value: destination),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Map placeholder
            Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                height: 180,
                color: Colors.grey.shade200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('แผนที่ Longdo Map',
                          style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NavigationScreen(trip: trip),
                            ),
                          );
                        },
                        icon: const Icon(Icons.navigation, size: 16),
                        label: const Text('นำทาง'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 36),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cargo & Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ข้อมูลสินค้า',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'สินค้า', value: cargo),
                    if (weight != null)
                      _InfoRow(label: 'น้ำหนัก', value: '$weight กก.'),
                    if (distance != null)
                      _InfoRow(label: 'ระยะทาง', value: '${(distance is num) ? distance.toStringAsFixed(1) : distance} กม.'),
                    if (plannedStart != null)
                      _InfoRow(label: 'เวลานัดหมาย', value: _formatDate(plannedStart)),
                    if (revenue != null)
                      _InfoRow(
                        label: 'ค่าขนส่ง',
                        value: '฿${(revenue is num) ? revenue.toStringAsFixed(0) : revenue}',
                        valueColor: Colors.green.shade700,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Checklist status
            Card(
              child: ListTile(
                leading: const Icon(Icons.checklist, color: Color(0xFF1565C0)),
                title: const Text('Checklist ก่อนออก'),
                subtitle: const Text('ตรวจสภาพรถก่อนเดินทาง'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChecklistScreen(tripId: trip['id']?.toString() ?? ''),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // POD status
            if (['delivering', 'completed'].contains(status))
              Card(
                child: ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF1565C0)),
                  title: const Text('หลักฐานส่งมอบ (POD)'),
                  subtitle: Text(
                    trip['hasPod'] == true ? 'บันทึกแล้ว' : 'ยังไม่บันทึก',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PodScreen(tripId: trip['id']?.toString() ?? ''),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Action button
            _ActionButton(status: status, tripId: trip['id'] as String? ?? ''),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year + 543} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
    } catch (_) {
      return iso;
    }
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _RouteRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String status;
  final String tripId;

  const _ActionButton({required this.status, required this.tripId});

  @override
  Widget build(BuildContext context) {
    String label;
    String nextStatus;
    Color color;

    switch (status) {
      case 'pending':
        label = 'รับงาน';
        nextStatus = 'accepted';
        color = Colors.orange;
        break;
      case 'accepted':
        label = 'เริ่มวิ่ง';
        nextStatus = 'started';
        color = Colors.blue;
        break;
      case 'started':
        label = 'ถึงจุดส่งแล้ว';
        nextStatus = 'arrived';
        color = Colors.teal;
        break;
      case 'arrived':
        label = 'เริ่มส่งมอบ';
        nextStatus = 'delivering';
        color = Colors.cyan.shade700;
        break;
      case 'delivering':
        label = 'บันทึก POD และเสร็จสิ้น';
        nextStatus = 'completed';
        color = Colors.green;
        break;
      default:
        return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size(double.infinity, 52),
          ),
          onPressed: () {
            context.read<TripBloc>().add(
                  UpdateTripStatus(tripId: tripId, newStatus: nextStatus),
                );
            if (nextStatus == 'delivering') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PodScreen(tripId: tripId),
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
