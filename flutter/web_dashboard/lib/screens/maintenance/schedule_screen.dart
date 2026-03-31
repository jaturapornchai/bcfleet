import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _filterVehicle = 'all';
  String _filterStatus = 'all';

  final _schedules = [
    {'id': '1', 'vehicle': 'กท-1234', 'type': 'ISUZU FRR 210', 'item': 'เปลี่ยนน้ำมันเครื่อง', 'interval': '10,000 กม.', 'last_km': '80,000', 'last_date': '01/06/2568', 'due_km': '90,000', 'current_km': '85,000', 'due_date': '01/12/2568', 'status': 'upcoming', 'days': '60'},
    {'id': '2', 'vehicle': 'กท-1234', 'type': 'ISUZU FRR 210', 'item': 'เปลี่ยนผ้าเบรค', 'interval': '40,000 กม.', 'last_km': '60,000', 'last_date': '01/01/2567', 'due_km': '100,000', 'current_km': '85,000', 'due_date': '-', 'status': 'ok', 'days': '-'},
    {'id': '3', 'vehicle': '2กร-5678', 'type': 'HINO 500', 'item': 'เปลี่ยนยาง 4 เส้น', 'interval': '50,000 กม.', 'last_km': '50,000', 'last_date': '01/06/2566', 'due_km': '100,000', 'current_km': '98,000', 'due_date': '15/04/2569', 'status': 'due_soon', 'days': '15'},
    {'id': '4', 'vehicle': 'ชม-3456', 'type': 'ISUZU NQR', 'item': 'เปลี่ยนกรองอากาศ', 'interval': '20,000 กม.', 'last_km': '80,000', 'last_date': '01/06/2568', 'due_km': '100,000', 'current_km': '102,000', 'due_date': '01/03/2569', 'status': 'overdue', 'days': '-30'},
    {'id': '5', 'vehicle': 'กน-7890', 'type': 'HINO 700', 'item': 'ตรวจเช็คสายพาน', 'interval': '80,000 กม.', 'last_km': '10,000', 'last_date': '01/01/2565', 'due_km': '90,000', 'current_km': '88,000', 'due_date': '30/04/2569', 'status': 'due_soon', 'days': '30'},
    {'id': '6', 'vehicle': 'ลป-1122', 'type': 'ISUZU FTR', 'item': 'เปลี่ยนน้ำมันเกียร์', 'interval': '40,000 กม.', 'last_km': '60,000', 'last_date': '01/01/2568', 'due_km': '100,000', 'current_km': '75,000', 'due_date': '-', 'status': 'ok', 'days': '-'},
    {'id': '7', 'vehicle': 'พย-3344', 'type': 'ISUZU FVR', 'item': 'ล้างหม้อน้ำ', 'interval': '60,000 กม.', 'last_km': '40,000', 'last_date': '01/06/2567', 'due_km': '100,000', 'current_km': '95,000', 'due_date': '20/04/2569', 'status': 'due_soon', 'days': '20'},
  ];

  List<Map<String, String>> get _filtered => _schedules.where((s) {
    final matchVehicle = _filterVehicle == 'all' || s['vehicle'] == _filterVehicle;
    final matchStatus = _filterStatus == 'all' || s['status'] == _filterStatus;
    return matchVehicle && matchStatus;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final overdue = _schedules.where((s) => s['status'] == 'overdue').length;
    final dueSoon = _schedules.where((s) => s['status'] == 'due_soon').length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ตารางซ่อมบำรุง', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('สร้างใบสั่งซ่อม'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Summary cards
          Row(
            children: [
              _buildSummaryCard(cs, 'เกินกำหนด', overdue, Colors.red, Icons.warning_rounded),
              const SizedBox(width: 12),
              _buildSummaryCard(cs, 'ใกล้ถึงกำหนด', dueSoon, Colors.orange, Icons.schedule),
              const SizedBox(width: 12),
              _buildSummaryCard(cs, 'ปกติ', _schedules.where((s) => s['status'] == 'ok').length, Colors.green, Icons.check_circle_outline),
              const SizedBox(width: 12),
              _buildSummaryCard(cs, 'รายการทั้งหมด', _schedules.length, cs.primary, Icons.build_outlined),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              DropdownButton<String>(
                value: _filterVehicle,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('ทุกคัน')),
                  ..._schedules.map((s) => s['vehicle']!).toSet().map((p) =>
                      DropdownMenuItem(value: p, child: Text(p))),
                ],
                onChanged: (v) => setState(() => _filterVehicle = v!),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filterStatus,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('ทุกสถานะ')),
                  DropdownMenuItem(value: 'overdue', child: Text('เกินกำหนด')),
                  DropdownMenuItem(value: 'due_soon', child: Text('ใกล้ถึงกำหนด')),
                  DropdownMenuItem(value: 'ok', child: Text('ปกติ')),
                ],
                onChanged: (v) => setState(() => _filterStatus = v!),
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
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(cs.surfaceContainerLow),
                  columns: const [
                    DataColumn(label: Text('รถ')),
                    DataColumn(label: Text('รายการ')),
                    DataColumn(label: Text('ระยะ')),
                    DataColumn(label: Text('ทำล่าสุด (กม.)')),
                    DataColumn(label: Text('ทำล่าสุด (วันที่)')),
                    DataColumn(label: Text('กม.ปัจจุบัน'), numeric: true),
                    DataColumn(label: Text('กำหนดทำ (กม.)'), numeric: true),
                    DataColumn(label: Text('กำหนดทำ (วันที่)')),
                    DataColumn(label: Text('สถานะ')),
                    DataColumn(label: Text('จัดการ')),
                  ],
                  rows: filtered.map((s) {
                    final isOverdue = s['status'] == 'overdue';
                    return DataRow(
                      color: isOverdue ? WidgetStateProperty.all(Colors.red.withValues(alpha: 0.05)) : null,
                      cells: [
                        DataCell(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(s['vehicle']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(s['type']!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                          ],
                        )),
                        DataCell(Text(s['item']!)),
                        DataCell(Text(s['interval']!, style: const TextStyle(fontSize: 12))),
                        DataCell(Text(s['last_km']! + ' กม.', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(s['last_date']!, style: const TextStyle(fontSize: 12))),
                        DataCell(Text(s['current_km']! + ' กม.')),
                        DataCell(Text(s['due_km']! + ' กม.')),
                        DataCell(Text(s['due_date']!, style: const TextStyle(fontSize: 12))),
                        DataCell(_ScheduleStatusChip(status: s['status']!, days: s['days']!)),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.build, size: 18, color: Colors.blue),
                              onPressed: () {},
                              tooltip: 'สร้างใบสั่งซ่อม',
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                              onPressed: () {},
                              tooltip: 'บันทึกว่าทำแล้ว',
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme cs, String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleStatusChip extends StatelessWidget {
  final String status;
  final String days;
  const _ScheduleStatusChip({required this.status, required this.days});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'overdue' => ('เกินกำหนด ${days.replaceAll('-', '')} วัน', Colors.red),
      'due_soon' => ('อีก $days วัน', Colors.orange),
      'ok' => ('ปกติ', Colors.green),
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
