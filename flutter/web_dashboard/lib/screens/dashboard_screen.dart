import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock data
  final _kpiData = [
    _KpiCard(label: 'รถทั้งหมด', value: '24', sub: '18 คันวิ่งอยู่', icon: Icons.local_shipping, color: Color(0xFF1565C0)),
    _KpiCard(label: 'เที่ยววิ่งวันนี้', value: '37', sub: '12 เสร็จแล้ว', icon: Icons.route, color: Color(0xFF2E7D32)),
    _KpiCard(label: 'รายได้วันนี้', value: '฿125,400', sub: 'เป้า ฿150,000', icon: Icons.attach_money, color: Color(0xFFE65100)),
    _KpiCard(label: 'แจ้งเตือน', value: '5', sub: '2 วิกฤต', icon: Icons.notifications_active, color: Color(0xFFC62828)),
  ];

  final _recentTrips = [
    {'no': 'TRIP-2026-001234', 'origin': 'คลังสินค้า ABC', 'dest': 'ร้าน XYZ ลำพูน', 'driver': 'สมชาย ใจดี', 'plate': 'กท-1234', 'status': 'in_progress', 'revenue': '2,500'},
    {'no': 'TRIP-2026-001233', 'origin': 'โรงงาน DEF', 'dest': 'ห้าง GHI เชียงราย', 'driver': 'วิชัย ขับดี', 'plate': '2กร-5678', 'status': 'completed', 'revenue': '5,800'},
    {'no': 'TRIP-2026-001232', 'origin': 'ท่าเรือ JKL', 'dest': 'ศูนย์กระจายสินค้า', 'driver': 'สมศักดิ์ รักงาน', 'plate': 'ชม-3456', 'status': 'pending', 'revenue': '3,200'},
    {'no': 'TRIP-2026-001231', 'origin': 'คลัง MNO', 'dest': 'ลูกค้า PQR ลำปาง', 'driver': 'ประสิทธิ์ มีน้ำใจ', 'plate': 'กน-7890', 'status': 'completed', 'revenue': '4,100'},
    {'no': 'TRIP-2026-001230', 'origin': 'สำนักงานใหญ่', 'dest': 'ลูกค้า STU เชียงใหม่', 'driver': 'อนุชา ตั้งใจ', 'plate': 'ลป-1122', 'status': 'started', 'revenue': '1,800'},
  ];

  final _alerts = [
    _AlertItem(title: 'ประกันภัยใกล้หมดอายุ', msg: 'รถ กท-1234 — เหลือ 15 วัน', severity: 'critical', icon: Icons.warning_amber),
    _AlertItem(title: 'พ.ร.บ. ครบกำหนด', msg: 'รถ ชม-3456 — เหลือ 7 วัน', severity: 'critical', icon: Icons.gavel),
    _AlertItem(title: 'ซ่อมบำรุงครบรอบ', msg: 'รถ 2กร-5678 — น้ำมันเครื่อง 10,000 กม.', severity: 'warning', icon: Icons.build),
    _AlertItem(title: 'ใบขับขี่ใกล้หมดอายุ', msg: 'สมชาย ใจดี — เหลือ 30 วัน', severity: 'warning', icon: Icons.badge),
    _AlertItem(title: 'สต๊อกอะไหล่ต่ำ', msg: 'น้ำมันเครื่อง SHELL เหลือ 8 ลิตร', severity: 'info', icon: Icons.inventory),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('แดชบอร์ดภาพรวม', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('วันอังคารที่ 31 มีนาคม 2569 — อัปเดตล่าสุด 09:45 น.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('รีเฟรช'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // KPI Cards Row
          Row(
            children: _kpiData.map((k) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildKpiCard(context, k),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),

          // Charts + Alerts row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart 1 — เที่ยววิ่งรายสัปดาห์
              Expanded(
                flex: 3,
                child: _buildChartPlaceholder(
                  context,
                  title: 'เที่ยววิ่งรายสัปดาห์',
                  subtitle: '7 วันที่ผ่านมา',
                  height: 220,
                  icon: Icons.bar_chart,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 16),
              // Chart 2 — สัดส่วนต้นทุน
              Expanded(
                flex: 2,
                child: _buildChartPlaceholder(
                  context,
                  title: 'สัดส่วนต้นทุน',
                  subtitle: 'เดือนมีนาคม 2569',
                  height: 220,
                  icon: Icons.pie_chart,
                  color: cs.tertiary,
                ),
              ),
              const SizedBox(width: 16),
              // Alerts sidebar
              SizedBox(
                width: 300,
                child: _buildAlertsCard(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Trips Table
          _buildRecentTripsTable(context),
        ],
      ),
    );
  }

  Widget _buildKpiCard(BuildContext context, _KpiCard k) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: k.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(k.icon, color: k.color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k.label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text(k.value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: k.color)),
                  Text(k.sub, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder(BuildContext context, {
    required String title,
    required String subtitle,
    required double height,
    required IconData icon,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const Spacer(),
                Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: height,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 40, color: color.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text('กราฟ $title', style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 13)),
                    Text('(เชื่อมต่อ fl_chart)', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                const Text('แจ้งเตือนล่าสุด', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const Spacer(),
                Badge(label: Text('${_alerts.length}'), child: const SizedBox.shrink()),
              ],
            ),
            const Divider(height: 20),
            ..._alerts.map((a) => _buildAlertTile(context, a)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(BuildContext context, _AlertItem a) {
    Color color = switch (a.severity) {
      'critical' => Colors.red,
      'warning' => Colors.orange,
      _ => Colors.blue,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(a.icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color)),
                Text(a.msg, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTripsTable(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, size: 20),
                const SizedBox(width: 8),
                const Text('เที่ยววิ่งล่าสุด', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('ดูทั้งหมด')),
              ],
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(1.5),
                5: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(6)),
                  children: ['เลขที่เที่ยว', 'ต้นทาง', 'ปลายทาง', 'คนขับ / รถ', 'สถานะ', 'รายได้']
                      .map((h) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Text(h, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ))
                      .toList(),
                ),
                ..._recentTrips.map((t) => TableRow(
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                      children: [
                        _cell(t['no']!),
                        _cell(t['origin']!),
                        _cell(t['dest']!),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['driver']!, style: const TextStyle(fontSize: 12)),
                              Text(t['plate']!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: _StatusBadge(status: t['status']!),
                        ),
                        _cell('฿${t['revenue']!}'),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      );
}

class _KpiCard {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.sub, required this.icon, required this.color});
}

class _AlertItem {
  final String title, msg, severity;
  final IconData icon;
  const _AlertItem({required this.title, required this.msg, required this.severity, required this.icon});
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'completed' => ('เสร็จสิ้น', Colors.green),
      'in_progress' || 'started' => ('กำลังวิ่ง', Colors.blue),
      'pending' => ('รอดำเนินการ', Colors.orange),
      'cancelled' => ('ยกเลิก', Colors.red),
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
