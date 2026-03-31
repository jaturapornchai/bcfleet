import 'package:flutter/material.dart';

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

  final _partners = [
    {'id': '1', 'owner': 'สมหมาย รถเยอะ', 'company': 'บจก.ขนส่งสมหมาย', 'phone': '081-456-7890', 'plate': '2กร-5678', 'type': '10ล้อ', 'driver': 'วิชัย ขับดี', 'zones': 'เชียงใหม่/ลำพูน/ลำปาง', 'rate': '3,000', 'rating': '4.5', 'trips': '35', 'status': 'active', 'tax_id': '0105564123456'},
    {'id': '2', 'owner': 'ประสิทธิ์ มีรถ', 'company': '', 'phone': '089-678-9012', 'plate': 'ลป-4567', 'type': '6ล้อ', 'driver': 'ประสิทธิ์ มีรถ', 'zones': 'ลำปาง/เชียงใหม่', 'rate': '2,500', 'rating': '4.2', 'trips': '18', 'status': 'active', 'tax_id': '1-1234-56789-01-2'},
    {'id': '3', 'owner': 'วีระพล ขนส่ง', 'company': 'หจก.วีระพลขนส่ง', 'phone': '085-123-4567', 'plate': 'ชม-8901', 'type': '4ล้อ', 'driver': 'อนุชา ขนดี', 'zones': 'เชียงใหม่', 'rate': '1,500', 'rating': '4.8', 'trips': '52', 'status': 'active', 'tax_id': '0135565012345'},
    {'id': '4', 'owner': 'สุรชัย ใหญ่โต', 'company': 'บจก.สุรชัยโลจิสติกส์', 'phone': '091-234-5678', 'plate': 'กน-2345', 'type': 'หัวลาก', 'driver': 'สมบัติ ลากดี', 'zones': 'ทุกจังหวัดภาคเหนือ', 'rate': '8,000', 'rating': '4.7', 'trips': '89', 'status': 'active', 'tax_id': '0505563456789'},
    {'id': '5', 'owner': 'มานพ รถบรรทุก', 'company': '', 'phone': '083-456-7890', 'plate': 'พย-6789', 'type': '6ล้อ', 'driver': 'มานพ รถบรรทุก', 'zones': 'พะเยา/เชียงราย', 'rate': '2,800', 'rating': '3.9', 'trips': '12', 'status': 'suspended', 'tax_id': '1-5678-90123-45-6'},
    {'id': '6', 'owner': 'สมศรี ขนส่งดี', 'company': 'หจก.สมศรีทรานสปอร์ต', 'phone': '087-890-1234', 'plate': 'ชร-1234', 'type': '10ล้อ', 'driver': 'ชัยวัฒน์ ขับดี', 'zones': 'เชียงราย/เชียงใหม่', 'rate': '4,000', 'rating': '4.6', 'trips': '41', 'status': 'active', 'tax_id': '0125563012345'},
  ];

  List<Map<String, String>> get _filtered => _partners.where((p) {
    final matchSearch = _search.isEmpty ||
        p['owner']!.contains(_search) ||
        p['company']!.contains(_search) ||
        p['plate']!.contains(_search) ||
        p['driver']!.contains(_search);
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
              child: Column(
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
                        rows: pageRows.map((p) => DataRow(cells: [
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p['owner']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              if (p['company']!.isNotEmpty)
                                Text(p['company']!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                              Text(p['phone']!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            ],
                          )),
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p['plate']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(p['type']!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            ],
                          )),
                          DataCell(Text(p['driver']!, style: const TextStyle(fontSize: 12))),
                          DataCell(SizedBox(
                            width: 160,
                            child: Text(p['zones']!, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                          )),
                          DataCell(Text('฿${p['rate']!}/เที่ยว')),
                          DataCell(Text(p['trips']!)),
                          DataCell(_RatingWidget(rating: double.parse(p['rating']!))),
                          DataCell(_PartnerStatusChip(status: p['status']!)),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () {}, tooltip: 'ดูรายละเอียด'),
                              IconButton(icon: const Icon(Icons.local_shipping_outlined, size: 18, color: Colors.blue), onPressed: () {}, tooltip: 'จองรถร่วม'),
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
