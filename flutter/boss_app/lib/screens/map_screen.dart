import 'package:flutter/material.dart';
import 'package:fleet_core/models/vehicle.dart';
import '../bloc/vehicle_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/vehicle_map_marker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    context.read<VehicleBloc>().add(LoadVehicles());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่รถ Real-time'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<VehicleBloc>().add(RefreshVehicles()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map placeholder
          Expanded(
            flex: 3,
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Stack(
                children: [
                  // Map background
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text(
                          'Longdo Map API v3',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mock vehicle markers on map
                  BlocBuilder<VehicleBloc, VehicleState>(
                    builder: (context, state) {
                      if (state is! VehicleLoaded) return const SizedBox();
                      return Stack(
                        children: [
                          Positioned(top: 60, left: 80,
                            child: VehicleMapMarker(
                              vehicle: state.vehicles.isNotEmpty ? state.vehicles[0] : _dummyVehicle(),
                              isSelected: _selectedVehicleId == 'v1',
                              onTap: () => setState(() => _selectedVehicleId = 'v1'),
                            ),
                          ),
                          Positioned(top: 140, right: 100,
                            child: VehicleMapMarker(
                              vehicle: state.vehicles.length > 1 ? state.vehicles[1] : _dummyVehicle(),
                              isSelected: _selectedVehicleId == 'v2',
                              onTap: () => setState(() => _selectedVehicleId = 'v2'),
                            ),
                          ),
                          Positioned(bottom: 80, left: 140,
                            child: VehicleMapMarker(
                              vehicle: state.vehicles.length > 2 ? state.vehicles[2] : _dummyVehicle(),
                              isSelected: _selectedVehicleId == 'v3',
                              onTap: () => setState(() => _selectedVehicleId = 'v3'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Zoom controls
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'zoom_in',
                          onPressed: () {},
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'zoom_out',
                          onPressed: () {},
                          child: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vehicle list panel
          Expanded(
            flex: 2,
            child: BlocBuilder<VehicleBloc, VehicleState>(
              builder: (context, state) {
                if (state is VehicleLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is VehicleLoaded) {
                  return _VehicleListPanel(
                    vehicles: state.vehicles,
                    selectedId: _selectedVehicleId,
                    onSelect: (id) => setState(() => _selectedVehicleId = id),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Vehicle _dummyVehicle() {
    final now = DateTime.now();
    return Vehicle(
      id: 'dummy', shopId: 's1', plate: '---', type: '6ล้อ',
      ownership: 'own', status: 'active', healthStatus: 'green',
      createdAt: now, updatedAt: now,
    );
  }
}

class _VehicleListPanel extends StatelessWidget {
  final List<Vehicle> vehicles;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _VehicleListPanel({
    required this.vehicles,
    required this.selectedId,
    required this.onSelect,
  });

  Color _healthColor(String h) {
    switch (h) {
      case 'green': return Colors.green;
      case 'yellow': return Colors.orange;
      case 'red': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('รถทั้งหมด ${vehicles.length} คัน',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: vehicles.length,
            itemBuilder: (context, i) {
              final v = vehicles[i];
              final isSelected = v.id == selectedId;
              return GestureDetector(
                onTap: () => onSelect(v.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: _healthColor(v.healthStatus),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(v.plate,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(v.type, style: theme.textTheme.bodySmall),
                      if (v.brand != null)
                        Text(v.brand!, style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
