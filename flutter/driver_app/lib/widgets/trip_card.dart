import 'package:flutter/material.dart';
import 'status_badge.dart';
import '../screens/trip_detail_screen.dart';

class TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;

  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final status = trip['status'] as String? ?? 'pending';
    final tripNo = trip['trip_no'] as String? ?? '-';
    final origin = trip['origin_name'] as String? ?? '-';
    final destination = trip['destination_name'] as String? ?? '-';
    final cargo = trip['cargo_description'] as String? ?? '-';
    final distance = trip['distance_km'];
    final revenue = trip['revenue'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripDetailScreen(trip: trip),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tripNo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 12),
              // Route
              Row(
                children: [
                  const Icon(Icons.circle, size: 10, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      origin,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Container(
                  width: 2,
                  height: 16,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      destination,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Cargo info
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      cargo,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Footer
              Row(
                children: [
                  if (distance != null) ...[
                    Icon(Icons.route, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${(distance is num) ? distance.toStringAsFixed(0) : distance} กม.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (revenue != null) ...[
                    Icon(Icons.payments_outlined, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '฿${(revenue is num) ? revenue.toStringAsFixed(0) : revenue}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  _ActionButton(status: status, trip: trip),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String status;
  final Map<String, dynamic> trip;

  const _ActionButton({required this.status, required this.trip});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (status) {
      case 'pending':
        label = 'รับงาน';
        color = Colors.orange;
        break;
      case 'accepted':
        label = 'เริ่มวิ่ง';
        color = Colors.blue;
        break;
      case 'started':
      case 'arrived':
        label = 'ดูรายละเอียด';
        color = const Color(0xFF1565C0);
        break;
      case 'completed':
        label = 'ดู POD';
        color = Colors.green;
        break;
      default:
        return const SizedBox.shrink();
    }

    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailScreen(trip: trip),
          ),
        );
      },
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
