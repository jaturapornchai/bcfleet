import 'package:flutter/material.dart';

class TripMapScreen extends StatefulWidget {
  const TripMapScreen({super.key});

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  String _selectedVehicle = 'all';
  bool _showRoutes = true;
  bool _showLabels = true;

  final _vehicles = [
    {'id': 'v1', 'plate': 'กท-1234', 'driver': 'สมชาย ใจดี', 'status': 'in_trip', 'trip': 'TRIP-001', 'lat': '18.7883', 'lng': '98.9853', 'speed': '65', 'dest': 'ลำพูน'},
    {'id': 'v2', 'plate': '2กร-5678', 'driver': 'วิชัย ขับดี', 'status': 'idle', 'trip': '', 'lat': '18.7800', 'lng': '98.9700', 'speed': '0', 'dest': ''},
    {'id': 'v3', 'plate': 'ชม-3456', 'driver': 'สมศักดิ์ รักงาน', 'status': 'in_trip', 'trip': 'TRIP-002', 'lat': '18.8100', 'lng': '98.9600', 'speed': '55', 'dest': 'เชียงราย'},
    {'id': 'v4', 'plate': 'กน-7890', 'driver': 'ประสิทธิ์ มีน้ำใจ', 'status': 'in_trip', 'trip': 'TRIP-003', 'lat': '18.7500', 'lng': '99.0100', 'speed': '72', 'dest': 'ลำปาง'},
    {'id': 'v5', 'plate': 'ลป-1122', 'driver': 'อนุชา ตั้งใจ', 'status': 'idle', 'trip': '', 'lat': '18.7900', 'lng': '98.9900', 'speed': '0', 'dest': ''},
    {'id': 'v6', 'plate': 'พย-3344', 'driver': 'วีระ ขยัน', 'status': 'maintenance', 'trip': '', 'lat': '18.7700', 'lng': '98.9800', 'speed': '0', 'dest': ''},
  ];

  String? _selectedVehicleDetail;

  List<Map<String, String>> get _filtered => _selectedVehicle == 'all'
      ? _vehicles
      : _vehicles.where((v) => v['id'] == _selectedVehicle).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('แผนที่รถทั้งหมด (Real-time)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              // Filter
              SizedBox(
                width: 200,
                child: DropdownButton<String>(
                  value: _selectedVehicle,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('ดูรถทุกคัน')),
                    ..._vehicles.map((v) => DropdownMenuItem(value: v['id'], child: Text('${v['plate']} — ${v['driver']!.split(' ')[0]}'))),
                  ],
                  onChanged: (v) => setState(() => _selectedVehicle = v!),
                ),
              ),
              const SizedBox(width: 16),
              FilterChip(
                label: const Text('แสดงเส้นทาง'),
                selected: _showRoutes,
                onSelected: (v) => setState(() => _showRoutes = v),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('แสดงป้าย'),
                selected: _showLabels,
                onSelected: (v) => setState(() => _showLabels = v),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh), onPressed: () {}, tooltip: 'รีเฟรช'),
            ],
          ),
          const SizedBox(height: 16),
          // Status summary row
          Row(
            children: [
              _buildStatusCount(cs, 'กำลังวิ่ง', _vehicles.where((v) => v['status'] == 'in_trip').length, Colors.green),
              const SizedBox(width: 12),
              _buildStatusCount(cs, 'จอดรอ', _vehicles.where((v) => v['status'] == 'idle').length, Colors.blue),
              const SizedBox(width: 12),
              _buildStatusCount(cs, 'ซ่อมบำรุง', _vehicles.where((v) => v['status'] == 'maintenance').length, Colors.orange),
              const SizedBox(width: 12),
              _buildStatusCount(cs, 'รวมทั้งหมด', _vehicles.length, cs.primary),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Map area (placeholder)
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Map background placeholder
                        Container(
                          color: const Color(0xFFE8F4F8),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text('Longdo Map API', style: TextStyle(fontSize: 18, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('แผนที่ไทย — รถทุกคันแบบ Real-time', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                                const SizedBox(height: 24),
                                // Simulated vehicle markers
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children: _filtered.map((v) => _buildMapMarker(v, cs)).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Map controls overlay
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Column(
                            children: [
                              _mapControlButton(Icons.add, () {}),
                              const SizedBox(height: 4),
                              _mapControlButton(Icons.remove, () {}),
                              const SizedBox(height: 8),
                              _mapControlButton(Icons.my_location, () {}),
                              const SizedBox(height: 4),
                              _mapControlButton(Icons.layers, () {}),
                            ],
                          ),
                        ),
                        // Live indicator
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                Text('อัปเดตทุก 30 วิ', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                              ],
                            ),
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
                          child: Text('รายการรถ', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 14)),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final v = _filtered[index];
                              final isSelected = _selectedVehicleDetail == v['id'];
                              return InkWell(
                                onTap: () => setState(() => _selectedVehicleDetail = isSelected ? null : v['id']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  color: isSelected ? cs.primaryContainer.withValues(alpha: 0.3) : null,
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _vehicleStatusDot(v['status']!),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(v['plate']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          ),
                                          if (v['status'] == 'in_trip')
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.speed, size: 12, color: Colors.grey[500]),
                                                const SizedBox(width: 2),
                                                Text('${v['speed']!} กม./ชม.', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(v['driver']!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                      if (v['trip']!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.place, size: 11, color: Colors.green),
                                            const SizedBox(width: 3),
                                            Text('กำลังไป: ${v['dest']!}', style: const TextStyle(fontSize: 10, color: Colors.green)),
                                          ],
                                        ),
                                      ],
                                      if (isSelected && v['status'] == 'in_trip') ...[
                                        const SizedBox(height: 8),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        _detailRow('เที่ยวที่', v['trip']!),
                                        _detailRow('ความเร็ว', '${v['speed']!} กม./ชม.'),
                                        _detailRow('พิกัด', '${double.parse(v['lat']!).toStringAsFixed(4)}, ${double.parse(v['lng']!).toStringAsFixed(4)}'),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(Icons.route, size: 14),
                                            label: const Text('ดูเส้นทาง', style: TextStyle(fontSize: 12)),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                            ),
                                          ),
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

  Widget _buildStatusCount(ColorScheme cs, String label, int count, Color color) {
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
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildMapMarker(Map<String, String> v, ColorScheme cs) {
    final color = v['status'] == 'in_trip' ? Colors.green
        : v['status'] == 'maintenance' ? Colors.orange
        : Colors.blue;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping, color: color, size: 24),
          const SizedBox(height: 4),
          Text(v['plate']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          if (_showLabels && v['status'] == 'in_trip')
            Text(v['speed']! + ' กม./ชม.', style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _mapControlButton(IconData icon, VoidCallback onTap) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _vehicleStatusDot(String status) {
    final color = status == 'in_trip' ? Colors.green
        : status == 'maintenance' ? Colors.orange
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
          SizedBox(width: 60, child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
