import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://smlfleet.satistang.com/api/v1/fleet';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _recentTrips = [];
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadSummary(),
      _loadTrips(),
      _loadAlerts(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadSummary() async {
    try {
      final res = await http.get(Uri.parse('$_apiBase/dashboard/summary'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        _summary = (body['data'] as Map<String, dynamic>?) ?? body;
      }
    } catch (_) {}
  }

  Future<void> _loadTrips() async {
    try {
      final res = await http.get(Uri.parse('$_apiBase/trips?limit=5&status=in_progress'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        _recentTrips = (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      }
    } catch (_) {}
  }

  Future<void> _loadAlerts() async {
    try {
      final res = await http.get(Uri.parse('$_apiBase/dashboard/alerts'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        _alerts = (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      }
    } catch (_) {}
  }

  List<_KpiCard> get _kpiData => [
    _KpiCard(
      label: 'รถทั้งหมด',
      value: '${_summary['total_vehicles'] ?? _summary['active_vehicles'] ?? '-'}',
      sub: '${_summary['active_vehicles'] ?? '-'} คันวิ่งอยู่',
      icon: Icons.local_shipping,
      color: const Color(0xFF1565C0),
    ),
    _KpiCard(
      label: 'เที่ยววิ่งวันนี้',
      value: '${_summary['today_trips'] ?? _summary['total_trips'] ?? '-'}',
      sub: '${_summary['completed_trips'] ?? '-'} เสร็จแล้ว',
      icon: Icons.route,
      color: const Color(0xFF2E7D32),
    ),
    _KpiCard(
      label: 'รายได้วันนี้',
      value: _summary['today_revenue'] != null ? '฿${_summary['today_revenue']}' : '-',
      sub: 'รวมทุกเที่ยว',
      icon: Icons.attach_money,
      color: const Color(0xFFE65100),
    ),
    _KpiCard(
      label: 'แจ้งเตือน',
      value: '${_alerts.length}',
      sub: '${_alerts.where((a) => a['severity'] == 'critical').length} วิกฤต',
      icon: Icons.notifications_active,
      color: const Color(0xFFC62828),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final padding = isMobile ? 16.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('แดชบอร์ดภาพรวม', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text('SML Fleet — ข้อมูลจาก API จริง', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 16),
                label: isMobile ? const SizedBox.shrink() : const Text('รีเฟรช'),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),

          // KPI Cards — 2 cols on mobile, 4 cols on tablet+
          if (isMobile)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: _kpiData.map((k) => _buildKpiCard(context, k, compact: true)).toList(),
            )
          else
            Row(
              children: _kpiData.map((k) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildKpiCard(context, k, compact: false),
                ),
              )).toList(),
            ),
          SizedBox(height: isMobile ? 16 : 24),

          // Charts + Alerts
          if (isMobile) ...[
            // Mobile: stack vertically, charts scrollable
            _buildChartPlaceholder(context, title: 'เที่ยววิ่งรายสัปดาห์', subtitle: '7 วันที่ผ่านมา', height: 180, icon: Icons.bar_chart, color: cs.primary),
            const SizedBox(height: 12),
            _buildChartPlaceholder(context, title: 'สัดส่วนต้นทุน', subtitle: 'เดือนปัจจุบัน', height: 180, icon: Icons.pie_chart, color: cs.tertiary),
            const SizedBox(height: 12),
            _buildAlertsCard(context),
          ] else if (isTablet) ...[
            // Tablet: 2 charts side by side, alerts below
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildChartPlaceholder(context, title: 'เที่ยววิ่งรายสัปดาห์', subtitle: '7 วันที่ผ่านมา', height: 200, icon: Icons.bar_chart, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChartPlaceholder(context, title: 'สัดส่วนต้นทุน', subtitle: 'เดือนปัจจุบัน', height: 200, icon: Icons.pie_chart, color: cs.tertiary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAlertsCard(context),
          ] else ...[
            // Desktop: charts + alerts side by side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildChartPlaceholder(context, title: 'เที่ยววิ่งรายสัปดาห์', subtitle: '7 วันที่ผ่านมา', height: 220, icon: Icons.bar_chart, color: cs.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildChartPlaceholder(context, title: 'สัดส่วนต้นทุน', subtitle: 'เดือนปัจจุบัน', height: 220, icon: Icons.pie_chart, color: cs.tertiary),
                ),
                const SizedBox(width: 16),
                SizedBox(width: 280, child: _buildAlertsCard(context)),
              ],
            ),
          ],
          SizedBox(height: isMobile ? 16 : 24),

          // Recent Trips
          _buildRecentTripsTable(context),
        ],
      ),
    );
  }

  Widget _buildKpiCard(BuildContext context, _KpiCard k, {bool compact = false}) {
    final pad = compact ? 12.0 : 20.0;
    final iconSize = compact ? 36.0 : 48.0;
    final valueSize = compact ? 20.0 : 24.0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: k.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(k.icon, color: k.color, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(k.label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(k.value, style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.bold, color: k.color)),
                  Text(k.sub, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
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
                        Text(k.value, style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.bold, color: k.color)),
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
            if (_alerts.isEmpty && !_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('ไม่มีแจ้งเตือน', style: TextStyle(color: Colors.grey))),
              )
            else
              ..._alerts.take(5).map((a) => _buildAlertTile(context, a)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(BuildContext context, Map<String, dynamic> a) {
    final severity = a['severity'] as String? ?? 'info';
    final title = a['title'] as String? ?? '';
    final message = a['message'] as String? ?? '';
    Color color = switch (severity) {
      'critical' => Colors.red,
      'warning' => Colors.orange,
      _ => Colors.blue,
    };
    IconData icon = switch (severity) {
      'critical' => Icons.warning_amber,
      'warning' => Icons.info_outline,
      _ => Icons.notifications_outlined,
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
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color)),
                Text(message, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTripsTable(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
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
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (_recentTrips.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('ไม่มีข้อมูลเที่ยววิ่ง', style: TextStyle(color: Colors.grey)),
              ))
            else if (isMobile)
              // Mobile: card list
              Column(
                children: _recentTrips.map((t) => _buildTripCard(context, t)).toList(),
              )
            else
              // Tablet/Desktop: table (horizontal scroll)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
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
                    ..._recentTrips.map((t) {
                      final origin = (t['origin'] as Map?) ?? {'name': t['origin_name'] ?? ''};
                      final destinations = t['destinations'] as List?;
                      final dest = destinations?.isNotEmpty == true ? (destinations!.first as Map?) : null;
                      final driverName = t['driver_name'] ?? t['driver_id'] ?? '';
                      final plate = t['vehicle_plate'] ?? t['vehicle_id'] ?? '';
                      final status = t['status'] as String? ?? '';
                      final revenue = t['costs']?['revenue'] ?? t['revenue'] ?? '';
                      return TableRow(
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                        children: [
                          _cell(t['trip_no'] as String? ?? ''),
                          _cell(origin['name'] as String? ?? ''),
                          _cell(dest?['name'] as String? ?? ''),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(driverName.toString(), style: const TextStyle(fontSize: 12)),
                                Text(plate.toString(), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: _StatusBadge(status: status),
                          ),
                          _cell(revenue != '' ? '฿$revenue' : '-'),
                        ],
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Map<String, dynamic> t) {
    final cs = Theme.of(context).colorScheme;
    final origin = (t['origin'] as Map?) ?? {'name': t['origin_name'] ?? ''};
    final destinations = t['destinations'] as List?;
    final dest = destinations?.isNotEmpty == true ? (destinations!.first as Map?) : null;
    final driverName = t['driver_name'] ?? t['driver_id'] ?? '-';
    final plate = t['vehicle_plate'] ?? t['vehicle_id'] ?? '-';
    final status = t['status'] as String? ?? '';
    final revenue = t['costs']?['revenue'] ?? t['revenue'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t['trip_no'] as String? ?? '', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(child: Text(origin['name'] as String? ?? '', style: const TextStyle(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.location_on, size: 8, color: Colors.red),
              const SizedBox(width: 6),
              Expanded(child: Text(dest?['name'] as String? ?? '-', style: const TextStyle(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(driverName.toString(), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(width: 8),
              Icon(Icons.local_shipping_outlined, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(plate.toString(), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const Spacer(),
              if (revenue != '')
                Text('฿$revenue', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
            ],
          ),
        ],
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'completed' => ('เสร็จสิ้น', Colors.green),
      'in_progress' || 'started' || 'delivering' => ('กำลังวิ่ง', Colors.blue),
      'pending' || 'accepted' => ('รอดำเนินการ', Colors.orange),
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
