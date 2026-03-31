import 'package:flutter/material.dart';

class KpiDashboardScreen extends StatefulWidget {
  const KpiDashboardScreen({super.key});

  @override
  State<KpiDashboardScreen> createState() => _KpiDashboardScreenState();
}

class _KpiDashboardScreenState extends State<KpiDashboardScreen> {
  String _filterMonth = '03/2569';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('KPI Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                DropdownButton<String>(
                  value: _filterMonth,
                  items: const [
                    DropdownMenuItem(value: '03/2569', child: Text('มีนาคม 2569')),
                    DropdownMenuItem(value: '02/2569', child: Text('กุมภาพันธ์ 2569')),
                    DropdownMenuItem(value: '01/2569', child: Text('มกราคม 2569')),
                  ],
                  onChanged: (v) => setState(() => _filterMonth = v!),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Export PDF'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Fleet KPIs
            Text('ภาพรวมกองรถ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cs.primary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildKpiTile(cs, 'อัตราการใช้รถ', '87.5%', 87.5, Colors.blue, Icons.directions_car_outlined, 'เป้าหมาย 85%', true),
                _buildKpiTile(cs, 'เที่ยววิ่งตรงเวลา', '92.3%', 92.3, Colors.green, Icons.schedule, 'เป้าหมาย 90%', true),
                _buildKpiTile(cs, 'อัตราน้ำมัน (กม./ลิตร)', '60.8', 60.8, Colors.orange, Icons.local_gas_station_outlined, 'เป้าหมาย 60', true),
                _buildKpiTile(cs, 'ค่าซ่อมต่อคัน/เดือน', '฿4,040', 60.0, Colors.red, Icons.build_outlined, 'เป้าหมาย ฿5,000', true),
                _buildKpiTile(cs, 'รายรับเฉลี่ยต่อเที่ยว', '฿5,333', 75.0, cs.primary, Icons.payments_outlined, 'เป้าหมาย ฿5,000', true),
                _buildKpiTile(cs, 'Profit Margin', '65.2%', 65.2, Colors.teal, Icons.trending_up, 'เป้าหมาย 60%', true),
              ],
            ),
            const SizedBox(height: 24),

            // Driver KPIs
            Text('ผลงานคนขับ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cs.primary)),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(cs.surfaceContainerLow),
                columns: const [
                  DataColumn(label: Text('อันดับ')),
                  DataColumn(label: Text('คนขับ')),
                  DataColumn(label: Text('เที่ยว'), numeric: true),
                  DataColumn(label: Text('ตรงเวลา %'), numeric: true),
                  DataColumn(label: Text('ประหยัดน้ำมัน'), numeric: true),
                  DataColumn(label: Text('Rating'), numeric: true),
                  DataColumn(label: Text('คะแนนรวม'), numeric: true),
                ],
                rows: [
                  _driverRow(1, 'อนุชา ขนดี', '15', '96.7%', '62.5', '4.8', '96', cs),
                  _driverRow(2, 'สมบัติ ลากดี', '6', '100%', '58.3', '4.7', '93', cs),
                  _driverRow(3, 'ชัยวัฒน์ ขับดี', '9', '88.9%', '71.4', '4.6', '89', cs),
                  _driverRow(4, 'สมชาย ใจดี', '12', '91.7%', '60.4', '4.5', '87', cs),
                  _driverRow(5, 'ประสิทธิ์ มีรถ', '10', '80.0%', '61.1', '4.2', '78', cs),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle health
            Text('สุขภาพรถ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cs.primary)),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(cs.surfaceContainerLow),
                columns: const [
                  DataColumn(label: Text('รถ')),
                  DataColumn(label: Text('กม.ปัจจุบัน'), numeric: true),
                  DataColumn(label: Text('ซ่อมเดือนนี้'), numeric: true),
                  DataColumn(label: Text('ซ่อมสะสม'), numeric: true),
                  DataColumn(label: Text('รายการค้างซ่อม'), numeric: true),
                  DataColumn(label: Text('สถานะ')),
                ],
                rows: [
                  _vehicleHealthRow('กท-1234', 'ISUZU FRR', '94,400', '฿4,040', '฿18,540', '0', 'green'),
                  _vehicleHealthRow('2กร-5678', 'HINO 500', '99,000', '฿0', '฿6,200', '1', 'yellow'),
                  _vehicleHealthRow('ชม-3456', 'ISUZU NQR', '103,500', '฿1,200', '฿3,700', '1', 'red'),
                  _vehicleHealthRow('กน-7890', 'HINO 700', '89,500', '฿8,500', '฿8,500', '0', 'yellow'),
                  _vehicleHealthRow('ลป-1122', 'ISUZU FTR', '76,000', '฿2,500', '฿2,500', '0', 'green'),
                  _vehicleHealthRow('พย-3344', 'ISUZU FVR', '96,500', '฿0', '฿0', '0', 'green'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Alerts summary
            Text('สรุปการแจ้งเตือน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cs.primary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAlertSummaryCard(cs, 'พ.ร.บ. ใกล้หมด', '2 คัน', Colors.red, Icons.policy_outlined),
                const SizedBox(width: 12),
                _buildAlertSummaryCard(cs, 'ประกันใกล้หมด', '1 คัน', Colors.orange, Icons.shield_outlined),
                const SizedBox(width: 12),
                _buildAlertSummaryCard(cs, 'ซ่อมบำรุงค้าง', '2 รายการ', Colors.orange, Icons.build_outlined),
                const SizedBox(width: 12),
                _buildAlertSummaryCard(cs, 'ใบขับขี่ใกล้หมด', '1 คน', Colors.yellow[700]!, Icons.badge_outlined),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  DataRow _driverRow(int rank, String name, String trips, String onTime, String fuel, String rating, String score, ColorScheme cs) {
    final scoreInt = int.tryParse(score) ?? 0;
    return DataRow(cells: [
      DataCell(Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: rank <= 3 ? [Colors.amber, Colors.grey[400]!, Colors.brown[300]!][rank - 1] : cs.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Center(child: Text('$rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
            color: rank <= 3 ? Colors.white : cs.onSurface))),
      )),
      DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
      DataCell(Text(trips)),
      DataCell(Text(onTime)),
      DataCell(Text('$fuel กม./ลิตร')),
      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.star, size: 14, color: Colors.amber[600]),
        const SizedBox(width: 4),
        Text(rating),
      ])),
      DataCell(_ScoreBadge(score: scoreInt)),
    ]);
  }

  DataRow _vehicleHealthRow(String plate, String model, String km, String thisMo, String total, String pending, String status) {
    return DataRow(
      color: status == 'red' ? WidgetStateProperty.all(Colors.red.withValues(alpha: 0.05)) : null,
      cells: [
        DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(plate, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(model, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ])),
        DataCell(Text('$km กม.')),
        DataCell(Text(thisMo, style: TextStyle(color: thisMo == '฿0' ? Colors.grey[400] : Colors.red[600]))),
        DataCell(Text(total, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(pending, style: TextStyle(color: pending == '0' ? Colors.grey[400] : Colors.orange[700]))),
        DataCell(_VehicleHealthChip(status: status)),
      ],
    );
  }

  Widget _buildKpiTile(ColorScheme cs, String label, String value, double pct, Color color, IconData icon, String target, bool isGood) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isGood ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isGood ? Icons.check_circle_outline : Icons.warning_outlined,
                      size: 12, color: isGood ? Colors.green : Colors.red),
                  const SizedBox(width: 3),
                  Text(isGood ? 'ผ่าน' : 'ไม่ผ่าน',
                      style: TextStyle(fontSize: 10, color: isGood ? Colors.green[700] : Colors.red[700])),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              backgroundColor: cs.surfaceContainerLow,
              color: color,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(target, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildAlertSummaryCard(ColorScheme cs, String label, String value, Color color, IconData icon) {
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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ]),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 90 ? Colors.green : score >= 80 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text('$score', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _VehicleHealthChip extends StatelessWidget {
  final String status;
  const _VehicleHealthChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'green' => ('ปกติ', Colors.green),
      'yellow' => ('เฝ้าระวัง', Colors.orange),
      'red' => ('วิกฤต', Colors.red),
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
