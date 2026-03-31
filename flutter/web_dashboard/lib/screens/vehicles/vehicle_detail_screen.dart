import 'package:flutter/material.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String? vehicleId;
  const VehicleDetailScreen({super.key, this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> with SingleTickerProviderStateMixin {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('รายละเอียดรถ: กท-1234', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Text('ISUZU FRR 210 — ปี 2023', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const Spacer(),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 16), label: const Text('แก้ไข')),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.assignment, size: 16), label: const Text('สร้างใบสั่งซ่อม')),
            ],
          ),
          const SizedBox(height: 16),

          // Health Status Row
          Row(
            children: [
              _buildHealthCard(context, 'สุขภาพรถ', 'ปกติ', Colors.green, Icons.check_circle),
              const SizedBox(width: 12),
              _buildHealthCard(context, 'ประกันภัย', 'เหลือ 15 วัน', Colors.orange, Icons.warning),
              const SizedBox(width: 12),
              _buildHealthCard(context, 'พ.ร.บ.', 'ปกติ — 8 เดือน', Colors.green, Icons.verified),
              const SizedBox(width: 12),
              _buildHealthCard(context, 'เลขไมล์', '85,000 กม.', Colors.blue, Icons.speed),
            ],
          ),
          const SizedBox(height: 16),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'ข้อมูลรถ'),
              Tab(text: 'ประวัติซ่อมบำรุง'),
              Tab(text: 'ค่าใช้จ่าย'),
              Tab(text: 'เอกสาร'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(context),
                _buildMaintenanceHistoryTab(context),
                _buildCostTab(context),
                _buildDocumentsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(BuildContext context, String label, String value, Color color, IconData icon) {
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

  Widget _buildInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildInfoSection('ข้อมูลทั่วไป', [
              ('ทะเบียน', 'กท-1234'),
              ('ยี่ห้อ', 'ISUZU'),
              ('รุ่น', 'FRR 210'),
              ('ปี', '2023'),
              ('สี', 'ขาว'),
              ('ประเภท', '6 ล้อ'),
              ('เชื้อเพลิง', 'ดีเซล'),
              ('น้ำหนักบรรทุกสูงสุด', '6,000 กก.'),
              ('การเป็นเจ้าของ', 'รถตัวเอง'),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInfoSection('เลขตัวถัง / เครื่องยนต์', [
              ('เลขตัวถัง', 'MPATFS66JMT000123'),
              ('เลขเครื่องยนต์', '4HK1-123456'),
              ('เลขไมล์ปัจจุบัน', '85,000 กม.'),
              ('คนขับประจำ', 'สมชาย ใจดี'),
              ('สถานะ', 'ใช้งาน'),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInfoSection('วันสำคัญ', [
              ('ประกันภัย ชั้น 1', '01/01/2025 — 01/01/2026'),
              ('ภาษีรถยนต์', 'ครบกำหนด 15/03/2025'),
              ('พ.ร.บ.', 'ครบกำหนด 15/03/2025'),
              ('ตรวจสภาพรถล่าสุด', '01/06/2024'),
              ('ตรวจสภาพรถครั้งถัดไป', '01/06/2025'),
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

  Widget _buildMaintenanceHistoryTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final history = [
      {'date': '10/12/2024', 'type': 'ป้องกัน', 'desc': 'เปลี่ยนน้ำมันเครื่อง + กรอง', 'cost': '4,040', 'by': 'ช่างสมศักดิ์', 'status': 'เสร็จสิ้น'},
      {'date': '01/09/2024', 'type': 'แก้ไข', 'desc': 'ซ่อมระบบเบรค', 'cost': '8,500', 'by': 'อู่หมอเล็ก', 'status': 'เสร็จสิ้น'},
      {'date': '01/06/2024', 'type': 'ป้องกัน', 'desc': 'เปลี่ยนยาง 4 เส้น', 'cost': '22,000', 'by': 'ช่างสมศักดิ์', 'status': 'เสร็จสิ้น'},
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
            DataColumn(label: Text('ประเภท')),
            DataColumn(label: Text('รายละเอียด')),
            DataColumn(label: Text('ค่าใช้จ่าย'), numeric: true),
            DataColumn(label: Text('ผู้ดำเนินการ')),
            DataColumn(label: Text('สถานะ')),
          ],
          rows: history.map((h) => DataRow(cells: [
            DataCell(Text(h['date']!)),
            DataCell(Text(h['type']!)),
            DataCell(Text(h['desc']!)),
            DataCell(Text('฿${h['cost']!}')),
            DataCell(Text(h['by']!)),
            DataCell(Chip(label: Text(h['status']!, style: const TextStyle(fontSize: 11)), backgroundColor: Colors.green.shade50)),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildCostTab(BuildContext context) {
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
                    const Text('ต้นทุนสะสม (ปีนี้)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    _costRow('ค่าน้ำมัน', '฿48,200'),
                    _costRow('ค่าซ่อมบำรุง', '฿34,540'),
                    _costRow('ค่าทางด่วน', '฿3,600'),
                    _costRow('ค่าประกันภัย', '฿25,000'),
                    _costRow('ค่าภาษี', '฿3,200'),
                    const Divider(),
                    _costRow('รวม', '฿114,540', bold: true),
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
                    const Text('รายได้ vs ต้นทุน (ปีนี้)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    _costRow('รายได้รวม', '฿385,000', color: Colors.green),
                    _costRow('ต้นทุนรวม', '฿114,540', color: Colors.red),
                    const Divider(),
                    _costRow('กำไร', '฿270,460', bold: true, color: Colors.green),
                    _costRow('อัตรากำไร', '70.2%', color: Colors.green),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _costRow(String label, String value, {bool bold = false, Color? color}) {
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

  Widget _buildDocumentsTab(BuildContext context) {
    final docs = [
      {'name': 'สมุดทะเบียน', 'type': 'registration', 'date': '01/01/2023', 'size': '2.3 MB'},
      {'name': 'กรมธรรม์ประกันภัย', 'type': 'insurance', 'date': '01/01/2025', 'size': '1.8 MB'},
      {'name': 'พ.ร.บ.', 'type': 'act', 'date': '15/03/2024', 'size': '0.9 MB'},
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          ...docs.map((d) => SizedBox(
            width: 220,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(d['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('${d['date']!} — ${d['size']!}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(height: 8),
                    TextButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 14), label: const Text('ดาวน์โหลด')),
                  ],
                ),
              ),
            ),
          )),
          SizedBox(
            width: 220,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.blue.shade200, style: BorderStyle.solid),
              ),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, color: Colors.blue.shade300, size: 32),
                      const SizedBox(height: 8),
                      Text('อัปโหลดเอกสาร', style: TextStyle(color: Colors.blue.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
