import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app.dart' show Responsive;
import '../bloc/dashboard_bloc.dart';
import '../bloc/alert_bloc.dart';
import '../widgets/kpi_card.dart';
import '../widgets/cost_chart.dart';
import 'map_screen.dart';
import 'trips_screen.dart';
import 'vehicles_screen.dart';
import 'drivers_screen.dart';
import 'maintenance_screen.dart';
import 'partners_screen.dart';
import 'costs_screen.dart';
import 'alerts_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const _screens = [
    _DashboardBody(),
    MapScreen(),
    TripsScreen(),
    VehiclesScreen(),
    _MoreScreen(),
  ];

  static const _destinations = [
    (icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'ภาพรวม'),
    (icon: Icons.map_outlined, selectedIcon: Icons.map, label: 'แผนที่'),
    (icon: Icons.route_outlined, selectedIcon: Icons.route, label: 'เที่ยววิ่ง'),
    (icon: Icons.local_shipping_outlined, selectedIcon: Icons.local_shipping, label: 'รถ'),
    (icon: Icons.more_horiz, selectedIcon: Icons.more_horiz, label: 'เพิ่มเติม'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboard());
    context.read<AlertBloc>().add(LoadAlerts());
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isTabletOrDesktop(context);

    if (isWide) {
      // Tablet / Desktop: NavigationRail on the left
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              labelType: NavigationRailLabelType.all,
              destinations: _destinations.map((d) => NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: Text(d.label),
              )).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile: BottomNavigationBar
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _destinations.map((d) => NavigationDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.selectedIcon),
          label: d.label,
        )).toList(),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SML Fleet'),
        actions: [
          BlocBuilder<AlertBloc, AlertState>(
            builder: (context, state) {
              final count = state is AlertLoaded ? state.activeCount : 0;
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<DashboardBloc>().add(LoadDashboard()),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }
          if (state is DashboardLoaded) {
            return _DashboardContent(state: state);
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardLoaded state;
  const _DashboardContent({required this.state});

  String _formatCurrency(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = state.summary;
    final t = state.todayTrips;
    final kpi = state.kpi;

    final cols = Responsive.gridColumns(context, mobile: 2, tablet: 4, desktop: 4);
    final pad = Responsive.padding(context);

    return RefreshIndicator(
      onRefresh: () async => context.read<DashboardBloc>().add(RefreshDashboard()),
      child: ListView(
        padding: EdgeInsets.all(pad),
        children: [
          // Header date
          Text(
            'วันนี้ ${_thaiDate()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // KPI grid: 2 cols mobile, 4 cols tablet/desktop
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: cols == 2 ? 1.6 : 1.5,
            children: [
              KpiCard(
                icon: Icons.local_shipping_rounded,
                title: 'รถทั้งหมด',
                value: '${s.activeVehicles}/${s.totalVehicles}',
                subtitle: 'กำลังใช้งาน',
                iconColor: Colors.blue,
              ),
              KpiCard(
                icon: Icons.route_rounded,
                title: 'เที่ยววิ่งวันนี้',
                value: '${t.total}',
                subtitle: 'เสร็จ ${t.completed} / วิ่ง ${t.inProgress}',
                iconColor: Colors.indigo,
              ),
              KpiCard(
                icon: Icons.payments_rounded,
                title: 'รายได้วันนี้',
                value: '฿${_formatCurrency(t.totalRevenue)}',
                subtitle: 'กำไร ฿${_formatCurrency(t.totalProfit)}',
                changePercent: 12.5,
                iconColor: Colors.green,
              ),
              KpiCard(
                icon: Icons.notifications_active_rounded,
                title: 'แจ้งเตือน',
                value: '${s.activeAlerts}',
                subtitle: 'รายการที่ต้องดำเนินการ',
                iconColor: s.activeAlerts > 0 ? Colors.orange : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Vehicle health status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('สถานะรถ', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _HealthDot(color: Colors.green, count: s.activeVehicles - s.warningVehicles - s.criticalVehicles, label: 'ปกติ'),
                      const SizedBox(width: 16),
                      _HealthDot(color: Colors.orange, count: s.warningVehicles, label: 'เฝ้าระวัง'),
                      const SizedBox(width: 16),
                      _HealthDot(color: Colors.red, count: s.criticalVehicles, label: 'วิกฤต'),
                      const SizedBox(width: 16),
                      _HealthDot(color: Colors.grey, count: s.vehiclesInMaintenance, label: 'ซ่อม'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Revenue chart 7 days
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('รายได้ 7 วัน', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const CostChartLegend(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CostChart(data: kpi.weeklyRevenue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Recent alerts
          if (state.recentAlerts.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('แจ้งเตือนล่าสุด', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
                  child: const Text('ดูทั้งหมด'),
                ),
              ],
            ),
            ...state.recentAlerts.take(5).map((alert) => _AlertTile(alert: alert)),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _thaiDate() {
    final now = DateTime.now();
    const months = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    return '${now.day} ${months[now.month]} ${now.year + 543}';
  }
}

class _HealthDot extends StatelessWidget {
  final Color color;
  final int count;
  final String label;
  const _HealthDot({required this.color, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AlertItem alert;
  const _AlertTile({required this.alert});

  Color get _severityColor {
    switch (alert.severity) {
      case 'critical': return Colors.red;
      case 'warning': return Colors.orange;
      default: return Colors.blue;
    }
  }

  IconData get _severityIcon {
    switch (alert.severity) {
      case 'critical': return Icons.error_rounded;
      case 'warning': return Icons.warning_rounded;
      default: return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(_severityIcon, color: _severityColor),
        title: Text(alert.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(alert.message, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        dense: true,
      ),
    );
  }
}

// ─── More Screen (เมนูเพิ่มเติม) ─────────────────────────────────────────────

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เมนูเพิ่มเติม')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(title: 'คนขับรถ', icon: Icons.person_rounded, color: Colors.purple,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriversScreen()))),
          _MenuCard(title: 'ซ่อมบำรุง', icon: Icons.build_rounded, color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen()))),
          _MenuCard(title: 'รถร่วม', icon: Icons.handshake_rounded, color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnersScreen()))),
          _MenuCard(title: 'ต้นทุน', icon: Icons.account_balance_wallet_rounded, color: Colors.green,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CostsScreen()))),
          _MenuCard(title: 'แจ้งเตือน', icon: Icons.notifications_rounded, color: Colors.red,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()))),
          _MenuCard(title: 'รายงาน', icon: Icons.bar_chart_rounded, color: Colors.indigo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MenuCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
