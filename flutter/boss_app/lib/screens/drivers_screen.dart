import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app.dart' show Responsive;
import '../bloc/vehicle_bloc.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('คนขับรถ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<VehicleBloc>().add(RefreshVehicles()),
          ),
        ],
      ),
      body: _DriverListBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDriverDialog(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('เพิ่มคนขับ'),
      ),
    );
  }

  void _showAddDriverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เพิ่มคนขับใหม่'),
        content: const Text('ฟีเจอร์นี้กำลังพัฒนา'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
        ],
      ),
    );
  }
}

class _DriverListBody extends StatelessWidget {
  // Mock drivers since DriverBloc not yet separate
  final List<_DriverData> _mockDrivers = const [
    _DriverData(
      name: 'สมชาย ใจดี',
      nickname: 'ชาย',
      phone: '081-234-5678',
      licenseType: 'ท.2',
      assignedVehicle: 'กท-1234',
      vehicleType: '6ล้อ',
      status: 'active',
      score: 92,
      totalTrips: 450,
      onTimeRate: 0.95,
    ),
    _DriverData(
      name: 'วิชัย ขับดี',
      nickname: 'วิ',
      phone: '089-345-6789',
      licenseType: 'ท.2',
      assignedVehicle: 'ชม-5678',
      vehicleType: '10ล้อ',
      status: 'active',
      score: 85,
      totalTrips: 320,
      onTimeRate: 0.88,
    ),
    _DriverData(
      name: 'สมหมาย รอดงาน',
      nickname: 'หมาย',
      phone: '082-456-7890',
      licenseType: 'ท.1',
      assignedVehicle: null,
      vehicleType: '4ล้อ',
      status: 'on_leave',
      score: 78,
      totalTrips: 210,
      onTimeRate: 0.82,
    ),
    _DriverData(
      name: 'ประสิทธิ์ มากน้ำ',
      nickname: 'สิทธิ์',
      phone: '083-567-8901',
      licenseType: 'ท.2',
      assignedVehicle: 'พย-3456',
      vehicleType: '6ล้อ',
      status: 'active',
      score: 95,
      totalTrips: 580,
      onTimeRate: 0.98,
    ),
  ];

  const _DriverListBody();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(Responsive.padding(context)),
      itemCount: _mockDrivers.length,
      itemBuilder: (context, i) => _DriverCard(driver: _mockDrivers[i]),
    );
  }
}

class _DriverData {
  final String name;
  final String nickname;
  final String phone;
  final String licenseType;
  final String? assignedVehicle;
  final String vehicleType;
  final String status;
  final int score;
  final int totalTrips;
  final double onTimeRate;

  const _DriverData({
    required this.name,
    required this.nickname,
    required this.phone,
    required this.licenseType,
    this.assignedVehicle,
    required this.vehicleType,
    required this.status,
    required this.score,
    required this.totalTrips,
    required this.onTimeRate,
  });
}

class _DriverCard extends StatelessWidget {
  final _DriverData driver;
  const _DriverCard({required this.driver});

  Color _scoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.orange;
    return Colors.red;
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'active': return 'ปฏิบัติงาน';
      case 'on_leave': return 'ลา';
      case 'suspended': return 'พักงาน';
      case 'resigned': return 'ลาออก';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'active': return Colors.green;
      case 'on_leave': return Colors.orange;
      case 'suspended': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _scoreColor(driver.score);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    driver.nickname.substring(0, 1),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            driver.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(driver.status).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusLabel(driver.status),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _statusColor(driver.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ใบขับขี่ ${driver.licenseType} · ${driver.vehicleType}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (driver.assignedVehicle != null)
                        Text(
                          'รถ: ${driver.assignedVehicle}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),

                // Score circle
                Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: scoreColor, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${driver.score}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('คะแนน', style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // KPI row — ใช้ LayoutBuilder เพื่อป้องกัน overflow บน mobile
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 16) / 3;
                return Row(
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _KpiItem(
                        label: 'เที่ยวรวม',
                        value: '${driver.totalTrips}',
                        icon: Icons.route_rounded,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _KpiItem(
                        label: 'ตรงเวลา',
                        value: '${(driver.onTimeRate * 100).toStringAsFixed(0)}%',
                        icon: Icons.access_time_rounded,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _KpiItem(
                        label: 'โทรศัพท์',
                        value: driver.phone,
                        icon: Icons.phone_rounded,
                        overflow: true,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool overflow;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    this.overflow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: overflow ? TextOverflow.ellipsis : TextOverflow.clip,
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          maxLines: 1,
        ),
      ],
    );
  }
}
