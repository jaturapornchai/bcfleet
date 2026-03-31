import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
// ignore: unused_import — used in build() for Responsive.isMobile
import '../app.dart' show Responsive;

const _apiBase = 'https://smlfleet.satistang.com/api/v1/fleet';

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

  void _selectVehicle(String id) {
    setState(() => _selectedVehicleId = id);
    final v = _vehicles.firstWhere((v) => v['id'] == id, orElse: () => {});
    final lat = v['current_lat'];
    final lng = v['current_lng'];
    if (lat != null && lng != null) {
      _mapController.move(
        LatLng((lat as num).toDouble(), (lng as num).toDouble()),
        14.0,
      );
    }
  }

  void _showVehicleListSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text('รายการรถ (${_vehicles.length} คัน)',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: _vehicles.length,
                itemBuilder: (context, i) {
                  final v = _vehicles[i];
                  final id = v['id'] as String? ?? '';
                  final isSelected = id == _selectedVehicleId;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _healthColor(v['health_status'] as String?),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(v['plate'] as String? ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${v['type'] ?? '-'} · ${v['brand'] ?? ''}'),
                    trailing: v['current_lat'] != null
                        ? const Icon(Icons.location_on, size: 16, color: Colors.green)
                        : const Icon(Icons.location_off, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);
                      _selectVehicle(id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final markers = _buildMarkers();

    final mapWidget = _loading
        ? const Center(child: CircularProgressIndicator())
        : FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(18.7883, 98.9853),
              initialZoom: 11.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smlfleet.boss',
              ),
              MarkerLayer(markers: markers),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors', onTap: () {}),
                ],
              ),
            ],
          );

    final statusBar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.cardColor,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'รถทั้งหมด ${_vehicles.length} คัน  •  บนแผนที่ ${markers.length} คัน',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );

    if (isMobile) {
      // Mobile: full screen map + FAB to open vehicle list bottom sheet
      return Scaffold(
        appBar: AppBar(
          title: const Text('แผนที่รถ Real-time'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadVehicles),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(child: mapWidget),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: statusBar,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showVehicleListSheet(context),
          icon: const Icon(Icons.list_rounded),
          label: Text('รายการรถ (${_vehicles.length})'),
        ),
      );
    }

    // Tablet / Desktop: map + side panel
    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่รถ Real-time'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadVehicles),
        ],
      ),
      body: Row(
        children: [
          // Vehicle list side panel
          SizedBox(
            width: 260,
            child: Column(
              children: [
                statusBar,
                Expanded(
                  child: _VehicleListPanel(
                    vehicles: _vehicles,
                    selectedId: _selectedVehicleId,
                    onSelect: _selectVehicle,
                    healthColor: _healthColor,
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Map fills remaining space
          Expanded(child: mapWidget),
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
