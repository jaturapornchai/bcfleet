import 'package:flutter/material.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  String _search = '';
  String _filterStatus = 'all';
  String _filterType = 'all';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;
  int _currentPage = 0;

  final _vehicles = [
    {'id': '1', 'plate': 'กท-1234', 'brand': 'ISUZU', 'model': 'FRR 210', 'type': '6ล้อ', 'year': '2023', 'driver': 'สมชาย ใจดี', 'mileage': '85,000', 'status': 'active', 'health': 'green', 'ownership': 'own'},
    {'id': '2', 'plate': '2กร-5678', 'brand': 'HINO', 'model': '500', 'type': '10ล้อ', 'year': '2022', 'driver': 'วิชัย ขับดี', 'mileage': '120,500', 'status': 'active', 'health': 'yellow', 'ownership': 'partner'},
    {'id': '3', 'plate': 'ชม-3456', 'brand': 'ISUZU', 'model': 'NQR', 'type': '6ล้อ', 'year': '2021', 'driver': 'สมศักดิ์ รักงาน', 'mileage': '95,200', 'status': 'maintenance', 'health': 'red', 'ownership': 'own'},
    {'id': '4', 'plate': 'กน-7890', 'brand': 'HINO', 'model': 'Dutro', 'type': '4ล้อ', 'year': '2024', 'driver': 'ประสิทธิ์ มีน้ำใจ', 'mileage': '22,100', 'status': 'active', 'health': 'green', 'ownership': 'own'},
    {'id': '5', 'plate': 'ลป-1122', 'brand': 'FUSO', 'model': 'Canter', 'type': '4ล้อ', 'year': '2023', 'driver': 'อนุชา ตั้งใจ', 'mileage': '45,600', 'status': 'active', 'health': 'green', 'ownership': 'rental'},
    {'id': '6', 'plate': 'พย-3344', 'brand': 'ISUZU', 'model': 'GXZ', 'type': 'หัวลาก', 'year': '2020', 'driver': 'วีระ ขยัน', 'mileage': '230,000', 'status': 'inactive', 'health': 'red', 'ownership': 'own'},
  ];

  List<Map<String, String>> get _filtered => _vehicles.where((v) {
    final matchSearch = _search.isEmpty ||
        v['plate']!.contains(_search) ||
        v['brand']!.contains(_search) ||
        v['driver']!.contains(_search);
    final matchStatus = _filterStatus == 'all' || v['status'] == _filterStatus;
    final matchType = _filterType == 'all' || v['type'] == _filterType;
    return matchSearch && matchStatus && matchType;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final pageStart = _currentPage * _rowsPerPage;
    final pageEnd = (pageStart + _rowsPerPage).clamp(0, filtered.length);
    final pageRows = filtered.sublist(pageStart, pageEnd);
    final totalPages = (filtered.length / _rowsPerPage).ceil();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('ทะเบียนรถทั้งหมด', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มรถ'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters Row
          Row(
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาทะเบียน / ยี่ห้อ / คนขับ...',
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
                  DropdownMenuItem(value: 'active', child: Text('ใช้งาน')),
                  DropdownMenuItem(value: 'maintenance', child: Text('ซ่อมบำรุง')),
                  DropdownMenuItem(value: 'inactive', child: Text('ไม่ใช้งาน')),
                ],
                onChanged: (v) => setState(() { _filterStatus = v!; _currentPage = 0; }),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filterType,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('ทุกประเภท')),
                  DropdownMenuItem(value: '4ล้อ', child: Text('4 ล้อ')),
                  DropdownMenuItem(value: '6ล้อ', child: Text('6 ล้อ')),
                  DropdownMenuItem(value: '10ล้อ', child: Text('10 ล้อ')),
                  DropdownMenuItem(value: 'หัวลาก', child: Text('หัวลาก')),
                ],
                onChanged: (v) => setState(() { _filterType = v!; _currentPage = 0; }),
              ),
              const Spacer(),
              Text('${filtered.length} รายการ', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),

          // Table
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
                          DataColumn(label: const Text('ทะเบียน'), onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })),
                          DataColumn(label: const Text('ยี่ห้อ / รุ่น'), onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })),
                          DataColumn(label: const Text('ประเภท')),
                          DataColumn(label: const Text('ปี')),
                          DataColumn(label: const Text('คนขับประจำ')),
                          DataColumn(label: const Text('เลขไมล์'), numeric: true),
                          DataColumn(label: const Text('ประเภทการเป็นเจ้าของ')),
                          DataColumn(label: const Text('สุขภาพรถ')),
                          DataColumn(label: const Text('สถานะ')),
                          DataColumn(label: const Text('จัดการ')),
                        ],
                        rows: pageRows.map((v) => DataRow(
                          cells: [
                            DataCell(Text(v['plate']!, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(v['brand']!, style: const TextStyle(fontSize: 13)),
                                Text(v['model']!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            )),
                            DataCell(Text(v['type']!)),
                            DataCell(Text(v['year']!)),
                            DataCell(Text(v['driver']!)),
                            DataCell(Text('${v['mileage']!} กม.')),
                            DataCell(_OwnershipChip(ownership: v['ownership']!)),
                            DataCell(_HealthDot(health: v['health']!)),
                            DataCell(_StatusChip(status: v['status']!)),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () {}, tooltip: 'ดูรายละเอียด'),
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {}, tooltip: 'แก้ไข'),
                              ],
                            )),
                          ],
                        )).toList(),
                      ),
                    ),
                  ),
                  // Pagination
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
}

class _HealthDot extends StatelessWidget {
  final String health;
  const _HealthDot({required this.health});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (health) {
      'green' => ('ปกติ', Colors.green),
      'yellow' => ('เฝ้าระวัง', Colors.orange),
      _ => ('วิกฤต', Colors.red),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('ใช้งาน', Colors.green),
      'maintenance' => ('ซ่อมบำรุง', Colors.orange),
      _ => ('ไม่ใช้งาน', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _OwnershipChip extends StatelessWidget {
  final String ownership;
  const _OwnershipChip({required this.ownership});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (ownership) {
      'own' => ('รถตัวเอง', Colors.blue),
      'partner' => ('รถร่วม', Colors.purple),
      _ => ('เช่า', Colors.teal),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
