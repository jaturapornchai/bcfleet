import 'package:flutter/material.dart';

class PartnerSettlementScreen extends StatefulWidget {
  const PartnerSettlementScreen({super.key});

  @override
  State<PartnerSettlementScreen> createState() => _PartnerSettlementScreenState();
}

class _PartnerSettlementScreenState extends State<PartnerSettlementScreen> {
  String _filterStatus = 'all';
  String _filterMonth = '03/2569';
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  final _settlements = [
    {'id': '1', 'partner': 'สมหมาย รถเยอะ', 'company': 'บจก.ขนส่งสมหมาย', 'plate': '2กร-5678', 'month': '03/2569', 'trips': '5', 'gross': '15,000', 'wht': '150', 'net': '14,850', 'status': 'pending', 'due_date': '10/04/2569'},
    {'id': '2', 'partner': 'ประสิทธิ์ มีรถ', 'company': '', 'plate': 'ลป-4567', 'month': '03/2569', 'trips': '3', 'gross': '7,500', 'wht': '75', 'net': '7,425', 'status': 'paid', 'due_date': '10/04/2569'},
    {'id': '3', 'partner': 'วีระพล ขนส่ง', 'company': 'หจก.วีระพลขนส่ง', 'plate': 'ชม-8901', 'month': '03/2569', 'trips': '8', 'gross': '12,000', 'wht': '120', 'net': '11,880', 'status': 'pending', 'due_date': '10/04/2569'},
    {'id': '4', 'partner': 'สุรชัย ใหญ่โต', 'company': 'บจก.สุรชัยโลจิสติกส์', 'plate': 'กน-2345', 'month': '03/2569', 'trips': '12', 'gross': '96,000', 'wht': '960', 'net': '95,040', 'status': 'paid', 'due_date': '10/04/2569'},
    {'id': '5', 'partner': 'สมศรี ขนส่งดี', 'company': 'หจก.สมศรีทรานสปอร์ต', 'plate': 'ชร-1234', 'month': '03/2569', 'trips': '6', 'gross': '24,000', 'wht': '240', 'net': '23,760', 'status': 'overdue', 'due_date': '05/04/2569'},
    {'id': '6', 'partner': 'สมหมาย รถเยอะ', 'company': 'บจก.ขนส่งสมหมาย', 'plate': '2กร-5678', 'month': '02/2569', 'trips': '4', 'gross': '12,000', 'wht': '120', 'net': '11,880', 'status': 'paid', 'due_date': '10/03/2569'},
    {'id': '7', 'partner': 'วีระพล ขนส่ง', 'company': 'หจก.วีระพลขนส่ง', 'plate': 'ชม-8901', 'month': '02/2569', 'trips': '6', 'gross': '9,000', 'wht': '90', 'net': '8,910', 'status': 'paid', 'due_date': '10/03/2569'},
  ];

  List<Map<String, String>> get _filtered => _settlements.where((s) {
    final matchStatus = _filterStatus == 'all' || s['status'] == _filterStatus;
    final matchMonth = _filterMonth == 'all' || s['month'] == _filterMonth;
    return matchStatus && matchMonth;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final pageStart = _currentPage * _rowsPerPage;
    final pageEnd = (pageStart + _rowsPerPage).clamp(0, filtered.length);
    final pageRows = filtered.sublist(pageStart, pageEnd);
    final totalPages = (filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

    final totalPending = filtered.where((s) => s['status'] == 'pending' || s['status'] == 'overdue').fold(0, (sum, s) => sum + _parseAmount(s['net']!));
    final totalPaid = filtered.where((s) => s['status'] == 'paid').fold(0, (sum, s) => sum + _parseAmount(s['net']!));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('จ่ายเงินรถร่วม', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Export ภ.ง.ด.3'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('จ่ายที่เลือก'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Summary
          Row(
            children: [
              _buildSummaryCard(cs, 'รอจ่าย', '฿${_formatAmount(totalPending)}', Colors.orange, Icons.schedule),
              const SizedBox(width: 12),
              _buildSummaryCard(cs, 'จ่ายแล้วเดือนนี้', '฿${_formatAmount(totalPaid)}', Colors.green, Icons.check_circle_outline),
              const SizedBox(width: 12),
              _buildSummaryCard(cs, 'หัก ณ ที่จ่ายรวม',
                  '฿${_formatAmount(filtered.fold(0, (sum, s) => sum + _parseAmount(s['wht']!)))}',
                  Colors.blue, Icons.account_balance_outlined),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              DropdownButton<String>(
                value: _filterMonth,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('ทุกเดือน')),
                  DropdownMenuItem(value: '03/2569', child: Text('มีนาคม 2569')),
                  DropdownMenuItem(value: '02/2569', child: Text('กุมภาพันธ์ 2569')),
                  DropdownMenuItem(value: '01/2569', child: Text('มกราคม 2569')),
                ],
                onChanged: (v) => setState(() { _filterMonth = v!; _currentPage = 0; }),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filterStatus,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('ทุกสถานะ')),
                  DropdownMenuItem(value: 'pending', child: Text('รอจ่าย')),
                  DropdownMenuItem(value: 'paid', child: Text('จ่ายแล้ว')),
                  DropdownMenuItem(value: 'overdue', child: Text('เกินกำหนด')),
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
                          DataColumn(label: Text('รถร่วม')),
                          DataColumn(label: Text('ทะเบียน')),
                          DataColumn(label: Text('เดือน')),
                          DataColumn(label: Text('เที่ยว'), numeric: true),
                          DataColumn(label: Text('ยอดรวม'), numeric: true),
                          DataColumn(label: Text('หัก ณ ที่จ่าย (1%)'), numeric: true),
                          DataColumn(label: Text('ยอดสุทธิ'), numeric: true),
                          DataColumn(label: Text('กำหนดจ่าย')),
                          DataColumn(label: Text('สถานะ')),
                          DataColumn(label: Text('จัดการ')),
                        ],
                        rows: pageRows.map((s) => DataRow(cells: [
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(s['partner']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              if (s['company']!.isNotEmpty)
                                Text(s['company']!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            ],
                          )),
                          DataCell(Text(s['plate']!, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(s['month']!)),
                          DataCell(Text(s['trips']!)),
                          DataCell(Text('฿${s['gross']!}')),
                          DataCell(Text('฿${s['wht']!}', style: TextStyle(color: Colors.orange[700]))),
                          DataCell(Text('฿${s['net']!}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(s['due_date']!, style: const TextStyle(fontSize: 12))),
                          DataCell(_SettlementStatusChip(status: s['status']!)),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (s['status'] != 'paid')
                                IconButton(
                                  icon: const Icon(Icons.payment, size: 18, color: Colors.green),
                                  onPressed: () => _showPayDialog(s),
                                  tooltip: 'จ่ายเงิน',
                                ),
                              IconButton(
                                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                                onPressed: () {},
                                tooltip: 'ดูรายละเอียด',
                              ),
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

  int _parseAmount(String s) => int.tryParse(s.replaceAll(',', '')) ?? 0;

  String _formatAmount(int amount) {
    if (amount >= 1000) {
      final str = amount.toString();
      final result = StringBuffer();
      final offset = str.length % 3;
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (i - offset) % 3 == 0) result.write(',');
        result.write(str[i]);
      }
      return result.toString();
    }
    return amount.toString();
  }

  Widget _buildSummaryCard(ColorScheme cs, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  void _showPayDialog(Map<String, String> s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการจ่ายเงิน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รถร่วม: ${s['partner']!}'),
            Text('ทะเบียน: ${s['plate']!}'),
            const SizedBox(height: 8),
            Text('ยอดรวม: ฿${s['gross']!}'),
            Text('หัก ณ ที่จ่าย: ฿${s['wht']!}'),
            const Divider(),
            Text('ยอดสุทธิที่ต้องจ่าย: ฿${s['net']!}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('จ่ายเงินให้ ${s['partner']!} เรียบร้อย ฿${s['net']!}')),
              );
            },
            child: const Text('ยืนยันจ่ายเงิน'),
          ),
        ],
      ),
    );
  }
}

class _SettlementStatusChip extends StatelessWidget {
  final String status;
  const _SettlementStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('รอจ่าย', Colors.orange),
      'paid' => ('จ่ายแล้ว', Colors.green),
      'overdue' => ('เกินกำหนด', Colors.red),
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
