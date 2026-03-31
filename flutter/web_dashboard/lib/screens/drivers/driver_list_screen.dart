import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://smlfleet.satistang.com/api/v1/fleet';

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
  bool _loading = true;

  List<Map<String, dynamic>> _drivers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_apiBase/drivers'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (mounted) {
          setState(() {
            _drivers = (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered => _drivers.where((d) {
    final name = (d['name'] as String? ?? '').toLowerCase();
    final empId = (d['employee_id'] as String? ?? '').toLowerCase();
    final phone = (d['phone'] as String? ?? '').toLowerCase();
    final search = _search.toLowerCase();
    final matchSearch = _search.isEmpty || name.contains(search) || empId.contains(search) || phone.contains(search);
    final matchStatus = _filterStatus == 'all' || d['status'] == _filterStatus;
    final empType = (d['employment'] as Map?)?['type'] as String? ?? d['employment_type'] as String? ?? '';
    final matchType = _filterType == 'all' || empType == _filterType;
    return matchSearch && matchStatus && matchType;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final filtered = _filtered;
    final pageStart = _currentPage * _rowsPerPage;
    final pageEnd = (pageStart + _rowsPerPage).clamp(0, filtered.length);
    final pageRows = filtered.sublist(pageStart, pageEnd);
    final totalPages = (filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('รายการคนขับรถ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'รีเฟรช'),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: isMobile ? const SizedBox.shrink() : const Text('เพิ่มคนขับ'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filters
          if (isMobile) ...[
            TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อ / รหัส...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() { _search = v; _currentPage = 0; }),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _filterStatus,
                    isDense: true,
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
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('ทุกประเภท')),
                      DropdownMenuItem(value: 'permanent', child: Text('ประจำ')),
                      DropdownMenuItem(value: 'contract', child: Text('สัญญา')),
                      DropdownMenuItem(value: 'daily', child: Text('รายวัน')),
                      DropdownMenuItem(value: 'partner', child: Text('รถร่วม')),
                    ],
                    onChanged: (v) => setState(() { _filterType = v!; _currentPage = 0; }),
                  ),
                  const SizedBox(width: 12),
                  Text('${filtered.length} รายการ', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
          ] else
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _drivers.isEmpty
                      ? const Center(child: Text('ไม่มีข้อมูลคนขับ', style: TextStyle(color: Colors.grey)))
                      : Column(
                          children: [
                            Expanded(
                              child: isMobile
                                  ? ListView.separated(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: pageRows.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (_, i) => _buildDriverCard(context, pageRows[i]),
                                    )
                                  : isTablet
                                      ? GridView.builder(
                                          padding: const EdgeInsets.all(12),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: 2.4,
                                          ),
                                          itemCount: pageRows.length,
                                          itemBuilder: (_, i) => _buildDriverCard(context, pageRows[i]),
                                        )
                                      : SingleChildScrollView(
                                          child: DataTable(
                                            sortColumnIndex: _sortColumnIndex,
                                            sortAscending: _sortAscending,
                                            headingRowColor: WidgetStateProperty.all(cs.surfaceContainerLow),
                                            columns: [
                                              DataColumn(label: const Text('รหัส'), onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })),
                                              DataColumn(label: const Text('ชื่อ-นามสกุล'), onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })),
                                              const DataColumn(label: Text('เบอร์โทร')),
                                              const DataColumn(label: Text('ใบขับขี่')),
                                              const DataColumn(label: Text('ประเภท')),
                                              const DataColumn(label: Text('รถที่รับผิดชอบ')),
                                              DataColumn(label: const Text('คะแนน'), numeric: true, onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })),
                                              const DataColumn(label: Text('เที่ยวรวม'), numeric: true),
                                              const DataColumn(label: Text('ตรงเวลา')),
                                              const DataColumn(label: Text('สถานะ')),
                                              const DataColumn(label: Text('จัดการ')),
                                            ],
                                            rows: pageRows.map((d) {
                                              final employment = d['employment'] as Map?;
                                              final license = d['license'] as Map?;
                                              final performance = d['performance'] as Map?;
                                              final empType = employment?['type'] as String? ?? d['employment_type'] as String? ?? '';
                                              final licType = license?['type'] as String? ?? d['license_type'] as String? ?? '';
                                              final licExpiry = license?['expiry_date'] as String? ?? d['license_expiry'] as String? ?? '';
                                              final score = (performance?['score'] ?? d['score'] ?? 0) as num;
                                              final totalTrips = (performance?['total_trips'] ?? d['total_trips'] ?? 0) as num;
                                              final onTimeRate = (performance?['on_time_rate'] ?? d['on_time_rate'] ?? 0.0) as num;
                                              final onTimePct = '${(onTimeRate * 100).round()}%';
                                              return DataRow(cells: [
                                                DataCell(Text(d['employee_id'] as String? ?? '', style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                                                DataCell(Text(d['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                                                DataCell(Text(d['phone'] as String? ?? '', style: const TextStyle(fontSize: 12))),
                                                DataCell(Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(licType, style: const TextStyle(fontSize: 13)),
                                                    Text('หมดอายุ $licExpiry', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                                  ],
                                                )),
                                                DataCell(_DriverTypeChip(type: empType)),
                                                DataCell(Text(d['assigned_vehicle_id'] as String? ?? '-', style: const TextStyle(fontSize: 12))),
                                                DataCell(_ScoreBadge(score: score.toInt())),
                                                DataCell(Text('$totalTrips')),
                                                DataCell(Text(onTimePct, style: const TextStyle(fontSize: 12))),
                                                DataCell(_DriverStatusChip(status: d['status'] as String? ?? '')),
                                                DataCell(Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () {}, tooltip: 'ดูรายละเอียด'),
                                                    IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {}, tooltip: 'แก้ไข'),
                                                  ],
                                                )),
                                              ]);
                                            }).toList(),
                                          ),
                                        ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                children: [
                                  if (!isMobile) ...[
                                    Text('แถวต่อหน้า: ', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                                    DropdownButton<int>(
                                      value: _rowsPerPage,
                                      underline: const SizedBox(),
                                      items: [10, 25, 50].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                                      onChanged: (v) => setState(() { _rowsPerPage = v!; _currentPage = 0; }),
                                    ),
                                  ],
                                  const Spacer(),
                                  Text('${_currentPage + 1}/$totalPages', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
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

  Widget _buildDriverCard(BuildContext context, Map<String, dynamic> d) {
    final cs = Theme.of(context).colorScheme;
    final employment = d['employment'] as Map?;
    final license = d['license'] as Map?;
    final performance = d['performance'] as Map?;
    final empType = employment?['type'] as String? ?? d['employment_type'] as String? ?? '';
    final licType = license?['type'] as String? ?? d['license_type'] as String? ?? '';
    final score = (performance?['score'] ?? d['score'] ?? 0) as num;
    final totalTrips = (performance?['total_trips'] ?? d['total_trips'] ?? 0) as num;
    final onTimeRate = (performance?['on_time_rate'] ?? d['on_time_rate'] ?? 0.0) as num;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.person, color: cs.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(d['name'] as String? ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      _ScoreBadge(score: score.toInt()),
                    ],
                  ),
                  Text('${d['employee_id'] ?? ''} · ${d['phone'] ?? ''}',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      _DriverStatusChip(status: d['status'] as String? ?? ''),
                      _DriverTypeChip(type: empType),
                      if (licType.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(licType, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$totalTrips เที่ยว · ตรงเวลา ${(onTimeRate * 100).round()}%',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () {}),
                IconButton(constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
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
