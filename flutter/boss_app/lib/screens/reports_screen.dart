import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงาน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _showExportDialog(context),
            tooltip: 'Export',
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardLoaded) {
            return _ReportsContent(state: state);
          }
          return const Center(child: Text('ไม่มีข้อมูล'));
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export รายงาน',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ExportOption(
              icon: Icons.picture_as_pdf_rounded,
              label: 'Export PDF',
              subtitle: 'สรุปรายงานทั้งหมด',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลังสร้าง PDF...')),
                );
              },
            ),
            const SizedBox(height: 8),
            _ExportOption(
              icon: Icons.table_chart_rounded,
              label: 'Export Excel',
              subtitle: 'ข้อมูลดิบสำหรับวิเคราะห์',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลังสร้าง Excel...')),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ReportsContent extends StatelessWidget {
  final DashboardLoaded state;
  const _ReportsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period selector
        _PeriodSelector(),
        const SizedBox(height: 16),

        // Report cards
        _ReportCard(
          icon: Icons.receipt_long_rounded,
          title: 'รายงานต้นทุนขนส่ง',
          subtitle: 'ต้นทุนรวม ต้นทุนต่อเที่ยว รายรับ กำไร',
          color: Colors.indigo,
          onTap: () => _showReportDetail(context, 'cost'),
          stats: [
            _StatItem(label: 'ต้นทุนรวม', value: '฿108,300'),
            _StatItem(label: 'รายรับรวม', value: '฿187,500'),
            _StatItem(label: 'กำไรสุทธิ', value: '฿79,200'),
          ],
        ),
        const SizedBox(height: 12),

        _ReportCard(
          icon: Icons.directions_car_rounded,
          title: 'รายงานการใช้รถ',
          subtitle: 'อัตราการใช้รถ จำนวนเที่ยว ระยะทาง',
          color: Colors.blue,
          onTap: () => _showReportDetail(context, 'utilization'),
          stats: [
            _StatItem(label: 'อัตราใช้รถ', value: '78%'),
            _StatItem(label: 'เที่ยวรวม', value: '124 เที่ยว'),
            _StatItem(label: 'ระยะทาง', value: '5,840 กม.'),
          ],
        ),
        const SizedBox(height: 12),

        _ReportCard(
          icon: Icons.local_gas_station_rounded,
          title: 'รายงานน้ำมันเชื้อเพลิง',
          subtitle: 'ปริมาณน้ำมัน ค่าเฉลี่ย อัตราสิ้นเปลือง',
          color: Colors.orange,
          onTap: () => _showReportDetail(context, 'fuel'),
          stats: [
            _StatItem(label: 'รวม', value: '1,240 ลิตร'),
            _StatItem(label: 'เฉลี่ย', value: '฿28.5/ลิตร'),
            _StatItem(label: 'ประสิทธิภาพ', value: '5.2 km/L'),
          ],
        ),
        const SizedBox(height: 12),

        _ReportCard(
          icon: Icons.person_rounded,
          title: 'รายงานผลงานคนขับ',
          subtitle: 'คะแนน ตรงเวลา ประหยัดน้ำมัน',
          color: Colors.teal,
          onTap: () => _showReportDetail(context, 'driver'),
          stats: [
            _StatItem(label: 'คะแนนเฉลี่ย', value: '88/100'),
            _StatItem(label: 'ตรงเวลา', value: '91%'),
            _StatItem(label: 'Top driver', value: 'ประสิทธิ์'),
          ],
        ),
        const SizedBox(height: 12),

        _ReportCard(
          icon: Icons.build_rounded,
          title: 'รายงานซ่อมบำรุง',
          subtitle: 'ใบสั่งซ่อม ต้นทุน อะไหล่',
          color: Colors.red,
          onTap: () => _showReportDetail(context, 'maintenance'),
          stats: [
            _StatItem(label: 'ใบสั่งซ่อม', value: '8 ใบ'),
            _StatItem(label: 'ต้นทุนรวม', value: '฿18,500'),
            _StatItem(label: 'เฉลี่ย/คัน', value: '฿2,313'),
          ],
        ),
        const SizedBox(height: 12),

        _ReportCard(
          icon: Icons.handshake_rounded,
          title: 'รายงานรถร่วม',
          subtitle: 'จำนวนเที่ยว ต้นทุนรถร่วม การชำระเงิน',
          color: Colors.purple,
          onTap: () => _showReportDetail(context, 'partner'),
          stats: [
            _StatItem(label: 'เที่ยวรถร่วม', value: '22 เที่ยว'),
            _StatItem(label: 'ต้นทุน', value: '฿14,200'),
            _StatItem(label: 'ชำระแล้ว', value: '฿8,500'),
          ],
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  void _showReportDetail(BuildContext context, String type) {
    final titles = {
      'cost': 'รายงานต้นทุนขนส่ง',
      'utilization': 'รายงานการใช้รถ',
      'fuel': 'รายงานน้ำมันเชื้อเพลิง',
      'driver': 'รายงานผลงานคนขับ',
      'maintenance': 'รายงานซ่อมบำรุง',
      'partner': 'รายงานรถร่วม',
    };
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titles[type] ?? 'รายงาน'),
        content: const Text('รายงานฉบับเต็มกำลังพัฒนา\nจะเชื่อมกับ API จริงในเร็วๆ นี้'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('กำลัง Export...')),
              );
            },
            child: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatefulWidget {
  @override
  State<_PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<_PeriodSelector> {
  int _selected = 1; // 0=วันนี้, 1=เดือนนี้, 2=ไตรมาส, 3=ปีนี้

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = ['วันนี้', 'เดือนนี้', 'ไตรมาส', 'ปีนี้'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(labels.length, (i) {
            final isSelected = _selected == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final List<_StatItem> stats;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: stats.map((s) => Expanded(
                  child: Column(
                    children: [
                      Text(
                        s.value,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
