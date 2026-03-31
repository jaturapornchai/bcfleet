import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://bcfleet.satistang.com/api/v1/fleet';

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
  bool _loading = true;

  List<Map<String, dynamic>> _workOrders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_apiBase/maintenance/work-orders'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (mounted) {
          setState(() {
            _workOrders = (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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

  List<Map<String, dynamic>> get _filtered => _workOrders.where((w) {
    final woNo = (w['wo_no'] as String? ?? '').toLowerCase();
    final vehicleId = (w['vehicle_id'] as String? ?? '').toLowerCase();
    final desc = (w['description'] as String? ?? '').toLowerCase();
    final search = _search.toLowerCase();
    final matchSearch = _search.isEmpty || woNo.contains(search) || vehicleId.contains(search) || desc.contains(search);
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
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'รีเฟรช'),
              const SizedBox(width: 8),
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _workOrders.isEmpty
                      ? const Center(child: Text('ไม่มีข้อมูลใบสั่งซ่อม', style: TextStyle(color: Colors.grey)))
                      : Column(
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
                                  rows: pageRows.map((w) {
                                    final serviceProvider = w['service_provider'] as Map?;
                                    final providerName = serviceProvider?['name'] as String? ?? w['service_provider_name'] as String? ?? '-';
                                    final createdAt = w['created_at'] as String? ?? '';
                                    final dateStr = createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
                                    final totalCost = w['total_cost'] ?? 0;
                                    final status = w['status'] as String? ?? '';
                                    return DataRow(cells: [
                                      DataCell(Text(w['wo_no'] as String? ?? '', style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
                                      DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                                      DataCell(Text(w['vehicle_id'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                                      DataCell(_WOTypeChip(type: w['type'] as String? ?? '')),
                                      DataCell(_PriorityChip(priority: w['priority'] as String? ?? '')),
                                      DataCell(SizedBox(width: 180, child: Text(w['description'] as String? ?? '', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))),
                                      DataCell(Text(providerName, style: const TextStyle(fontSize: 12))),
                                      DataCell(Text('฿$totalCost')),
                                      DataCell(_WOStatusChip(status: status)),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () {}, tooltip: 'ดูรายละเอียด'),
                                          if (status == 'pending_approval')
                                            IconButton(icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.green), onPressed: () {}, tooltip: 'อนุมัติ'),
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
