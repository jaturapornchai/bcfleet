import 'package:flutter/material.dart';

class NavigationScreen extends StatelessWidget {
  final Map<String, dynamic> trip;

  const NavigationScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final destination = trip['destination_name'] as String? ?? '-';
    final distance = trip['distance_km'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('นำทาง'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info bar
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    destination,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (distance != null)
                  Text(
                    '${distance.toStringAsFixed(0)} กม.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
              ],
            ),
          ),

          // Map placeholder
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: Colors.grey.shade300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined,
                            size: 80, color: Colors.grey.shade500),
                        const SizedBox(height: 12),
                        Text(
                          'Longdo Map API v3',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'แผนที่จะแสดงเมื่อเชื่อมต่อ API',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                // Speed indicator
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('0',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('กม/ชม',
                            style:
                                TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.route,
                        label: distance != null
                            ? '${distance.toStringAsFixed(0)} กม.'
                            : '- กม.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.access_time,
                        label: distance != null
                            ? '~${(distance / 60 * 60).toStringAsFixed(0)} นาที'
                            : '- นาที',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('เชื่อมต่อ Longdo Map เพื่อนำทาง'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('เริ่มนำทาง'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1565C0)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
        ],
      ),
    );
  }
}
