import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://smlfleet.satistang.com/api/v1/fleet';

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
  bool _loading = true;

  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_apiBase/trips'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (mounted) {
          setState(() {
            _trips = (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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

  List<Map<String, dynamic>> get _filtered => _trips.where((t) {
    final tripNo = (t['trip_no'] as String? ?? '').toLowerCase();
    final originMap = t['origin'] as Map?;
    final origin = (originMap?['name'] as String? ?? t['origin_name'] as String? ?? '').toLowerCase();
    final dests = t['destinations'] as List?;
    final firstDest = dests != null && dests.isNotEmpty ? dests.first as Map? : null;
    final destName = (firstDest?['name'] as String? ?? '').toLowerCase();
    final driver = (t['driver_name'] as String? ?? '').toLowerCase();
    final search = _search.toLowerCase();
    final matchSearch = _search.isEmpty || tripNo.contains(search) || origin.contains(search) || destName.contains(search) || driver.contains(search);
    final matchStatus = _filterStatus == 'all' || t['status'] == _filterStatus;
    return matchSearch && matchStatus;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
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
                child: Text('รายการเที่ยววิ่ง',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              if (_loading)
                const Padding(padding: EdgeInsets.only(right: 8),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'รีเฟรช'),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: isMobile ? const SizedBox.shrink() : const Text('สร้างเที่ยวใหม่'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isMobile) ...[
            TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาเที่ยว / ต้นทาง...',
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
                      DropdownMenuItem(value: 'pending', child: Text('รอดำเนินการ')),
                      DropdownMenuItem(value: 'started', child: Text('กำลังวิ่ง')),
                      DropdownMenuItem(value: 'completed', child: Text('เสร็จสิ้น')),
                      DropdownMenuItem(value: 'cancelled', child: Text('ยกเลิก')),
                    ],
                    onChanged: (v) => setState(() { _filterStatus = v!; _currentPage = 0; }),
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _trips.isEmpty
                      ? const Center(child: Text('ไม่มีข้อมูลเที่ยววิ่ง', style: TextStyle(color: Colors.grey)))
                      : Column(
                          children: [
                            Expanded(
                              child: isMobile
                                  ? ListView.separated(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: pageRows.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (_, i) => _buildTripCard(context, pageRows[i]),
                                    )
                                  : SingleChildScrollView(
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
                                        rows: pageRows.map((t) {
                                          final originMap2 = t['origin'] as Map?;
                                          final origin = originMap2?['name'] as String? ?? t['origin_name'] as String? ?? '';
                                          final dests = t['destinations'] as List?;
                                          final firstDest2 = dests != null && dests.isNotEmpty ? dests.first as Map? : null;
                                          final destName = firstDest2?['name'] as String? ?? '';
                                          final driverName = t['driver_name'] as String? ?? t['driver_id'] as String? ?? '-';
                                          final plate = t['vehicle_plate'] as String? ?? t['vehicle_id'] as String? ?? '-';
                                          final status = t['status'] as String? ?? '';
                                          final isPartner = t['is_partner'] == true;
                                          final schedule = t['schedule'] as Map?;
                                          final plannedStart = schedule?['planned_start'] as String? ?? t['planned_start'] as String? ?? '';
                                          final dateStr = plannedStart.isNotEmpty ? plannedStart.substring(0, 10) : '';
                                          final costs = t['costs'] as Map?;
                                          final revenue = costs?['revenue'] ?? t['revenue'] ?? '';
                                          return DataRow(cells: [
                                            DataCell(Text(t['trip_no'] as String? ?? '', style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
                                            DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                                            DataCell(Text(origin)),
                                            DataCell(Text(destName)),
                                            DataCell(Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(driverName, style: const TextStyle(fontSize: 12)),
                                                Text(plate, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                              ],
                                            )),
                                            DataCell(isPartner
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
                                            DataCell(_TripStatusChip(status: status)),
                                            DataCell(Text(revenue != '' ? '฿$revenue' : '-')),
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
                                  Text('${_currentPage + 1}/$totalPages', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
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

  Widget _buildTripCard(BuildContext context, Map<String, dynamic> t) {
    final cs = Theme.of(context).colorScheme;
    final originMap = t['origin'] as Map?;
    final origin = originMap?['name'] as String? ?? t['origin_name'] as String? ?? '-';
    final dests = t['destinations'] as List?;
    final firstDest = dests != null && dests.isNotEmpty ? dests.first as Map? : null;
    final destName = firstDest?['name'] as String? ?? '-';
    final driverName = t['driver_name'] as String? ?? t['driver_id'] as String? ?? '-';
    final plate = t['vehicle_plate'] as String? ?? t['vehicle_id'] as String? ?? '-';
    final status = t['status'] as String? ?? '';
    final isPartner = t['is_partner'] == true;
    final schedule = t['schedule'] as Map?;
    final plannedStart = schedule?['planned_start'] as String? ?? t['planned_start'] as String? ?? '';
    final dateStr = plannedStart.length >= 10 ? plannedStart.substring(0, 10) : plannedStart;
    final costs = t['costs'] as Map?;
    final revenue = costs?['revenue'] ?? t['revenue'] ?? '';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t['trip_no'] as String? ?? '',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                ),
                if (dateStr.isNotEmpty)
                  Text(dateStr, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                const SizedBox(width: 8),
                _TripStatusChip(status: status),
              ],
            ),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.circle, size: 8, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(child: Text(origin, style: const TextStyle(fontSize: 12))),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.location_on, size: 8, color: Colors.red),
              const SizedBox(width: 6),
              Expanded(child: Text(destName, style: const TextStyle(fontSize: 12))),
            ]),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(driverName, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(width: 8),
                Icon(Icons.local_shipping_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(plate, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPartner ? Colors.purple : Colors.blue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(isPartner ? 'รถร่วม' : 'รถตัวเอง',
                      style: TextStyle(fontSize: 10, color: isPartner ? Colors.purple : Colors.blue)),
                ),
                if (revenue != '') ...[
                  const SizedBox(width: 8),
                  Text('฿$revenue', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                ],
              ],
            ),
          ],
        ),
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
      'in_progress' || 'started' || 'delivering' => ('กำลังวิ่ง', Colors.blue),
      'pending' || 'accepted' => ('รอดำเนินการ', Colors.orange),
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
