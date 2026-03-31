import 'package:flutter/material.dart';

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key});

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  String _search = '';
  String _filterStatus = 'all';
  String _filterType = 'all';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;
  int _currentPage = 0;

  final _drivers = [
    {'id': '1', 'employee_id': 'EMP-001', 'name': 'สมชาย ใจดี', 'phone': '081-234-5678', 'license_type': 'ท.2', 'license_expiry': '01/01/2026', 'type': 'permanent', 'vehicle': 'กท-1234', 'status': 'active', 'score': '92', 'trips': '450', 'on_time': '95%'},
    {'id': '2', 'employee_id': 'EMP-002', 'name': 'วิชัย ขับดี', 'phone': '089-567-8901', 'license_type': 'ท.2', 'license_expiry': '15/06/2025', 'type': 'permanent', 'vehicle': '2กร-5678', 'status': 'active', 'score': '88', 'trips': '320', 'on_time': '92%'},
    {'id': '3', 'employee_id': 'EMP-003', 'name': 'สมศักดิ์ รักงาน', 'phone': '082-345-6789', 'license_type': 'ท.3', 'license_expiry': '20/03/2025', 'type': 'permanent', 'vehicle': 'ชม-3456', 'status': 'on_leave', 'score': '79', 'trips': '280', 'on_time': '89%'},
    {'id': '4', 'employee_id': 'EMP-004', 'name': 'ประสิทธิ์ มีน้ำใจ', 'phone': '083-456-7890', 'license_type': 'ท.1', 'license_expiry': '10/08/2026', 'type': 'permanent', 'vehicle': 'กน-7890', 'status': 'active', 'score': '95', 'trips': '510', 'on_time': '98%'},
    {'id': '5', 'employee_id': 'EMP-005', 'name': 'อนุชา ตั้งใจ', 'phone': '084-567-8901', 'license_type': 'ท.2', 'license_expiry': '05/11/2025', 'type': 'contract', 'vehicle': 'ลป-1122', 'status': 'active', 'score': '83', 'trips': '195', 'on_time': '91%'},
    {'id': '6', 'employee_id': 'EMP-006', 'name': 'วีระ ขยัน', 'phone': '085-678-9012', 'license_type': 'ท.2', 'license_expiry': '30/09/2024', 'type': 'daily', 'vehicle': 'พย-3344', 'status': 'suspended', 'score': '55', 'trips': '120', 'on_time': '78%'},
  ];

  List<Map<String, String>> get _filtered => _drivers.where((d) {
    final matchSearch = _search.isEmpty ||
        d['name']!.contains(_search) ||
        d['employee_id']!.contains(_search) ||
        d['phone']!.contains(_search);
    final matchStatus = _filterStatus == 'all' || d['status'] == _filterStatus;
    final matchType = _filterType == 'all' || d['type'] == _filterType;
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
              Text('รายการคนขับรถ', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มคนขับ'),
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
                    hintText: 'ค้นหาชื่อ / รหัส / เบอร์โทร...',
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
                  DropdownMenuItem(value: 'active', child: Text('ปฏิบัติงาน')),
                  DropdownMenuItem(value: 'on_leave', child: Text('ลา')),
                  DropdownMenuItem(value: 'suspended', child: Text('พักงาน')),
                ],
                onChanged: (v) => setState(() { _filterStatus = v!; _currentPage = 0; }),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filterType,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('ทุกประเภท')),
                  DropdownMenuItem(value: 'permanent', child: Text('พนักงานประจำ')),
                  DropdownMenuItem(value: 'contract', child: Text('สัญญาจ้าง')),
                  DropdownMenuItem(value: 'daily', child: Text('รายวัน')),
                  DropdownMenuItem(value: 'partner', child: Text('รถร่วม')),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: DataTable(
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        headingRowColor: WidgetStateProperty.all(cs.surfaceContainerLow),
                        columns: [
                          DataColumn(label: const Text('รหัส'), onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })),
                          DataColumn(label: const Text('ชื่อ-นามสกุล'), onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })),
                          DataColumn(label: const Text('เบอร์โทร')),
                          DataColumn(label: const Text('ใบขับขี่')),
                          DataColumn(label: const Text('ประเภท')),
                          DataColumn(label: const Text('รถที่รับผิดชอบ')),
                          DataColumn(label: const Text('คะแนน'), numeric: true, onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })),
                          DataColumn(label: const Text('เที่ยวรวม'), numeric: true),
                          DataColumn(label: const Text('ตรงเวลา')),
                          DataColumn(label: const Text('สถานะ')),
                          DataColumn(label: const Text('จัดการ')),
                        ],
                        rows: pageRows.map((d) => DataRow(cells: [
                          DataCell(Text(d['employee_id']!, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                          DataCell(Text(d['name']!, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(d['phone']!, style: const TextStyle(fontSize: 12))),
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(d['license_type']!, style: const TextStyle(fontSize: 13)),
                              Text('หมดอายุ ${d['license_expiry']!}', style: TextStyle(fontSize: 10, color: _isLicenseExpiring(d['license_expiry']!) ? Colors.red : Colors.grey[500])),
                            ],
                          )),
                          DataCell(_DriverTypeChip(type: d['type']!)),
                          DataCell(Text(d['vehicle']!, style: const TextStyle(fontSize: 12))),
                          DataCell(_ScoreBadge(score: int.parse(d['score']!))),
                          DataCell(Text(d['trips']!)),
                          DataCell(Text(d['on_time']!, style: const TextStyle(fontSize: 12))),
                          DataCell(_DriverStatusChip(status: d['status']!)),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () {}, tooltip: 'ดูรายละเอียด'),
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
                        Text('แถวต่อหน้า: ', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                        DropdownButton<int>(
                          value: _rowsPerPage,
                          underline: const SizedBox(),
                          items: [10, 25, 50].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                          onChanged: (v) => setState(() { _rowsPerPage = v!; _currentPage = 0; }),
                        ),
                        const Spacer(),
                        Text('หน้า ${_currentPage + 1} จาก $totalPages', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                        const SizedBox(width: 8),
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

  bool _isLicenseExpiring(String dateStr) {
    try {
      final parts = dateStr.split('/');
      final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      return date.isBefore(DateTime.now().add(const Duration(days: 60)));
    } catch (_) { return false; }
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 90 ? Colors.green : score >= 75 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text('$score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _DriverStatusChip extends StatelessWidget {
  final String status;
  const _DriverStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('ปฏิบัติงาน', Colors.green),
      'on_leave' => ('ลา', Colors.orange),
      'suspended' => ('พักงาน', Colors.red),
      _ => ('ลาออก', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _DriverTypeChip extends StatelessWidget {
  final String type;
  const _DriverTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'permanent' => ('ประจำ', Colors.blue),
      'contract' => ('สัญญา', Colors.purple),
      'daily' => ('รายวัน', Colors.teal),
      _ => ('รถร่วม', Colors.brown),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
