import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://smlfleet.satistang.com/api/v1/fleet';

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
  bool _loading = true;

  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_apiBase/vehicles'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (mounted) {
          setState(() {
            _vehicles = (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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

  List<Map<String, dynamic>> get _filtered => _vehicles.where((v) {
    final plate = (v['plate'] as String? ?? '').toLowerCase();
    final brand = (v['brand'] as String? ?? '').toLowerCase();
    final driver = (v['current_driver_id'] as String? ?? (v['driver_name'] as String? ?? '')).toLowerCase();
    final search = _search.toLowerCase();
    final matchSearch = _search.isEmpty || plate.contains(search) || brand.contains(search) || driver.contains(search);
    final matchStatus = _filterStatus == 'all' || v['status'] == _filterStatus;
    final matchType = _filterType == 'all' || v['type'] == _filterType;
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
          // Header
          Row(
            children: [
              Expanded(
                child: Text('ทะเบียนรถทั้งหมด',
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
                label: isMobile ? const SizedBox.shrink() : const Text('เพิ่มรถ'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filters — wrap on mobile
          if (isMobile) ...[
            TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาทะเบียน / ยี่ห้อ...',
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
                      DropdownMenuItem(value: 'active', child: Text('ใช้งาน')),
                      DropdownMenuItem(value: 'maintenance', child: Text('ซ่อมบำรุง')),
                      DropdownMenuItem(value: 'inactive', child: Text('ไม่ใช้งาน')),
                    ],
                    onChanged: (v) => setState(() { _filterStatus = v!; _currentPage = 0; }),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _filterType,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('ทุกประเภท')),
                      DropdownMenuItem(value: '4ล้อ', child: Text('4 ล้อ')),
                      DropdownMenuItem(value: '6ล้อ', child: Text('6 ล้อ')),
                      DropdownMenuItem(value: '10ล้อ', child: Text('10 ล้อ')),
                      DropdownMenuItem(value: 'หัวลาก', child: Text('หัวลาก')),
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

          // Content
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _vehicles.isEmpty
                      ? const Center(child: Text('ไม่มีข้อมูลรถ', style: TextStyle(color: Colors.grey)))
                      : Column(
                          children: [
                            Expanded(
                              child: isMobile
                                  // Mobile: card list
                                  ? ListView.separated(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: pageRows.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (_, i) => _buildVehicleCard(context, pageRows[i]),
                                    )
                                  : isTablet
                                      // Tablet: 2-col grid
                                      ? GridView.builder(
                                          padding: const EdgeInsets.all(12),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: 2.6,
                                          ),
                                          itemCount: pageRows.length,
                                          itemBuilder: (_, i) => _buildVehicleCard(context, pageRows[i]),
                                        )
                                      // Desktop: DataTable
                                      : SingleChildScrollView(
                                          child: DataTable(
                                            sortColumnIndex: _sortColumnIndex,
                                            sortAscending: _sortAscending,
                                            headingRowColor: WidgetStateProperty.all(cs.surfaceContainerLow),
                                            columns: [
                                              DataColumn(label: const Text('ทะเบียน'), onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })),
                                              DataColumn(label: const Text('ยี่ห้อ / รุ่น'), onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })),
                                              const DataColumn(label: Text('ประเภท')),
                                              const DataColumn(label: Text('ปี')),
                                              const DataColumn(label: Text('คนขับประจำ')),
                                              const DataColumn(label: Text('เลขไมล์'), numeric: true),
                                              const DataColumn(label: Text('ประเภทเจ้าของ')),
                                              const DataColumn(label: Text('สุขภาพ')),
                                              const DataColumn(label: Text('สถานะ')),
                                              const DataColumn(label: Text('จัดการ')),
                                            ],
                                            rows: pageRows.map((v) => DataRow(
                                              cells: [
                                                DataCell(Text(v['plate'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                                                DataCell(Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(v['brand'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                                                    Text(v['model'] as String? ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                                  ],
                                                )),
                                                DataCell(Text(v['type'] as String? ?? '')),
                                                DataCell(Text('${v['year'] ?? ''}')),
                                                DataCell(Text(v['driver_name'] as String? ?? v['current_driver_id'] as String? ?? '-')),
                                                DataCell(Text('${v['mileage_km'] ?? '-'} กม.')),
                                                DataCell(_OwnershipChip(ownership: v['ownership'] as String? ?? '')),
                                                DataCell(_HealthDot(health: v['health_status'] as String? ?? 'green')),
                                                DataCell(_StatusChip(status: v['status'] as String? ?? '')),
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

  Widget _buildVehicleCard(BuildContext context, Map<String, dynamic> v) {
    final cs = Theme.of(context).colorScheme;
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.local_shipping, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(v['plate'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      _HealthDot(health: v['health_status'] as String? ?? 'green'),
                    ],
                  ),
                  Text('${v['brand'] ?? ''} ${v['model'] ?? ''} · ${v['type'] ?? ''}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      _StatusChip(status: v['status'] as String? ?? ''),
                      _OwnershipChip(ownership: v['ownership'] as String? ?? ''),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${v['mileage_km'] ?? '-'} กม.', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () {}),
                    IconButton(constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {}),
                  ],
                ),
              ],
            ),
          ],
        ),
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
