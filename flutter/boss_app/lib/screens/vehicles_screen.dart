import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/vehicle_bloc.dart';
import 'package:fleet_core/models/vehicle.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  String _selectedFilter = 'all';

  final _filters = [
    ('all', 'ทั้งหมด'),
    ('active', 'ใช้งาน'),
    ('maintenance', 'ซ่อม'),
    ('inactive', 'ไม่ใช้'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<VehicleBloc>().add(LoadVehicles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการรถ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<VehicleBloc>().add(RefreshVehicles()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _filters.map((f) {
                final isSelected = _selectedFilter == f.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.$2),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = f.$1);
                      context.read<VehicleBloc>().add(FilterVehicles(status: f.$1));
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: BlocBuilder<VehicleBloc, VehicleState>(
              builder: (context, state) {
                if (state is VehicleLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is VehicleLoaded) {
                  final vehicles = state.filtered;
                  if (vehicles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text('ไม่มีรถ', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => context.read<VehicleBloc>().add(RefreshVehicles()),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: vehicles.length,
                      itemBuilder: (context, i) => _VehicleCard(vehicle: vehicles[i]),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรถ'),
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เพิ่มรถใหม่'),
        content: const Text('ฟีเจอร์นี้กำลังพัฒนา\nจะเชื่อมกับ API จริงในเร็วๆ นี้'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  Color _healthColor(String h) {
    switch (h) {
      case 'green': return Colors.green;
      case 'yellow': return Colors.orange;
      case 'red': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _healthLabel(String h) {
    switch (h) {
      case 'green': return 'ปกติ';
      case 'yellow': return 'เฝ้าระวัง';
      case 'red': return 'วิกฤต';
      default: return 'ไม่ทราบ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final healthColor = _healthColor(vehicle.healthStatus);
    final isInMaintenance = vehicle.status == 'maintenance';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isInMaintenance ? Colors.grey : healthColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isInMaintenance ? 'ซ่อม' : _healthLabel(vehicle.healthStatus),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isInMaintenance ? Colors.grey : healthColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                vehicle.plate,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                vehicle.type,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (vehicle.brand != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${vehicle.brand}${vehicle.model != null ? ' ${vehicle.model}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    vehicle.ownership == 'own' ? 'รถตัวเอง' : 'รถร่วม',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
