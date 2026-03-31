import 'package:flutter/material.dart';

class PartsInventoryScreen extends StatefulWidget {
  const PartsInventoryScreen({super.key});

  @override
  State<PartsInventoryScreen> createState() => _PartsInventoryScreenState();
}

class _PartsInventoryScreenState extends State<PartsInventoryScreen> {
  String _search = '';
  String _filterCategory = 'all';
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  final _parts = [
    {'id': '1', 'part_no': 'PART-001', 'name': 'น้ำมันเครื่อง SHELL Rimula R4 15W-40', 'category': 'น้ำมันหล่อลื่น', 'unit': 'ลิตร', 'qty': '40', 'min_qty': '16', 'unit_cost': '280', 'supplier': 'Shell Thailand', 'location': 'A-01', 'status': 'ok'},
    {'id': '2', 'part_no': 'PART-002', 'name': 'กรองน้ำมันเครื่อง ISUZU', 'category': 'ไส้กรอง', 'unit': 'ชิ้น', 'qty': '8', 'min_qty': '5', 'unit_cost': '350', 'supplier': 'ISUZU Parts', 'location': 'B-03', 'status': 'ok'},
    {'id': '3', 'part_no': 'PART-003', 'name': 'กรองอากาศ HINO 500', 'category': 'ไส้กรอง', 'unit': 'ชิ้น', 'qty': '3', 'min_qty': '4', 'unit_cost': '450', 'supplier': 'HINO Parts', 'location': 'B-04', 'status': 'low'},
    {'id': '4', 'part_no': 'PART-004', 'name': 'น้ำมันเกียร์ 80W-90', 'category': 'น้ำมันหล่อลื่น', 'unit': 'ลิตร', 'qty': '0', 'min_qty': '10', 'unit_cost': '180', 'supplier': 'PTT Lubricants', 'location': 'A-02', 'status': 'out'},
    {'id': '5', 'part_no': 'PART-005', 'name': 'ผ้าเบรคหน้า ISUZU FRR', 'category': 'ระบบเบรค', 'unit': 'ชุด', 'qty': '2', 'min_qty': '2', 'unit_cost': '2200', 'supplier': 'ISUZU Parts', 'location': 'C-01', 'status': 'ok'},
    {'id': '6', 'part_no': 'PART-006', 'name': 'หลอดไฟหน้า H4 12V/60W', 'category': 'ระบบไฟฟ้า', 'unit': 'หลอด', 'qty': '12', 'min_qty': '6', 'unit_cost': '120', 'supplier': 'OSRAM Thailand', 'location': 'D-02', 'status': 'ok'},
    {'id': '7', 'part_no': 'PART-007', 'name': 'สายพานไทม์มิ่ง ISUZU 4HK1', 'category': 'เครื่องยนต์', 'unit': 'เส้น', 'qty': '1', 'min_qty': '2', 'unit_cost': '3500', 'supplier': 'ISUZU Parts', 'location': 'E-01', 'status': 'low'},
    {'id': '8', 'part_no': 'PART-008', 'name': 'น้ำยาหม้อน้ำ', 'category': 'ระบบหล่อเย็น', 'unit': 'ลิตร', 'qty': '20', 'min_qty': '10', 'unit_cost': '85', 'supplier': 'PRESTONE', 'location': 'A-03', 'status': 'ok'},
    {'id': '9', 'part_no': 'PART-009', 'name': 'แบตเตอรี่ 12V 100Ah', 'category': 'ระบบไฟฟ้า', 'unit': 'ลูก', 'qty': '2', 'min_qty': '2', 'unit_cost': '3800', 'supplier': 'GS Battery', 'location': 'D-01', 'status': 'ok'},
    {'id': '10', 'part_no': 'PART-010', 'name': 'ยาง Bridgestone 10.00R20', 'category': 'ยาง', 'unit': 'เส้น', 'qty': '4', 'min_qty': '4', 'unit_cost': '8500', 'supplier': 'Bridgestone', 'location': 'F-01', 'status': 'ok'},
    {'id': '11', 'part_no': 'PART-011', 'name': 'กรองเชื้อเพลิง ISUZU', 'category': 'ไส้กรอง', 'unit': 'ชิ้น', 'qty': '5', 'min_qty': '3', 'unit_cost': '280', 'supplier': 'ISUZU Parts', 'location': 'B-05', 'status': 'ok'},
    {'id': '12', 'part_no': 'PART-012', 'name': 'น้ำมันไฮดรอลิค', 'category': 'น้ำมันหล่อลื่น', 'unit': 'ลิตร', 'qty': '0', 'min_qty': '5', 'unit_cost': '95', 'supplier': 'PTT Lubricants', 'location': 'A-04', 'status': 'out'},
  ];

  List<Map<String, String>> get _filtered => _parts.where((p) {
    final matchSearch = _search.isEmpty ||
        p['name']!.contains(_search) ||
        p['part_no']!.contains(_search) ||
        p['supplier']!.contains(_search);
    final matchCat = _filterCategory == 'all' || p['category'] == _filterCategory;
    return matchSearch && matchCat;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final pageStart = _currentPage * _rowsPerPage;
    final pageEnd = (pageStart + _rowsPerPage).clamp(0, filtered.length);
    final pageRows = filtered.sublist(pageStart, pageEnd);
    final totalPages = (filtered.length / _rowsPerPage).ceil().clamp(1, 9999);
    final outOfStock = _parts.where((p) => p['status'] == 'out').length;
    final lowStock = _parts.where((p) => p['status'] == 'low').length;

    final categories = _parts.map((p) => p['category']!).toSet().toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('สต๊อกอะไหล่', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Export'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มอะไหล่'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(cs, 'หมดสต๊อก', outOfStock, Colors.red, Icons.warning_rounded),
              const SizedBox(width: 12),
              _buildStatCard(cs, 'ใกล้หมด', lowStock, Colors.orange, Icons.inventory_2_outlined),
              const SizedBox(width: 12),
              _buildStatCard(cs, 'รายการทั้งหมด', _parts.length, cs.primary, Icons.warehouse_outlined),
              const SizedBox(width: 12),
              _buildStatCard(cs, 'มูลค่ารวม', null, Colors.green, Icons.attach_money, valueText: '฿${_calculateTotalValue()}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาชื่อ / รหัส / supplier...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() { _search = v; _currentPage = 0; }),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filterCategory,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('ทุกหมวดหมู่')),
                  ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                ],
                onChanged: (v) => setState(() { _filterCategory = v!; _currentPage = 0; }),
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
                          DataColumn(label: Text('รหัส')),
                          DataColumn(label: Text('ชื่ออะไหล่')),
                          DataColumn(label: Text('หมวดหมู่')),
                          DataColumn(label: Text('คงเหลือ'), numeric: true),
                          DataColumn(label: Text('ขั้นต่ำ'), numeric: true),
                          DataColumn(label: Text('หน่วย')),
                          DataColumn(label: Text('ราคา/หน่วย'), numeric: true),
                          DataColumn(label: Text('มูลค่า'), numeric: true),
                          DataColumn(label: Text('Supplier')),
                          DataColumn(label: Text('ที่เก็บ')),
                          DataColumn(label: Text('สถานะ')),
                          DataColumn(label: Text('จัดการ')),
                        ],
                        rows: pageRows.map((p) {
                          final qty = int.parse(p['qty']!);
                          final minQty = int.parse(p['min_qty']!);
                          final unitCost = int.parse(p['unit_cost']!);
                          final totalValue = qty * unitCost;
                          final isLow = p['status'] == 'low';
                          final isOut = p['status'] == 'out';
                          return DataRow(
                            color: isOut
                                ? WidgetStateProperty.all(Colors.red.withValues(alpha: 0.05))
                                : isLow
                                    ? WidgetStateProperty.all(Colors.orange.withValues(alpha: 0.05))
                                    : null,
                            cells: [
                              DataCell(Text(p['part_no']!, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
                              DataCell(SizedBox(width: 200, child: Text(p['name']!, style: const TextStyle(fontSize: 12)))),
                              DataCell(Text(p['category']!, style: const TextStyle(fontSize: 12))),
                              DataCell(Text(
                                '$qty',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOut ? Colors.red : isLow ? Colors.orange : null,
                                ),
                              )),
                              DataCell(Text('$minQty', style: TextStyle(color: Colors.grey[500], fontSize: 12))),
                              DataCell(Text(p['unit']!)),
                              DataCell(Text('฿${p['unit_cost']!}')),
                              DataCell(Text('฿$totalValue', style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(p['supplier']!, style: const TextStyle(fontSize: 12))),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(p['location']!, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                              )),
                              DataCell(_StockStatusChip(status: p['status']!)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
                                    onPressed: () {},
                                    tooltip: 'เติมสต๊อก',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    onPressed: () {},
                                    tooltip: 'แก้ไข',
                                  ),
                                ],
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

  String _calculateTotalValue() {
    final total = _parts.fold<int>(0, (sum, p) {
      return sum + int.parse(p['qty']!) * int.parse(p['unit_cost']!);
    });
    if (total >= 1000) {
      return '${(total / 1000).toStringAsFixed(1)}K';
    }
    return '$total';
  }

  Widget _buildStatCard(ColorScheme cs, String label, int? count, Color color, IconData icon, {String? valueText}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valueText ?? '$count',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockStatusChip extends StatelessWidget {
  final String status;
  const _StockStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'out' => ('หมดสต๊อก', Colors.red),
      'low' => ('ใกล้หมด', Colors.orange),
      'ok' => ('พอเพียง', Colors.green),
      _ => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
