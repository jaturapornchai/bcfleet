import 'package:flutter/material.dart';

class CostOverviewScreen extends StatefulWidget {
  const CostOverviewScreen({super.key});

  @override
  State<CostOverviewScreen> createState() => _CostOverviewScreenState();
}

class _CostOverviewScreenState extends State<CostOverviewScreen> {
  String _filterMonth = '03/2569';
  String _filterVehicle = 'all';
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  final _costs = [
    {'id': '1', 'vehicle': 'กท-1234', 'type': 'ISUZU FRR 210', 'trips': '12', 'revenue': '48,000', 'fuel': '9,600', 'toll': '720', 'maintenance': '4,040', 'driver': '3,600', 'other': '500', 'total_cost': '18,460', 'profit': '29,540', 'margin': '61.5', 'month': '03/2569'},
    {'id': '2', 'vehicle': '2กร-5678', 'type': 'HINO 500', 'trips': '8', 'revenue': '64,000', 'fuel': '14,400', 'toll': '960', 'maintenance': '0', 'driver': '2,400', 'other': '200', 'total_cost': '17,960', 'profit': '46,040', 'margin': '71.9', 'month': '03/2569'},
    {'id': '3', 'vehicle': 'ชม-3456', 'type': 'ISUZU NQR', 'trips': '15', 'revenue': '37,500', 'fuel': '8,250', 'toll': '450', 'maintenance': '1,200', 'driver': '4,500', 'other': '300', 'total_cost': '14,700', 'profit': '22,800', 'margin': '60.8', 'month': '03/2569'},
    {'id': '4', 'vehicle': 'กน-7890', 'type': 'HINO 700', 'trips': '6', 'revenue': '72,000', 'fuel': '18,000', 'toll': '1,200', 'maintenance': '8,500', 'driver': '1,800', 'other': '600', 'total_cost': '30,100', 'profit': '41,900', 'margin': '58.2', 'month': '03/2569'},
    {'id': '5', 'vehicle': 'ลป-1122', 'type': 'ISUZU FTR', 'trips': '10', 'revenue': '40,000', 'fuel': '10,000', 'toll': '600', 'maintenance': '2,500', 'driver': '3,000', 'other': '400', 'total_cost': '16,500', 'profit': '23,500', 'margin': '58.8', 'month': '03/2569'},
    {'id': '6', 'vehicle': 'พย-3344', 'type': 'ISUZU FVR', 'trips': '9', 'revenue': '36,000', 'fuel': '7,200', 'toll': '540', 'maintenance': '0', 'driver': '2,700', 'other': '150', 'total_cost': '10,590', 'profit': '25,410', 'margin': '70.6', 'month': '03/2569'},
    {'id': '7', 'vehicle': 'กท-1234', 'type': 'ISUZU FRR 210', 'trips': '10', 'revenue': '40,000', 'fuel': '8,000', 'toll': '600', 'maintenance': '0', 'driver': '3,000', 'other': '400', 'total_cost': '12,000', 'profit': '28,000', 'margin': '70.0', 'month': '02/2569'},
    {'id': '8', 'vehicle': '2กร-5678', 'type': 'HINO 500', 'trips': '7', 'revenue': '56,000', 'fuel': '12,600', 'toll': '840', 'maintenance': '6,200', 'driver': '2,100', 'other': '300', 'total_cost': '22,040', 'profit': '33,960', 'margin': '60.6', 'month': '02/2569'},
  ];

  List<Map<String, String>> get _filtered => _costs.where((c) {
    final matchMonth = _filterMonth == 'all' || c['month'] == _filterMonth;
    final matchVehicle = _filterVehicle == 'all' || c['vehicle'] == _filterVehicle;
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

    final totalRevenue = filtered.fold(0, (sum, c) => sum + _parseAmount(c['revenue']!));
    final totalCost = filtered.fold(0, (sum, c) => sum + _parseAmount(c['total_cost']!));
    final totalProfit = filtered.fold(0, (sum, c) => sum + _parseAmount(c['profit']!));
    final totalFuel = filtered.fold(0, (sum, c) => sum + _parseAmount(c['fuel']!));

    final vehicles = _costs.map((c) => c['vehicle']!).toSet().toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ภาพรวมต้นทุน', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
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
              _buildSummaryCard(cs, 'รายรับรวม', '฿${_formatAmount(totalRevenue)}', Colors.green, Icons.trending_up),
              const SizedBox(width: 12),
              _buildSummaryCard(cs, 'ต้นทุนรวม', '฿${_formatAmount(totalCost)}', Colors.red, Icons.trending_down),
              const SizedBox(width: 12),
              _buildSummaryCard(cs, 'กำไรรวม', '฿${_formatAmount(totalProfit)}', cs.primary, Icons.account_balance_wallet_outlined),
              const SizedBox(width: 12),
              _buildSummaryCard(cs, 'ค่าน้ำมันรวม', '฿${_formatAmount(totalFuel)}', Colors.orange, Icons.local_gas_station_outlined),
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
                          DataColumn(label: Text('รถ')),
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
                          DataColumn(label: Text('Margin %'), numeric: true),
                        ],
                        rows: pageRows.map((c) {
                          final margin = double.tryParse(c['margin']!) ?? 0;
                          final isLowMargin = margin < 60;
                          return DataRow(
                            color: isLowMargin ? WidgetStateProperty.all(Colors.orange.withValues(alpha: 0.05)) : null,
                            cells: [
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(c['vehicle']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(c['type']!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                ],
                              )),
                              DataCell(Text(c['month']!, style: const TextStyle(fontSize: 12))),
                              DataCell(Text(c['trips']!)),
                              DataCell(Text('฿${c['revenue']!}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]))),
                              DataCell(Text('฿${c['fuel']!}')),
                              DataCell(Text('฿${c['toll']!}')),
                              DataCell(Text('฿${c['maintenance']!}', style: TextStyle(color: c['maintenance'] == '0' ? Colors.grey[400] : Colors.red[600]))),
                              DataCell(Text('฿${c['driver']!}')),
                              DataCell(Text('฿${c['other']!}')),
                              DataCell(Text('฿${c['total_cost']!}', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('฿${c['profit']!}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary))),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (margin >= 65 ? Colors.green : margin >= 60 ? Colors.orange : Colors.red).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${c['margin']!}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: margin >= 65 ? Colors.green[700] : margin >= 60 ? Colors.orange[700] : Colors.red[700],
                                  ),
                                ),
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

  Widget _buildSummaryCard(ColorScheme cs, String label, String value, Color color, IconData icon) {
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
