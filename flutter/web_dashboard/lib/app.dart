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

class SMLFleetWebApp extends StatelessWidget {
  const SMLFleetWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SML Fleet Dashboard',
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

  void _selectSection(NavSection section) {
    setState(() {
      _selected = section;
      _subIndex = 0;
    });
  }

  /// Drawer content — used for mobile
  Widget _buildDrawer(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: cs.primary,
            alignment: Alignment.centerLeft,
            child: SafeArea(
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: cs.onPrimary, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'SML Fleet',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _navItems.map((item) {
                final (section, outlineIcon, filledIcon, label) = item;
                final isSelected = _selected == section;
                return ListTile(
                  leading: Icon(
                    isSelected ? filledIcon : outlineIcon,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? cs.primary : cs.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: cs.primaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  onTap: () {
                    _selectSection(section);
                    Navigator.of(context).pop(); // close drawer
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.person, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('แอดมิน', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                      Text('admin@smlfleet.com', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sidebar — used for tablet & desktop
  Widget _buildSidebar(BuildContext context, {required bool extended}) {
    final cs = Theme.of(context).colorScheme;
    final width = extended ? 220.0 : 72.0;

    return Container(
      width: width,
      color: cs.surfaceContainerLow,
      child: Column(
        children: [
          // Logo
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 0),
            color: cs.primary,
            alignment: extended ? Alignment.centerLeft : Alignment.center,
            child: extended
                ? Row(
                    children: [
                      Icon(Icons.local_shipping, color: cs.onPrimary, size: 26),
                      const SizedBox(width: 10),
                      Text('SML Fleet', style: TextStyle(color: cs.onPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  )
                : Icon(Icons.local_shipping, color: cs.onPrimary, size: 26),
          ),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _navItems.map((item) {
                final (section, outlineIcon, filledIcon, label) = item;
                final isSelected = _selected == section;
                if (extended) {
                  return InkWell(
                    onTap: () => _selectSection(section),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? cs.primaryContainer : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? filledIcon : outlineIcon,
                            color: isSelected ? cs.primary : cs.onSurfaceVariant,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? cs.primary : cs.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // collapsed — icons only with tooltip
                  return Tooltip(
                    message: label,
                    preferBelow: false,
                    child: InkWell(
                      onTap: () => _selectSection(section),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? cs.primaryContainer : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            isSelected ? filledIcon : outlineIcon,
                            color: isSelected ? cs.primary : cs.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }).toList(),
            ),
          ),
          // User footer
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(extended ? 12 : 8),
            child: extended
                ? Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.person, size: 16, color: cs.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('แอดมิน', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
                            Text('admin@smlfleet.com', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  )
                : Tooltip(
                    message: 'แอดมิน',
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(Icons.person, size: 16, color: cs.primary),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Sub-menu tabs bar
  Widget _buildSubMenuBar(BuildContext context, List<String> subMenus) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: subMenus.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: _subIndex == e.key ? cs.primaryContainer : null,
                foregroundColor: _subIndex == e.key ? cs.primary : cs.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => _subIndex = e.key),
              child: Text(e.value, style: const TextStyle(fontSize: 13)),
            ),
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final subMenus = _subMenuLabels[_selected];

    // --------- MOBILE layout ---------
    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          titleSpacing: 0,
          title: Row(
            children: [
              const Icon(Icons.local_shipping, size: 22),
              const SizedBox(width: 8),
              const Text('SML Fleet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: cs.onPrimary),
              onPressed: () {},
              tooltip: 'แจ้งเตือน',
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: Column(
          children: [
            // Sub-menu tabs (scrollable horizontal)
            if (subMenus != null) _buildSubMenuBar(context, subMenus),
            Expanded(child: _buildContent()),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: NavSection.values.indexOf(_selected),
          onDestinationSelected: (i) => _selectSection(NavSection.values[i]),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: _navItems.map((item) {
            final (_, outlineIcon, filledIcon, label) = item;
            return NavigationDestination(
              icon: Icon(outlineIcon),
              selectedIcon: Icon(filledIcon),
              label: label,
            );
          }).toList(),
        ),
      );
    }

    // --------- TABLET / DESKTOP layout ---------
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context, extended: !isTablet),
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      if (subMenus != null)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: subMenus.asMap().entries.map((e) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: _subIndex == e.key ? cs.primaryContainer : null,
                                    foregroundColor: _subIndex == e.key ? cs.primary : cs.onSurfaceVariant,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => setState(() => _subIndex = e.key),
                                  child: Text(e.value, style: const TextStyle(fontSize: 13)),
                                ),
                              )).toList(),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (subMenus == null) const Spacer(),
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
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
