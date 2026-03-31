import 'package:flutter/material.dart';

class PlPerVehicleScreen extends StatefulWidget {
  const PlPerVehicleScreen({super.key});

  @override
  State<PlPerVehicleScreen> createState() => _PlPerVehicleScreenState();
}

class _PlPerVehicleScreenState extends State<PlPerVehicleScreen> {
  String _selectedVehicle = 'กท-1234';
  String _filterPeriod = 'month';

  final _vehicles = ['กท-1234', '2กร-5678', 'ชม-3456', 'กน-7890', 'ลป-1122', 'พย-3344'];

  final _monthlyData = {
    'กท-1234': [
      {'month': 'ม.ค. 2569', 'revenue': '32,000', 'fuel': '7,200', 'toll': '480', 'maintenance': '0', 'driver': '2,400', 'other': '320', 'total_cost': '10,400', 'profit': '21,600', 'margin': '67.5', 'trips': '8'},
      {'month': 'ก.พ. 2569', 'revenue': '40,000', 'fuel': '8,000', 'toll': '600', 'maintenance': '0', 'driver': '3,000', 'other': '400', 'total_cost': '12,000', 'profit': '28,000', 'margin': '70.0', 'trips': '10'},
      {'month': 'มี.ค. 2569', 'revenue': '48,000', 'fuel': '9,600', 'toll': '720', 'maintenance': '4,040', 'driver': '3,600', 'other': '500', 'total_cost': '18,460', 'profit': '29,540', 'margin': '61.5', 'trips': '12'},
    ],
    '2กร-5678': [
      {'month': 'ม.ค. 2569', 'revenue': '56,000', 'fuel': '12,600', 'toll': '840', 'maintenance': '0', 'driver': '1,680', 'other': '280', 'total_cost': '15,400', 'profit': '40,600', 'margin': '72.5', 'trips': '7'},
      {'month': 'ก.พ. 2569', 'revenue': '56,000', 'fuel': '12,600', 'toll': '840', 'maintenance': '6,200', 'driver': '2,100', 'other': '300', 'total_cost': '22,040', 'profit': '33,960', 'margin': '60.6', 'trips': '7'},
      {'month': 'มี.ค. 2569', 'revenue': '64,000', 'fuel': '14,400', 'toll': '960', 'maintenance': '0', 'driver': '2,400', 'other': '200', 'total_cost': '17,960', 'profit': '46,040', 'margin': '71.9', 'trips': '8'},
    ],
  };

  List<Map<String, String>> get _currentData {
    return _monthlyData[_selectedVehicle] ?? _monthlyData['กท-1234']!;
  }

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
    final data = _currentData;

    final totalRevenue = data.fold(0, (sum, d) => sum + _parseAmount(d['revenue']!));
    final totalCost = data.fold(0, (sum, d) => sum + _parseAmount(d['total_cost']!));
    final totalProfit = data.fold(0, (sum, d) => sum + _parseAmount(d['profit']!));
    final avgMargin = data.isEmpty ? 0.0 :
        data.fold(0.0, (sum, d) => sum + (double.tryParse(d['margin']!) ?? 0)) / data.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('P&L ต่อคัน', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Export PDF'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Vehicle selector
          Row(
            children: [
              const Text('เลือกรถ:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedVehicle,
                items: _vehicles.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _selectedVehicle = v!),
              ),
              const SizedBox(width: 24),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'month', label: Text('รายเดือน')),
                  ButtonSegment(value: 'quarter', label: Text('รายไตรมาส')),
                ],
                selected: {_filterPeriod},
                onSelectionChanged: (s) => setState(() => _filterPeriod = s.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Summary KPI cards
          Row(
            children: [
              _buildKpiCard(cs, 'รายรับรวม', '฿${_formatAmount(totalRevenue)}', Colors.green, Icons.trending_up),
              const SizedBox(width: 12),
              _buildKpiCard(cs, 'ต้นทุนรวม', '฿${_formatAmount(totalCost)}', Colors.red, Icons.trending_down),
              const SizedBox(width: 12),
              _buildKpiCard(cs, 'กำไรสุทธิ', '฿${_formatAmount(totalProfit)}', cs.primary, Icons.account_balance_wallet_outlined),
              const SizedBox(width: 12),
              _buildKpiCard(cs, 'Margin เฉลี่ย', '${avgMargin.toStringAsFixed(1)}%', Colors.teal, Icons.percent),
            ],
          ),
          const SizedBox(height: 20),
          // P&L Table
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('รายละเอียด P&L — $_selectedVehicle',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.primary)),
                      const Divider(height: 24),
                      DataTable(
                        headingRowColor: WidgetStateProperty.all(cs.surfaceContainerLow),
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('เดือน')),
                          DataColumn(label: Text('เที่ยว'), numeric: true),
                          DataColumn(label: Text('รายรับ'), numeric: true),
                          DataColumn(label: Text('น้ำมัน'), numeric: true),
                          DataColumn(label: Text('ทางด่วน'), numeric: true),
                          DataColumn(label: Text('ซ่อมบำรุง'), numeric: true),
                          DataColumn(label: Text('คนขับ'), numeric: true),
                          DataColumn(label: Text('อื่นๆ'), numeric: true),
                          DataColumn(label: Text('ต้นทุนรวม'), numeric: true),
                          DataColumn(label: Text('กำไร'), numeric: true),
                          DataColumn(label: Text('Margin'), numeric: true),
                        ],
                        rows: [
                          ...data.map((d) {
                            final margin = double.tryParse(d['margin']!) ?? 0;
                            return DataRow(cells: [
                              DataCell(Text(d['month']!, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(d['trips']!)),
                              DataCell(Text('฿${d['revenue']!}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold))),
                              DataCell(Text('฿${d['fuel']!}')),
                              DataCell(Text('฿${d['toll']!}')),
                              DataCell(Text('฿${d['maintenance']!}',
                                  style: TextStyle(color: d['maintenance'] == '0' ? Colors.grey[400] : Colors.red[600]))),
                              DataCell(Text('฿${d['driver']!}')),
                              DataCell(Text('฿${d['other']!}')),
                              DataCell(Text('฿${d['total_cost']!}', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('฿${d['profit']!}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary))),
                              DataCell(_MarginBadge(margin: margin)),
                            ]);
                          }),
                          // Total row
                          DataRow(
                            color: WidgetStateProperty.all(cs.surfaceContainerLow),
                            cells: [
                              const DataCell(Text('รวม', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('${data.fold(0, (s, d) => s + _parseAmount(d['trips']!))}')),
                              DataCell(Text('฿${_formatAmount(totalRevenue)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]))),
                              DataCell(Text('฿${_formatAmount(data.fold(0, (s, d) => s + _parseAmount(d['fuel']!)))}')),
                              DataCell(Text('฿${_formatAmount(data.fold(0, (s, d) => s + _parseAmount(d['toll']!)))}')),
                              DataCell(Text('฿${_formatAmount(data.fold(0, (s, d) => s + _parseAmount(d['maintenance']!)))}')),
                              DataCell(Text('฿${_formatAmount(data.fold(0, (s, d) => s + _parseAmount(d['driver']!)))}')),
                              DataCell(Text('฿${_formatAmount(data.fold(0, (s, d) => s + _parseAmount(d['other']!)))}')),
                              DataCell(Text('฿${_formatAmount(totalCost)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('฿${_formatAmount(totalProfit)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary))),
                              DataCell(_MarginBadge(margin: avgMargin)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(ColorScheme cs, String label, String value, Color color, IconData icon) {
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
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarginBadge extends StatelessWidget {
  final double margin;
  const _MarginBadge({required this.margin});

  @override
  Widget build(BuildContext context) {
    final color = margin >= 65 ? Colors.green : margin >= 60 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${margin.toStringAsFixed(1)}%',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
