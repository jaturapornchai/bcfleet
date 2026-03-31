import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://bcfleet.satistang.com/api/v1/fleet';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;
  String? _selectedVehicleId;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(Uri.parse('$_apiBase/vehicles?limit=50'));
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        setState(() {
          _vehicles =
              (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _healthColor(String? h) {
    switch (h) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final v in _vehicles) {
      final lat = v['current_lat'];
      final lng = v['current_lng'];
      if (lat == null || lng == null) continue;

      final plate = v['plate'] as String? ?? '';
      final status = v['status'] as String? ?? 'active';
      final color = _statusColor(status);
      final isSelected = v['id'] == _selectedVehicleId;

      markers.add(Marker(
        point: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
        width: 110,
        height: 58,
        child: GestureDetector(
          onTap: () => setState(
              () => _selectedVehicleId = isSelected ? null : v['id'] as String?),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_shipping,
                  color: isSelected ? Colors.blue : color, size: 28),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: isSelected ? Colors.blue : color, width: 1.5),
                  boxShadow: const [
                    BoxShadow(blurRadius: 3, color: Colors.black26)
                  ],
                ),
                child: Text(
                  plate,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue : color),
                ),
              ),
            ],
          ),
        ),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final markers = _buildMarkers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่รถ Real-time'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _loadVehicles),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: const MapOptions(
                      initialCenter: LatLng(18.7883, 98.9853),
                      initialZoom: 11.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.bcfleet.boss',
                      ),
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
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.cardColor,
            child: Row(
              children: [
                Text(
                  'รถทั้งหมด ${_vehicles.length} คัน  •  แสดงบนแผนที่ ${markers.length} คัน',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),

          // Vehicle list panel
          Expanded(
            flex: 2,
            child: _VehicleListPanel(
              vehicles: _vehicles,
              selectedId: _selectedVehicleId,
              onSelect: (id) {
                setState(() => _selectedVehicleId = id);
                // Move map to selected vehicle
                final v = _vehicles.firstWhere((v) => v['id'] == id,
                    orElse: () => {});
                final lat = v['current_lat'];
                final lng = v['current_lng'];
                if (lat != null && lng != null) {
                  _mapController.move(
                      LatLng(
                          (lat as num).toDouble(), (lng as num).toDouble()),
                      14.0);
                }
              },
              healthColor: _healthColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleListPanel extends StatelessWidget {
  final List<Map<String, dynamic>> vehicles;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final Color Function(String?) healthColor;

  const _VehicleListPanel({
    required this.vehicles,
    required this.selectedId,
    required this.onSelect,
    required this.healthColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('รายการรถ',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: vehicles.length,
            itemBuilder: (context, i) {
              final v = vehicles[i];
              final id = v['id'] as String? ?? '';
              final isSelected = id == selectedId;
              final hasLocation =
                  v['current_lat'] != null && v['current_lng'] != null;
              return GestureDetector(
                onTap: () => onSelect(id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 140,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: healthColor(v['health_status'] as String?),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              v['plate'] as String? ?? '-',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(v['type'] as String? ?? '-',
                          style: theme.textTheme.bodySmall),
                      if (v['brand'] != null)
                        Text(
                          v['brand'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            hasLocation ? Icons.location_on : Icons.location_off,
                            size: 11,
                            color: hasLocation ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            hasLocation ? 'มีตำแหน่ง' : 'ไม่มีตำแหน่ง',
                            style: TextStyle(
                                fontSize: 10,
                                color:
                                    hasLocation ? Colors.green : Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
