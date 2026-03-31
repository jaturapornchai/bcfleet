import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/vehicles/vehicle_list_screen.dart';
import 'screens/vehicles/vehicle_form_screen.dart';
import 'screens/drivers/driver_list_screen.dart';
import 'screens/drivers/driver_form_screen.dart';
import 'screens/trips/trip_list_screen.dart';
import 'screens/trips/trip_planning_screen.dart';
import 'screens/trips/trip_map_screen.dart';
import 'screens/maintenance/work_order_list_screen.dart';
import 'screens/maintenance/work_order_form_screen.dart';
import 'screens/maintenance/schedule_screen.dart';
import 'screens/maintenance/parts_inventory_screen.dart';
import 'screens/partners/partner_list_screen.dart';
import 'screens/partners/partner_register_screen.dart';
import 'screens/partners/partner_settlement_screen.dart';
import 'screens/costs/cost_overview_screen.dart';
import 'screens/costs/fuel_report_screen.dart';
import 'screens/costs/pl_per_vehicle_screen.dart';
import 'screens/reports/kpi_dashboard_screen.dart';
import 'screens/reports/export_screen.dart';

class BCFleetWebApp extends StatelessWidget {
  const BCFleetWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BC Fleet Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AppShell(),
    );
  }
}

enum NavSection {
  dashboard,
  vehicles,
  drivers,
  trips,
  maintenance,
  partners,
  costs,
  reports,
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  NavSection _selected = NavSection.dashboard;
  int _subIndex = 0;

  static const _navItems = [
    (NavSection.dashboard, Icons.dashboard_outlined, Icons.dashboard, 'แดชบอร์ด'),
    (NavSection.vehicles, Icons.local_shipping_outlined, Icons.local_shipping, 'ทะเบียนรถ'),
    (NavSection.drivers, Icons.person_outlined, Icons.person, 'คนขับรถ'),
    (NavSection.trips, Icons.route_outlined, Icons.route, 'เที่ยววิ่ง'),
    (NavSection.maintenance, Icons.build_outlined, Icons.build, 'ซ่อมบำรุง'),
    (NavSection.partners, Icons.handshake_outlined, Icons.handshake, 'รถร่วม'),
    (NavSection.costs, Icons.attach_money_outlined, Icons.attach_money, 'ต้นทุน'),
    (NavSection.reports, Icons.bar_chart_outlined, Icons.bar_chart, 'รายงาน'),
  ];

  static const Map<NavSection, List<String>> _subMenuLabels = {
    NavSection.vehicles: ['รายการรถ', 'เพิ่มรถ'],
    NavSection.drivers: ['รายการคนขับ', 'เพิ่มคนขับ'],
    NavSection.trips: ['รายการเที่ยว', 'จัดเที่ยว (Drag&Drop)', 'แผนที่เที่ยว'],
    NavSection.maintenance: ['ใบสั่งซ่อม', 'สร้างใบสั่งซ่อม', 'ตารางซ่อม', 'สต๊อกอะไหล่'],
    NavSection.partners: ['รายการรถร่วม', 'ลงทะเบียนรถร่วม', 'จ่ายเงินรถร่วม'],
    NavSection.costs: ['ภาพรวมต้นทุน', 'รายงานน้ำมัน', 'P&L ต่อคัน'],
    NavSection.reports: ['KPI Dashboard', 'Export'],
  };

  Widget _buildContent() {
    switch (_selected) {
      case NavSection.dashboard:
        return const DashboardScreen();
      case NavSection.vehicles:
        return switch (_subIndex) {
          1 => const VehicleFormScreen(),
          _ => const VehicleListScreen(),
        };
      case NavSection.drivers:
        return switch (_subIndex) {
          1 => const DriverFormScreen(),
          _ => const DriverListScreen(),
        };
      case NavSection.trips:
        return switch (_subIndex) {
          1 => const TripPlanningScreen(),
          2 => const TripMapScreen(),
          _ => const TripListScreen(),
        };
      case NavSection.maintenance:
        return switch (_subIndex) {
          1 => const WorkOrderFormScreen(),
          2 => const ScheduleScreen(),
          3 => const PartsInventoryScreen(),
          _ => const WorkOrderListScreen(),
        };
      case NavSection.partners:
        return switch (_subIndex) {
          1 => const PartnerRegisterScreen(),
          2 => const PartnerSettlementScreen(),
          _ => const PartnerListScreen(),
        };
      case NavSection.costs:
        return switch (_subIndex) {
          1 => const FuelReportScreen(),
          2 => const PlPerVehicleScreen(),
          _ => const CostOverviewScreen(),
        };
      case NavSection.reports:
        return switch (_subIndex) {
          1 => const ExportScreen(),
          _ => const KpiDashboardScreen(),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subMenus = _subMenuLabels[_selected];

    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 220,
            color: colorScheme.surfaceContainerLow,
            child: Column(
              children: [
                // Logo / App Header
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: colorScheme.primary,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping, color: colorScheme.onPrimary, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'BC Fleet',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Nav Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _navItems.map((item) {
                      final (section, outlineIcon, filledIcon, label) = item;
                      final isSelected = _selected == section;
                      return InkWell(
                        onTap: () => setState(() {
                          _selected = section;
                          _subIndex = 0;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? filledIcon : outlineIcon,
                                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // User footer
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(Icons.person, size: 18, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('แอดมิน', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                            Text('admin@bcfleet.com', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      // Sub-menu tabs
                      if (subMenus != null)
                        ...subMenus.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: _subIndex == e.key ? colorScheme.primaryContainer : null,
                              foregroundColor: _subIndex == e.key ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => setState(() => _subIndex = e.key),
                            child: Text(e.value, style: const TextStyle(fontSize: 13)),
                          ),
                        )),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                        tooltip: 'แจ้งเตือน',
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {},
                        tooltip: 'ตั้งค่า',
                      ),
                    ],
                  ),
                ),
                // Screen content
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
