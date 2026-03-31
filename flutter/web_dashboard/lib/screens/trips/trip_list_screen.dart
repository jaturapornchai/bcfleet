import 'package:flutter/material.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  String _search = '';
  String _filterStatus = 'all';
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  final _trips = [
    {'id': '1', 'trip_no': 'TRIP-2026-001234', 'origin': 'คลังสินค้า ABC', 'dest': 'ร้าน XYZ ลำพูน', 'driver': 'สมชาย ใจดี', 'plate': 'กท-1234', 'status': 'in_progress', 'revenue': '2,500', 'date': '31/03/2569', 'is_partner': 'false'},
    {'id': '2', 'trip_no': 'TRIP-2026-001233', 'origin': 'โรงงาน DEF', 'dest': 'ห้าง GHI เชียงราย', 'driver': 'วิชัย ขับดี', 'plate': '2กร-5678', 'status': 'completed', 'revenue': '5,800', 'date': '31/03/2569', 'is_partner': 'false'},
    {'id': '3', 'trip_no': 'TRIP-2026-001232', 'origin': 'ท่าเรือ JKL', 'dest': 'ศูนย์กระจายสินค้า', 'driver': 'สมศักดิ์ รักงาน', 'plate': 'ชม-3456', 'status': 'pending', 'revenue': '3,200', 'date': '31/03/2569', 'is_partner': 'false'},
    {'id': '4', 'trip_no': 'TRIP-2026-001231', 'origin': 'คลัง MNO', 'dest': 'ลูกค้า PQR ลำปาง', 'driver': 'ประสิทธิ์ มีน้ำใจ', 'plate': 'กน-7890', 'status': 'completed', 'revenue': '4,100', 'date': '30/03/2569', 'is_partner': 'false'},
    {'id': '5', 'trip_no': 'TRIP-2026-001230', 'origin': 'สำนักงานใหญ่', 'dest': 'ลูกค้า STU เชียงใหม่', 'driver': 'อนุชา ตั้งใจ', 'plate': 'ลป-1122', 'status': 'started', 'revenue': '1,800', 'date': '30/03/2569', 'is_partner': 'false'},
    {'id': '6', 'trip_no': 'TRIP-2026-001229', 'origin': 'โรงงาน ABC', 'dest': 'ห้าง XYZ พะเยา', 'driver': 'วีระ ขยัน', 'plate': '2กร-5678', 'status': 'cancelled', 'revenue': '6,000', 'date': '29/03/2569', 'is_partner': 'true'},
  ];

  List<Map<String, String>> get _filtered => _trips.where((t) {
    final matchSearch = _search.isEmpty ||
        t['trip_no']!.contains(_search) ||
        t['origin']!.contains(_search) ||
        t['dest']!.contains(_search) ||
        t['driver']!.contains(_search);
    final matchStatus = _filterStatus == 'all' || t['status'] == _filterStatus;
    return matchSearch && matchStatus;
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
              Text('รายการเที่ยววิ่ง', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('สร้างเที่ยวใหม่'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาเลขที่เที่ยว / ต้นทาง / ปลายทาง...',
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
                  DropdownMenuItem(value: 'pending', child: Text('รอดำเนินการ')),
                  DropdownMenuItem(value: 'started', child: Text('กำลังวิ่ง')),
                  DropdownMenuItem(value: 'in_progress', child: Text('กำลังส่ง')),
                  DropdownMenuItem(value: 'completed', child: Text('เสร็จสิ้น')),
                  DropdownMenuItem(value: 'cancelled', child: Text('ยกเลิก')),
                ],
                onChanged: (v) => setState(() { _filterStatus = v!; _currentPage = 0; }),
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
                          DataColumn(label: Text('เลขที่เที่ยว')),
                          DataColumn(label: Text('วันที่')),
                          DataColumn(label: Text('ต้นทาง')),
                          DataColumn(label: Text('ปลายทาง')),
                          DataColumn(label: Text('คนขับ / รถ')),
                          DataColumn(label: Text('ประเภท')),
                          DataColumn(label: Text('สถานะ')),
                          DataColumn(label: Text('รายได้'), numeric: true),
                          DataColumn(label: Text('จัดการ')),
                        ],
                        rows: pageRows.map((t) => DataRow(cells: [
                          DataCell(Text(t['trip_no']!, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
                          DataCell(Text(t['date']!, style: const TextStyle(fontSize: 12))),
                          DataCell(Text(t['origin']!)),
                          DataCell(Text(t['dest']!)),
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t['driver']!, style: const TextStyle(fontSize: 12)),
                              Text(t['plate']!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            ],
                          )),
                          DataCell(t['is_partner'] == 'true'
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                  child: const Text('รถร่วม', style: TextStyle(fontSize: 11, color: Colors.purple)),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                  child: const Text('รถตัวเอง', style: TextStyle(fontSize: 11, color: Colors.blue)),
                                )),
                          DataCell(_TripStatusChip(status: t['status']!)),
                          DataCell(Text('฿${t['revenue']!}')),
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

class _TripStatusChip extends StatelessWidget {
  final String status;
  const _TripStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'completed' => ('เสร็จสิ้น', Colors.green),
      'in_progress' || 'started' => ('กำลังวิ่ง', Colors.blue),
      'pending' => ('รอดำเนินการ', Colors.orange),
      'cancelled' => ('ยกเลิก', Colors.red),
      _ => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
