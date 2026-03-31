import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://bcfleet.satistang.com/api/v1/fleet';

class PartnerListScreen extends StatefulWidget {
  const PartnerListScreen({super.key});

  @override
  State<PartnerListScreen> createState() => _PartnerListScreenState();
}

class _PartnerListScreenState extends State<PartnerListScreen> {
  String _search = '';
  String _filterStatus = 'all';
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  bool _loading = true;

  List<Map<String, dynamic>> _partners = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_apiBase/partners'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (mounted) {
          setState(() {
            _partners = (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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

  List<Map<String, dynamic>> get _filtered => _partners.where((p) {
    final owner = p['owner'] as Map?;
    final vehicle = p['vehicle'] as Map?;
    final driver = p['driver'] as Map?;
    final ownerName = (owner?['name'] as String? ?? '').toLowerCase();
    final ownerCompany = (owner?['company'] as String? ?? '').toLowerCase();
    final plate = (vehicle?['plate'] as String? ?? '').toLowerCase();
    final driverName = (driver?['name'] as String? ?? '').toLowerCase();
    final search = _search.toLowerCase();
    final matchSearch = _search.isEmpty || ownerName.contains(search) || ownerCompany.contains(search) || plate.contains(search) || driverName.contains(search);
    final matchStatus = _filterStatus == 'all' || p['status'] == _filterStatus;
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
              Text('รถร่วม', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
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
                label: const Text('ลงทะเบียนรถร่วม'),
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
                    hintText: 'ค้นหาชื่อ / บริษัท / ทะเบียน...',
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
                  DropdownMenuItem(value: 'suspended', child: Text('ระงับ')),
                  DropdownMenuItem(value: 'inactive', child: Text('ไม่ใช้งาน')),
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
                  : _partners.isEmpty
                      ? const Center(child: Text('ไม่มีข้อมูลรถร่วม', style: TextStyle(color: Colors.grey)))
                      : Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(cs.surfaceContainerLow),
                                  columns: const [
                                    DataColumn(label: Text('เจ้าของ / บริษัท')),
                                    DataColumn(label: Text('ทะเบียน / ประเภท')),
                                    DataColumn(label: Text('คนขับ')),
                                    DataColumn(label: Text('โซนให้บริการ')),
                                    DataColumn(label: Text('ราคาเริ่มต้น'), numeric: true),
                                    DataColumn(label: Text('เที่ยวทั้งหมด'), numeric: true),
                                    DataColumn(label: Text('Rating')),
                                    DataColumn(label: Text('สถานะ')),
                                    DataColumn(label: Text('จัดการ')),
                                  ],
                                  rows: pageRows.map((p) {
                                    final owner = p['owner'] as Map?;
                                    final vehicle = p['vehicle'] as Map?;
                                    final driver = p['driver'] as Map?;
                                    final pricing = p['pricing'] as Map?;
                                    final ownerName = owner?['name'] as String? ?? '';
                                    final ownerCompany = owner?['company'] as String? ?? '';
                                    final ownerPhone = owner?['phone'] as String? ?? '';
                                    final plate = vehicle?['plate'] as String? ?? '';
                                    final vehicleType = vehicle?['type'] as String? ?? '';
                                    final driverName = driver?['name'] as String? ?? '';
                                    final baseRate = pricing?['base_rate'] ?? p['base_rate'] ?? 0;
                                    final zones = p['coverage_zones'] as List?;
                                    final zonesStr = zones?.join('/') ?? '';
                                    final rating = (p['rating'] as num?)?.toDouble() ?? 0.0;
                                    final totalTrips = p['total_trips'] ?? 0;
                                    return DataRow(cells: [
                                      DataCell(Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(ownerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          if (ownerCompany.isNotEmpty)
                                            Text(ownerCompany, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                          Text(ownerPhone, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                        ],
                                      )),
                                      DataCell(Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(plate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text(vehicleType, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                        ],
                                      )),
                                      DataCell(Text(driverName, style: const TextStyle(fontSize: 12))),
                                      DataCell(SizedBox(
                                        width: 160,
                                        child: Text(zonesStr, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                      )),
                                      DataCell(Text('฿$baseRate/เที่ยว')),
                                      DataCell(Text('$totalTrips')),
                                      DataCell(_RatingWidget(rating: rating)),
                                      DataCell(_PartnerStatusChip(status: p['status'] as String? ?? '')),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () {}, tooltip: 'ดูรายละเอียด'),
                                          IconButton(icon: const Icon(Icons.local_shipping_outlined, size: 18, color: Colors.blue), onPressed: () {}, tooltip: 'จองรถร่วม'),
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

class _RatingWidget extends StatelessWidget {
  final double rating;
  const _RatingWidget({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: 14, color: Colors.amber[600]),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PartnerStatusChip extends StatelessWidget {
  final String status;
  const _PartnerStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('ใช้งาน', Colors.green),
      'suspended' => ('ระงับ', Colors.red),
      'inactive' => ('ไม่ใช้งาน', Colors.grey),
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
