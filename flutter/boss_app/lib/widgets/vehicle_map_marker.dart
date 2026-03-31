import 'package:flutter/material.dart';
import 'package:fleet_core/models/vehicle.dart';

class VehicleMapMarker extends StatelessWidget {
  final Vehicle vehicle;
  final bool isSelected;
  final VoidCallback? onTap;

  const VehicleMapMarker({
    super.key,
    required this.vehicle,
    this.isSelected = false,
    this.onTap,
  });

  Color get _healthColor {
    switch (vehicle.healthStatus) {
      case 'green': return Colors.green;
      case 'yellow': return Colors.orange;
      case 'red': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? _healthColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _healthColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: _healthColor.withValues(alpha: 0.3),
              blurRadius: isSelected ? 12 : 4,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_rounded,
              size: 16,
              color: isSelected ? Colors.white : _healthColor,
            ),
            const SizedBox(width: 4),
            Text(
              vehicle.plate,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact dot marker สำหรับ zoom ออก
class VehicleMapDot extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const VehicleMapDot({super.key, required this.vehicle, this.onTap});

  Color get _color {
    switch (vehicle.healthStatus) {
      case 'green': return Colors.green;
      case 'yellow': return Colors.orange;
      case 'red': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: _color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: _color.withValues(alpha: 0.4), blurRadius: 4),
          ],
        ),
      ),
    );
  }
}
