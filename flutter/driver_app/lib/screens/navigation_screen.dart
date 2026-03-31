import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class NavigationScreen extends StatefulWidget {
  final Map<String, dynamic> trip;

  const NavigationScreen({super.key, required this.trip});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();

  LatLng get _origin {
    final lat = widget.trip['origin_lat'];
    final lng = widget.trip['origin_lng'];
    if (lat != null && lng != null) {
      return LatLng((lat as num).toDouble(), (lng as num).toDouble());
    }
    return const LatLng(18.7883, 98.9853); // เชียงใหม่ default
  }

  LatLng get _destination {
    final lat = widget.trip['destination_lat'];
    final lng = widget.trip['destination_lng'];
    if (lat != null && lng != null) {
      return LatLng((lat as num).toDouble(), (lng as num).toDouble());
    }
    // Offset slightly from origin as fallback
    return LatLng(_origin.latitude - 0.15, _origin.longitude + 0.05);
  }

  LatLng get _center {
    return LatLng(
      (_origin.latitude + _destination.latitude) / 2,
      (_origin.longitude + _destination.longitude) / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.trip['destination_name'] as String? ?? '-';
    final distance = widget.trip['distance_km'];

    final markers = [
      // Origin marker
      Marker(
        point: _origin,
        width: 40,
        height: 40,
        child: const Icon(Icons.warehouse, color: Colors.blue, size: 32),
      ),
      // Destination marker
      Marker(
        point: _destination,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
      ),
    ];

    final polyline = Polyline(
      points: [_origin, _destination],
      color: Colors.blue.withValues(alpha: 0.7),
      strokeWidth: 4.0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('นำทาง'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
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
                    '${(distance as num).toStringAsFixed(0)} กม.',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 10.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.bcfleet.driver',
                    ),
                    PolylineLayer(polylines: [polyline]),
                    MarkerLayer(markers: markers),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                            'OpenStreetMap contributors',
                            onTap: () {}),
                      ],
                    ),
                  ],
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
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),

                // Re-center button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter',
                    onPressed: () =>
                        _mapController.move(_center, 10.0),
                    child: const Icon(Icons.my_location),
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
                            ? '${(distance as num).toStringAsFixed(0)} กม.'
                            : '- กม.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.access_time,
                        label: distance != null
                            ? '~${((distance as num) / 60 * 60).toStringAsFixed(0)} นาที'
                            : '- นาที',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _mapController.move(_origin, 14.0),
                    icon: const Icon(Icons.navigation),
                    label: const Text('เริ่มนำทาง'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
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
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0))),
        ],
      ),
    );
  }
}
