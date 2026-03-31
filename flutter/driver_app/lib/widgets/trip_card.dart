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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      tripNo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1565C0),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  color: const Color(0xFF9E9E9E),
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
                  const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF616161)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      cargo,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF616161)),
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
                    const Icon(Icons.route, size: 14, color: Color(0xFF616161)),
                    const SizedBox(width: 4),
                    Text(
                      '${(distance is num) ? distance.toStringAsFixed(0) : distance} กม.',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF616161)),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (revenue != null) ...[
                    const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 4),
                    Text(
                      '฿${(revenue is num) ? revenue.toStringAsFixed(0) : revenue}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2E7D32),
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
    Color bgColor;
    bool isFilled;

    switch (status) {
      case 'pending':
        label = 'รับงาน';
        bgColor = const Color(0xFFFF8F00);
        isFilled = true;
        break;
      case 'accepted':
        label = 'เริ่มวิ่ง';
        bgColor = const Color(0xFF1565C0);
        isFilled = true;
        break;
      case 'started':
      case 'arrived':
        label = 'ดูรายละเอียด';
        bgColor = const Color(0xFF1565C0);
        isFilled = false;
        break;
      case 'completed':
        label = 'ดู POD';
        bgColor = const Color(0xFF2E7D32);
        isFilled = false;
        break;
      default:
        return const SizedBox.shrink();
    }

    void onTap() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripDetailScreen(trip: trip),
        ),
      );
    }

    if (isFilled) {
      return SizedBox(
        height: 32,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: Size.zero,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
