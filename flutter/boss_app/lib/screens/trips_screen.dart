import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/trip_bloc.dart';
import 'package:fleet_core/models/trip.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const ['ทั้งหมด', 'วันนี้', 'รอดำเนินการ', 'เสร็จแล้ว'];
  final _filters = ['all', 'today', 'pending', 'completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<TripBloc>().add(FilterTrips(status: _filters[_tabController.index]));
      }
    });
    context.read<TripBloc>().add(LoadTrips());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เที่ยววิ่ง'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<TripBloc>().add(RefreshTrips()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
        ),
      ),
      body: BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          if (state is TripLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TripLoaded) {
            final trips = state.filtered;
            if (trips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.route_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('ไม่มีเที่ยววิ่ง', style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<TripBloc>().add(RefreshTrips()),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: trips.length,
                itemBuilder: (context, i) => _TripCard(trip: trips[i]),
              ),
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTripDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('สร้างเที่ยววิ่ง'),
      ),
    );
  }

  void _showCreateTripDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('สร้างเที่ยววิ่งใหม่'),
        content: const Text('ฟีเจอร์นี้กำลังพัฒนา\nจะเชื่อมกับ API จริงในเร็วๆ นี้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  Color _statusColor(String s) {
    switch (s) {
      case 'completed': return Colors.green;
      case 'in_progress':
      case 'started':
      case 'delivering': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'completed': return 'เสร็จแล้ว';
      case 'in_progress': return 'กำลังวิ่ง';
      case 'started': return 'เริ่มแล้ว';
      case 'delivering': return 'กำลังส่ง';
      case 'pending': return 'รอดำเนินการ';
      case 'accepted': return 'รับงานแล้ว';
      case 'cancelled': return 'ยกเลิก';
      default: return s;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'completed': return Icons.check_circle_rounded;
      case 'in_progress':
      case 'started':
      case 'delivering': return Icons.local_shipping_rounded;
      case 'pending': return Icons.schedule_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(trip.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip.tripNo ?? 'TRIP-${trip.id.substring(0, 8).toUpperCase()}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(trip.status), size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel(trip.status),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Origin → Destination
            Row(
              children: [
                Column(
                  children: [
                    Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
                    Container(width: 1, height: 20, color: theme.colorScheme.outlineVariant),
                    Icon(Icons.location_on_rounded, size: 14, color: theme.colorScheme.error),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.originName ?? 'ต้นทาง',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${trip.destinationCount} จุดส่ง${trip.cargoDescription != null ? ' · ${trip.cargoDescription}' : ''}',
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Bottom info row
            Row(
              children: [
                if (trip.driverId != null) ...[
                  Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(trip.driverId!, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                ],
                if (trip.vehicleId != null) ...[
                  Icon(Icons.local_shipping_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(trip.vehicleId!, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                ],
                const Spacer(),
                if (trip.revenue != null)
                  Text(
                    '฿${trip.revenue!.toStringAsFixed(0)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
