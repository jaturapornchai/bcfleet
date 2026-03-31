import 'package:flutter/material.dart';

class WorkOrderListScreen extends StatefulWidget {
  const WorkOrderListScreen({super.key});

  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  String _search = '';
  String _filterStatus = 'all';
  String _filterType = 'all';
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  final _workOrders = [
    {'id': '1', 'wo_no': 'WO-2026-000123', 'vehicle': 'กท-1234', 'type': 'preventive', 'priority': 'medium', 'status': 'completed', 'desc': 'เปลี่ยนน้ำมันเครื่อง + กรอง', 'cost': '4,040', 'date': '10/03/2569', 'provider': 'ช่างสมศักดิ์'},
    {'id': '2', 'wo_no': 'WO-2026-000124', 'vehicle': '2กร-5678', 'type': 'corrective', 'priority': 'high', 'status': 'in_progress', 'desc': 'ซ่อมระบบเบรค', 'cost': '8,500', 'date': '28/03/2569', 'provider': 'อู่ซ่อมรถนิยม'},
    {'id': '3', 'wo_no': 'WO-2026-000125', 'vehicle': 'ชม-3456', 'type': 'preventive', 'priority': 'low', 'status': 'pending_approval', 'desc': 'เปลี่ยนยาง 4 เส้น', 'cost': '12,000', 'date': '30/03/2569', 'provider': 'ร้านยางดี'},
    {'id': '4', 'wo_no': 'WO-2026-000126', 'vehicle': 'กน-7890', 'type': 'emergency', 'priority': 'critical', 'status': 'approved', 'desc': 'เครื่องยนต์ดับกลางทาง', 'cost': '25,000', 'date': '31/03/2569', 'provider': 'อู่ใหญ่เชียงใหม่'},
    {'id': '5', 'wo_no': 'WO-2026-000122', 'vehicle': 'ลป-1122', 'type': 'preventive', 'priority': 'medium', 'status': 'completed', 'desc': 'ตรวจเช็คระยะ 50,000 กม.', 'cost': '6,200', 'date': '05/03/2569', 'provider': 'ศูนย์บริการ ISUZU'},
    {'id': '6', 'wo_no': 'WO-2026-000121', 'vehicle': 'พย-3344', 'type': 'corrective', 'priority': 'medium', 'status': 'cancelled', 'desc': 'ซ่อมระบบไฟฟ้า', 'cost': '3,500', 'date': '01/03/2569', 'provider': 'ช่างไฟนคร'},
  ];

  List<Map<String, String>> get _filtered => _workOrders.where((w) {
    final matchSearch = _search.isEmpty ||
        w['wo_no']!.contains(_search) ||
        w['vehicle']!.contains(_search) ||
        w['desc']!.contains(_search);
    final matchStatus = _filterStatus == 'all' || w['status'] == _filterStatus;
    final matchType = _filterType == 'all' || w['type'] == _filterType;
    return matchSearch && matchStatus && matchType;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final pageStart = _currentPage * _rowsPerPage;
    final pageEnd = (pageStart + _rowsPerPage).clamp(0, filtered.length);
    final pageRows = filtered.sublist(pageStart, pageEnd);
    final totalPages = (filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ใบสั่งซ่อม', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('สร้างใบสั่งซ่อม'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาเลขที่ / รถ / รายละเอียด...',
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
                value: _filterStatus,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('ทุกสถานะ')),
                  DropdownMenuItem(value: 'pending_approval', child: Text('รออนุมัติ')),
                  DropdownMenuItem(value: 'approved', child: Text('อนุมัติแล้ว')),
                  DropdownMenuItem(value: 'in_progress', child: Text('กำลังซ่อม')),
                  DropdownMenuItem(value: 'completed', child: Text('เสร็จสิ้น')),
                  DropdownMenuItem(value: 'cancelled', child: Text('ยกเลิก')),
                ],
                onChanged: (v) => setState(() { _filterStatus = v!; _currentPage = 0; }),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filterType,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('ทุกประเภท')),
                  DropdownMenuItem(value: 'preventive', child: Text('ซ่อมบำรุงตามกำหนด')),
                  DropdownMenuItem(value: 'corrective', child: Text('ซ่อมแก้ไข')),
                  DropdownMenuItem(value: 'emergency', child: Text('ฉุกเฉิน')),
                ],
                onChanged: (v) => setState(() { _filterType = v!; _currentPage = 0; }),
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
                          DataColumn(label: Text('เลขที่ใบสั่งซ่อม')),
                          DataColumn(label: Text('วันที่')),
                          DataColumn(label: Text('รถ')),
                          DataColumn(label: Text('ประเภท')),
                          DataColumn(label: Text('ความเร่งด่วน')),
                          DataColumn(label: Text('รายละเอียด')),
                          DataColumn(label: Text('อู่/ช่าง')),
                          DataColumn(label: Text('ค่าใช้จ่าย'), numeric: true),
                          DataColumn(label: Text('สถานะ')),
                          DataColumn(label: Text('จัดการ')),
                        ],
                        rows: pageRows.map((w) => DataRow(cells: [
                          DataCell(Text(w['wo_no']!, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
                          DataCell(Text(w['date']!, style: const TextStyle(fontSize: 12))),
                          DataCell(Text(w['vehicle']!, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(_WOTypeChip(type: w['type']!)),
                          DataCell(_PriorityChip(priority: w['priority']!)),
                          DataCell(SizedBox(width: 180, child: Text(w['desc']!, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))),
                          DataCell(Text(w['provider']!, style: const TextStyle(fontSize: 12))),
                          DataCell(Text('฿${w['cost']!}')),
                          DataCell(_WOStatusChip(status: w['status']!)),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () {}, tooltip: 'ดูรายละเอียด'),
                              if (w['status'] == 'pending_approval')
                                IconButton(icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.green), onPressed: () {}, tooltip: 'อนุมัติ'),
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {}, tooltip: 'แก้ไข'),
                            ],
                          )),
                        ])).toList(),
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
}

class _WOTypeChip extends StatelessWidget {
  final String type;
  const _WOTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'preventive' => ('บำรุงรักษา', Colors.blue),
      'corrective' => ('ซ่อมแก้ไข', Colors.orange),
      'emergency' => ('ฉุกเฉิน', Colors.red),
      _ => (type, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      'low' => ('ต่ำ', Colors.grey),
      'medium' => ('ปานกลาง', Colors.blue),
      'high' => ('สูง', Colors.orange),
      'critical' => ('วิกฤต', Colors.red),
      _ => (priority, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _WOStatusChip extends StatelessWidget {
  final String status;
  const _WOStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending_approval' => ('รออนุมัติ', Colors.orange),
      'approved' => ('อนุมัติแล้ว', Colors.blue),
      'in_progress' => ('กำลังซ่อม', Colors.purple),
      'completed' => ('เสร็จสิ้น', Colors.green),
      'cancelled' => ('ยกเลิก', Colors.grey),
      _ => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
