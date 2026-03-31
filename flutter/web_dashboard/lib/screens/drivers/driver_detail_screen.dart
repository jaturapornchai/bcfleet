import 'package:flutter/material.dart';

class DriverDetailScreen extends StatefulWidget {
  final String? driverId;
  const DriverDetailScreen({super.key, this.driverId});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {}),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.person, size: 28, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('สมชาย ใจดี', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Text('EMP-001 — คนขับประจำ | ทะเบียน กท-1234', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const Spacer(),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 16), label: const Text('แก้ไข')),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.assignment, size: 16), label: const Text('มอบหมายงาน')),
            ],
          ),
          const SizedBox(height: 16),

          // KPI Row
          Row(
            children: [
              _buildKpiCard(context, 'คะแนนรวม', '92 / 100', Colors.green, Icons.star),
              const SizedBox(width: 12),
              _buildKpiCard(context, 'เที่ยวรวม', '450 เที่ยว', Colors.blue, Icons.route),
              const SizedBox(width: 12),
              _buildKpiCard(context, 'ตรงเวลา', '95%', Colors.teal, Icons.access_time),
              const SizedBox(width: 12),
              _buildKpiCard(context, 'ใบขับขี่', 'หมดอายุ 01/01/2026', Colors.orange, Icons.badge),
            ],
          ),
          const SizedBox(height: 16),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'ข้อมูลส่วนตัว'),
              Tab(text: 'ประวัติการทำงาน'),
              Tab(text: 'ผลงาน & KPI'),
              Tab(text: 'ตารางเวร'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(context),
                _buildTripHistoryTab(context),
                _buildPerformanceTab(context),
                _buildScheduleTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: color.withValues(alpha: 0.4))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildInfoSection('ข้อมูลส่วนตัว', [
              ('รหัสพนักงาน', 'EMP-001'),
              ('ชื่อ-นามสกุล', 'สมชาย ใจดี'),
              ('ชื่อเล่น', 'ชาย'),
              ('เบอร์โทร', '081-234-5678'),
              ('บัตรประชาชน', '1-1234-12345-12-1'),
              ('วันเกิด', '15/05/2528'),
              ('ที่อยู่', '123 ม.4 ต.สารภี อ.สารภี จ.เชียงใหม่'),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInfoSection('ใบขับขี่ & เอกสาร', [
              ('เลขใบขับขี่', '12345678'),
              ('ประเภท', 'ท.2'),
              ('วันออก', '01/01/2563'),
              ('วันหมดอายุ', '01/01/2569'),
              ('บัตร DLT', 'DLT-001'),
              ('บัตร DLT หมดอายุ', '01/06/2568'),
              ('ตรวจสุขภาพล่าสุด', '01/06/2567 — ปกติ'),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInfoSection('ข้อมูลการจ้างงาน', [
              ('ประเภทการจ้าง', 'พนักงานประจำ'),
              ('วันเริ่มงาน', '01/01/2563'),
              ('เงินเดือน', '฿15,000'),
              ('เบี้ยเลี้ยงต่อวัน', '฿300'),
              ('โบนัสต่อเที่ยว', '฿200'),
              ('รถที่รับผิดชอบ', 'กท-1234'),
              ('พื้นที่', 'เชียงใหม่, ลำพูน, ลำปาง'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<(String, String)> items) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(height: 20),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 140, child: Text(item.$1, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                  Expanded(child: Text(item.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTripHistoryTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trips = [
      {'date': '30/03/2569', 'trip_no': 'TRIP-2026-001230', 'origin': 'คลังสินค้า ABC', 'dest': 'ลูกค้า STU เชียงใหม่', 'km': '45', 'revenue': '1,800', 'status': 'completed'},
      {'date': '28/03/2569', 'trip_no': 'TRIP-2026-001215', 'origin': 'โรงงาน XYZ', 'dest': 'ห้าง ABC ลำพูน', 'km': '28', 'revenue': '2,500', 'status': 'completed'},
      {'date': '25/03/2569', 'trip_no': 'TRIP-2026-001198', 'origin': 'ท่าเรือ DEF', 'dest': 'ศูนย์กระจายสินค้า', 'km': '62', 'revenue': '3,800', 'status': 'completed'},
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: cs.outlineVariant)),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(cs.surfaceContainerLow),
          columns: const [
            DataColumn(label: Text('วันที่')),
            DataColumn(label: Text('เลขที่เที่ยว')),
            DataColumn(label: Text('ต้นทาง')),
            DataColumn(label: Text('ปลายทาง')),
            DataColumn(label: Text('ระยะทาง'), numeric: true),
            DataColumn(label: Text('รายได้'), numeric: true),
            DataColumn(label: Text('สถานะ')),
          ],
          rows: trips.map((t) => DataRow(cells: [
            DataCell(Text(t['date']!)),
            DataCell(Text(t['trip_no']!, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
            DataCell(Text(t['origin']!)),
            DataCell(Text(t['dest']!)),
            DataCell(Text('${t['km']!} กม.')),
            DataCell(Text('฿${t['revenue']!}')),
            DataCell(Chip(label: Text('เสร็จสิ้น', style: const TextStyle(fontSize: 11)), backgroundColor: Colors.green.shade50)),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildPerformanceTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: cs.outlineVariant)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ผลงานรวม', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    _kpiRow('เที่ยวรวม', '450 เที่ยว'),
                    _kpiRow('ตรงเวลา', '95%', color: Colors.green),
                    _kpiRow('ประสิทธิภาพน้ำมัน', '5.2 กม./ลิตร'),
                    _kpiRow('คะแนนลูกค้า', '4.8 / 5.0', color: Colors.green),
                    _kpiRow('อุบัติเหตุ', '1 ครั้ง', color: Colors.orange),
                    _kpiRow('ฝ่าฝืนกฎ', '0 ครั้ง', color: Colors.green),
                    const Divider(),
                    _kpiRow('คะแนนรวม', '92 / 100', bold: true, color: Colors.green),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: cs.outlineVariant)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ประวัติอุบัติเหตุ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.warning_amber, color: Colors.orange),
                      title: const Text('ชนกระบะ', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('15/05/2566 — ความเสียหายเล็กน้อย', style: TextStyle(fontSize: 11)),
                      trailing: const Text('฿5,000', style: TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                    const Divider(),
                    const Text('ไม่มีประวัติอุบัติเหตุอื่น', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  Widget _buildScheduleTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final leaves = [
      {'type': 'ลาป่วย', 'from': '01/12/2567', 'to': '02/12/2567', 'days': '2', 'status': 'approved'},
      {'type': 'ลากิจ', 'from': '15/01/2568', 'to': '15/01/2568', 'days': '1', 'status': 'approved'},
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: cs.outlineVariant)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ข้อมูลกะงาน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Divider(),
                  _kpiRow('กะงาน', 'เช้า (06:00 — 18:00)'),
                  _kpiRow('วันหยุดประจำ', 'วันอาทิตย์'),
                  _kpiRow('วันลาป่วยคงเหลือ', '3 วัน'),
                  _kpiRow('วันลากิจคงเหลือ', '5 วัน'),
                  _kpiRow('วันพักร้อนคงเหลือ', '10 วัน'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: cs.outlineVariant)),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(cs.surfaceContainerLow),
              columns: const [
                DataColumn(label: Text('ประเภทการลา')),
                DataColumn(label: Text('วันที่เริ่ม')),
                DataColumn(label: Text('วันที่สิ้นสุด')),
                DataColumn(label: Text('จำนวน'), numeric: true),
                DataColumn(label: Text('สถานะ')),
              ],
              rows: leaves.map((l) => DataRow(cells: [
                DataCell(Text(l['type']!)),
                DataCell(Text(l['from']!)),
                DataCell(Text(l['to']!)),
                DataCell(Text('${l['days']!} วัน')),
                DataCell(Chip(label: Text('อนุมัติ', style: const TextStyle(fontSize: 11)), backgroundColor: Colors.green.shade50)),
              ])).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
