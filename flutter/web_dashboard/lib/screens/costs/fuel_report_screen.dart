import 'package:flutter/material.dart';

class FuelReportScreen extends StatefulWidget {
  const FuelReportScreen({super.key});

  @override
  State<FuelReportScreen> createState() => _FuelReportScreenState();
}

class _FuelReportScreenState extends State<FuelReportScreen> {
  String _filterMonth = '03/2569';
  String _filterVehicle = 'all';
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  final _fuelLogs = [
    {'id': '1', 'vehicle': 'กท-1234', 'driver': 'สมชาย ใจดี', 'date': '01/03/2569', 'liters': '80', 'price_per_liter': '27.50', 'amount': '2,200', 'odometer': '85,200', 'prev_odometer': '80,100', 'distance': '5,100', 'efficiency': '63.75', 'station': 'ปตท. สาขาเชียงใหม่', 'fuel_type': 'ดีเซล B7', 'month': '03/2569'},
    {'id': '2', 'vehicle': 'กท-1234', 'driver': 'สมชาย ใจดี', 'date': '08/03/2569', 'liters': '75', 'price_per_liter': '27.50', 'amount': '2,062', 'odometer': '89,800', 'prev_odometer': '85,200', 'distance': '4,600', 'efficiency': '61.33', 'station': 'ปตท. สาขาลำพูน', 'fuel_type': 'ดีเซล B7', 'month': '03/2569'},
    {'id': '3', 'vehicle': '2กร-5678', 'driver': 'วิชัย ขับดี', 'date': '02/03/2569', 'liters': '120', 'price_per_liter': '27.50', 'amount': '3,300', 'odometer': '99,000', 'prev_odometer': '92,000', 'distance': '7,000', 'efficiency': '58.33', 'station': 'บางจาก สาขาเชียงใหม่', 'fuel_type': 'ดีเซล B7', 'month': '03/2569'},
    {'id': '4', 'vehicle': 'ชม-3456', 'driver': 'อนุชา ขนดี', 'date': '03/03/2569', 'liters': '55', 'price_per_liter': '27.20', 'amount': '1,496', 'odometer': '103,500', 'prev_odometer': '100,200', 'distance': '3,300', 'efficiency': '60.00', 'station': 'Shell สาขาเชียงใหม่', 'fuel_type': 'ดีเซล B7', 'month': '03/2569'},
    {'id': '5', 'vehicle': 'กน-7890', 'driver': 'สมบัติ ลากดี', 'date': '05/03/2569', 'liters': '200', 'price_per_liter': '27.50', 'amount': '5,500', 'odometer': '89,500', 'prev_odometer': '81,000', 'distance': '8,500', 'efficiency': '42.50', 'station': 'ปตท. สาขาลำปาง', 'fuel_type': 'ดีเซล B7', 'month': '03/2569'},
    {'id': '6', 'vehicle': 'ลป-1122', 'driver': 'ประสิทธิ์ มีรถ', 'date': '06/03/2569', 'liters': '90', 'price_per_liter': '27.50', 'amount': '2,475', 'odometer': '76,000', 'prev_odometer': '70,500', 'distance': '5,500', 'efficiency': '61.11', 'station': 'Caltex สาขาลำปาง', 'fuel_type': 'ดีเซล B7', 'month': '03/2569'},
    {'id': '7', 'vehicle': 'พย-3344', 'driver': 'ชัยวัฒน์ ขับดี', 'date': '07/03/2569', 'liters': '70', 'price_per_liter': '27.20', 'amount': '1,904', 'odometer': '96,500', 'prev_odometer': '91,500', 'distance': '5,000', 'efficiency': '71.43', 'station': 'ปตท. สาขาพะเยา', 'fuel_type': 'ดีเซล B7', 'month': '03/2569'},
    {'id': '8', 'vehicle': 'กท-1234', 'driver': 'สมชาย ใจดี', 'date': '15/03/2569', 'liters': '82', 'price_per_liter': '27.80', 'amount': '2,280', 'odometer': '94,400', 'prev_odometer': '89,800', 'distance': '4,600', 'efficiency': '56.10', 'station': 'ปตท. สาขาเชียงใหม่', 'fuel_type': 'ดีเซล B7', 'month': '03/2569'},
  ];

  List<Map<String, String>> get _filtered => _fuelLogs.where((f) {
    final matchMonth = _filterMonth == 'all' || f['month'] == _filterMonth;
    final matchVehicle = _filterVehicle == 'all' || f['vehicle'] == _filterVehicle;
    return matchMonth && matchVehicle;
  }).toList();

  int _parseAmount(String s) => int.tryParse(s.replaceAll(',', '')) ?? 0;

  String _formatAmount(int amount) {
    if (amount >= 1000) {
      final str = amount.toString();
      final result = StringBuffer();
      final offset = str.length % 3;
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (i - offset) % 3 == 0) result.write(',');
        result.write(str[i]);
      }
      return result.toString();
    }
    return amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final pageStart = _currentPage * _rowsPerPage;
    final pageEnd = (pageStart + _rowsPerPage).clamp(0, filtered.length);
    final pageRows = filtered.sublist(pageStart, pageEnd);
    final totalPages = (filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

    final totalLiters = filtered.fold(0, (sum, f) => sum + _parseAmount(f['liters']!));
    final totalAmount = filtered.fold(0, (sum, f) => sum + _parseAmount(f['amount']!));
    final totalDistance = filtered.fold(0, (sum, f) => sum + _parseAmount(f['distance']!));
    final avgEfficiency = filtered.isEmpty ? 0.0 :
        filtered.fold(0.0, (sum, f) => sum + (double.tryParse(f['efficiency']!) ?? 0)) / filtered.length;

    final vehicles = _fuelLogs.map((f) => f['vehicle']!).toSet().toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('รายงานน้ำมัน', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Export Excel'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(cs, 'ปริมาณน้ำมันรวม', '${_formatAmount(totalLiters)} ลิตร', Colors.orange, Icons.local_gas_station_outlined),
              const SizedBox(width: 12),
              _buildStatCard(cs, 'ค่าน้ำมันรวม', '฿${_formatAmount(totalAmount)}', Colors.red, Icons.payments_outlined),
              const SizedBox(width: 12),
              _buildStatCard(cs, 'ระยะทางรวม', '${_formatAmount(totalDistance)} กม.', cs.primary, Icons.route_outlined),
              const SizedBox(width: 12),
              _buildStatCard(cs, 'อัตราเฉลี่ย', '${avgEfficiency.toStringAsFixed(1)} กม./ลิตร', Colors.green, Icons.speed_outlined),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              DropdownButton<String>(
                value: _filterMonth,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('ทุกเดือน')),
                  DropdownMenuItem(value: '03/2569', child: Text('มีนาคม 2569')),
                  DropdownMenuItem(value: '02/2569', child: Text('กุมภาพันธ์ 2569')),
                  DropdownMenuItem(value: '01/2569', child: Text('มกราคม 2569')),
                ],
                onChanged: (v) => setState(() { _filterMonth = v!; _currentPage = 0; }),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filterVehicle,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('ทุกคัน')),
                  ...vehicles.map((v) => DropdownMenuItem(value: v, child: Text(v))),
                ],
                onChanged: (v) => setState(() { _filterVehicle = v!; _currentPage = 0; }),
              ),
              const Spacer(),
              Text('${filtered.length} รายการ', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(cs.surfaceContainerLow),
                        columns: const [
                          DataColumn(label: Text('วันที่')),
                          DataColumn(label: Text('รถ')),
                          DataColumn(label: Text('คนขับ')),
                          DataColumn(label: Text('ลิตร'), numeric: true),
                          DataColumn(label: Text('ราคา/ลิตร'), numeric: true),
                          DataColumn(label: Text('ยอดรวม'), numeric: true),
                          DataColumn(label: Text('เลขไมล์')),
                          DataColumn(label: Text('ระยะทาง'), numeric: true),
                          DataColumn(label: Text('อัตราสิ้นเปลือง'), numeric: true),
                          DataColumn(label: Text('สถานีบริการ')),
                        ],
                        rows: pageRows.map((f) {
                          final efficiency = double.tryParse(f['efficiency']!) ?? 0;
                          final isLowEfficiency = efficiency < 55.0;
                          return DataRow(
                            color: isLowEfficiency ? WidgetStateProperty.all(Colors.orange.withValues(alpha: 0.05)) : null,
                            cells: [
                              DataCell(Text(f['date']!, style: const TextStyle(fontSize: 12))),
                              DataCell(Text(f['vehicle']!, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(f['driver']!, style: const TextStyle(fontSize: 12))),
                              DataCell(Text(f['liters']!, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text('฿${f['price_per_liter']!}')),
                              DataCell(Text('฿${f['amount']!}', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold))),
                              DataCell(Text('${f['odometer']!} กม.', style: const TextStyle(fontSize: 12))),
                              DataCell(Text('${f['distance']!} กม.')),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isLowEfficiency ? Colors.orange : Colors.green).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${f['efficiency']!} กม./ลิตร',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isLowEfficiency ? Colors.orange[700] : Colors.green[700],
                                  ),
                                ),
                              )),
                              DataCell(SizedBox(
                                width: 160,
                                child: Text(f['station']!, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text('หน้า ${_currentPage + 1} จาก $totalPages', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null),
                        IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ColorScheme cs, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
