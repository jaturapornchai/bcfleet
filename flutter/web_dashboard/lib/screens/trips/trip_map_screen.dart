import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://smlfleet.satistang.com/api/v1/fleet';

class TripMapScreen extends StatefulWidget {
  const TripMapScreen({super.key});

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;
  String _selectedVehicleFilter = 'all';
  bool _showLabels = true;
  String? _selectedVehicleDetail;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(Uri.parse('$_apiBase/vehicles?limit=100'));
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

  List<Map<String, dynamic>> get _filtered {
    if (_selectedVehicleFilter == 'all') return _vehicles;
    return _vehicles.where((v) => v['id'] == _selectedVehicleFilter).toList();
  }

  List<Map<String, dynamic>> get _vehiclesWithLocation =>
      _filtered.where((v) => v['current_lat'] != null && v['current_lng'] != null).toList();

  Color _statusColor(String? s) {
    switch (s) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  List<Marker> _buildMarkers() {
    return _vehiclesWithLocation.map((v) {
      final lat = (v['current_lat'] as num).toDouble();
      final lng = (v['current_lng'] as num).toDouble();
      final plate = v['plate'] as String? ?? '';
      final color = _statusColor(v['status'] as String?);
      final isSelected = v['id'] == _selectedVehicleDetail;

      return Marker(
        point: LatLng(lat, lng),
        width: 110,
        height: _showLabels ? 62 : 44,
        child: GestureDetector(
          onTap: () {
            final id = v['id'] as String?;
            setState(() =>
                _selectedVehicleDetail = isSelected ? null : id);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_shipping,
                  color: isSelected ? Colors.purple : color, size: 28),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: isSelected ? Colors.purple : color,
                      width: 1.5),
                  boxShadow: const [
                    BoxShadow(blurRadius: 3, color: Colors.black26)
                  ],
                ),
                child: Text(
                  plate,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.purple : color),
                ),
              ),
              if (_showLabels && v['status'] == 'active')
                Text(
                  'วิ่งอยู่',
                  style: TextStyle(
                      fontSize: 9,
                      color: color.withValues(alpha: 0.8)),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final markers = _buildMarkers();

    final inTrip = _vehicles
        .where((v) => v['status'] == 'active')
        .length;
    final maintenance = _vehicles
        .where((v) => v['status'] == 'maintenance')
        .length;
    final idle = _vehicles.length - inTrip - maintenance;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'แผนที่รถทั้งหมด (Real-time)',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: 220,
                child: DropdownButton<String>(
                  value: _selectedVehicleFilter,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                        value: 'all', child: Text('ดูรถทุกคัน')),
                    ..._vehicles.map((v) => DropdownMenuItem(
                          value: v['id'] as String?,
                          child: Text(
                              '${v['plate'] ?? '-'} — ${(v['brand'] ?? '')}'),
                        )),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedVehicleFilter = v ?? 'all'),
                ),
              ),
              const SizedBox(width: 16),
              FilterChip(
                label: const Text('แสดงป้าย'),
                selected: _showLabels,
                onSelected: (v) => setState(() => _showLabels = v),
              ),
              const SizedBox(width: 8),
              IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadVehicles,
                  tooltip: 'รีเฟรช'),
            ],
          ),
          const SizedBox(height: 16),

          // Status summary row
          Row(
            children: [
              _buildStatusCount(cs, 'กำลังวิ่ง', inTrip, Colors.green),
              const SizedBox(width: 12),
              _buildStatusCount(cs, 'จอดรอ', idle < 0 ? 0 : idle, Colors.blue),
              const SizedBox(width: 12),
              _buildStatusCount(cs, 'ซ่อมบำรุง', maintenance, Colors.orange),
              const SizedBox(width: 12),
              _buildStatusCount(cs, 'รวมทั้งหมด', _vehicles.length, cs.primary),
              const SizedBox(width: 12),
              _buildStatusCount(
                  cs, 'มีพิกัด', _vehiclesWithLocation.length, Colors.teal),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Map area
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: const MapOptions(
                                  initialCenter: LatLng(18.7883, 98.9853),
                                  initialZoom: 10.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'com.smlfleet.dashboard',
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
                              // LIVE badge
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('LIVE',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 4),
                                      Text('อัปเดตทุก 30 วิ',
                                          style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                              // Recenter button
                              Positioned(
                                bottom: 40,
                                right: 12,
                                child: FloatingActionButton.small(
                                  heroTag: 'recenter_map',
                                  onPressed: () => _mapController.move(
                                      const LatLng(18.7883, 98.9853), 10.0),
                                  child: const Icon(Icons.my_location),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Vehicle list panel
                SizedBox(
                  width: 280,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('รายการรถ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                  fontSize: 14)),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _loading
                              ? const Center(
                                  child: CircularProgressIndicator())
                              : ListView.separated(
                                  itemCount: _filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final v = _filtered[index];
                                    final vid = v['id'] as String?;
                                    final isSelected =
                                        _selectedVehicleDetail == vid;
                                    final hasLocation =
                                        v['current_lat'] != null &&
                                            v['current_lng'] != null;

                                    return InkWell(
                                      onTap: () {
                                        setState(() =>
                                            _selectedVehicleDetail =
                                                isSelected ? null : vid);
                                        if (hasLocation) {
                                          _mapController.move(
                                            LatLng(
                                              (v['current_lat'] as num)
                                                  .toDouble(),
                                              (v['current_lng'] as num)
                                                  .toDouble(),
                                            ),
                                            14.0,
                                          );
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        color: isSelected
                                            ? cs.primaryContainer
                                                .withValues(alpha: 0.3)
                                            : null,
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                _vehicleStatusDot(
                                                    v['status'] as String?),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    v['plate'] as String? ??
                                                        '-',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13),
                                                  ),
                                                ),
                                                if (hasLocation)
                                                  const Icon(
                                                      Icons.location_on,
                                                      size: 12,
                                                      color: Colors.green),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            if (v['brand'] != null ||
                                                v['type'] != null)
                                              Text(
                                                '${v['brand'] ?? ''} ${v['type'] ?? ''}'
                                                    .trim(),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600]),
                                              ),
                                            if (isSelected && hasLocation) ...[
                                              const SizedBox(height: 8),
                                              const Divider(height: 1),
                                              const SizedBox(height: 8),
                                              _detailRow(
                                                  'สถานะ',
                                                  v['status'] as String? ??
                                                      '-'),
                                              _detailRow(
                                                'พิกัด',
                                                '${(v['current_lat'] as num).toStringAsFixed(4)}, '
                                                    '${(v['current_lng'] as num).toStringAsFixed(4)}',
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
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

  Widget _buildStatusCount(
      ColorScheme cs, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _vehicleStatusDot(String? status) {
    final color = status == 'active'
        ? Colors.green
        : status == 'maintenance'
            ? Colors.orange
            : Colors.blue;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
              width: 60,
              child: Text(label,
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey[600]))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
