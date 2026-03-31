import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/maintenance_bloc.dart';
import '../widgets/approval_dialog.dart';
import 'package:fleet_core/models/maintenance.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<MaintenanceBloc>().add(LoadWorkOrders());
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
        title: const Text('ซ่อมบำรุง'),
        actions: [
          BlocBuilder<MaintenanceBloc, MaintenanceState>(
            builder: (context, state) {
              final count = state is MaintenanceLoaded ? state.pendingCount : 0;
              return Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: IconButton(
                  icon: const Icon(Icons.pending_actions_rounded),
                  onPressed: () => _tabController.animateTo(1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<MaintenanceBloc>().add(RefreshWorkOrders()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ทั้งหมด'),
            Tab(text: 'รออนุมัติ'),
            Tab(text: 'กำลังซ่อม'),
            Tab(text: 'เสร็จแล้ว'),
          ],
          onTap: (i) {
            final filters = ['all', 'pending_approval', 'in_progress', 'completed'];
            context.read<MaintenanceBloc>().add(FilterWorkOrders(status: filters[i]));
          },
        ),
      ),
      body: BlocBuilder<MaintenanceBloc, MaintenanceState>(
        builder: (context, state) {
          if (state is MaintenanceLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MaintenanceLoaded) {
            final orders = state.filtered;
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.build_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('ไม่มีใบสั่งซ่อม', style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<MaintenanceBloc>().add(RefreshWorkOrders()),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder: (context, i) => _WorkOrderCard(
                  workOrder: orders[i],
                  onApprove: () => _handleApprove(context, orders[i]),
                  onReject: () => _handleReject(context, orders[i]),
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('สร้างใบสั่งซ่อม'),
      ),
    );
  }

  void _handleApprove(BuildContext context, WorkOrder wo) {
    ApprovalDialog.show(
      context: context,
      title: 'อนุมัติใบสั่งซ่อม',
      itemLabel: wo.woNo ?? wo.id,
      description: wo.description,
      cost: wo.totalCost != null ? '฿${wo.totalCost!.toStringAsFixed(0)}' : null,
      onApprove: (note) {
        context.read<MaintenanceBloc>().add(ApproveWorkOrder(workOrderId: wo.id, approvedBy: note ?? ''));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อนุมัติใบสั่งซ่อมแล้ว')),
        );
      },
      onReject: (reason) {
        context.read<MaintenanceBloc>().add(RejectWorkOrder(workOrderId: wo.id, reason: reason));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ปฏิเสธใบสั่งซ่อมแล้ว')),
        );
      },
    );
  }

  void _handleReject(BuildContext context, WorkOrder wo) {
    _handleApprove(context, wo); // same dialog, starts in approve mode
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('สร้างใบสั่งซ่อม'),
        content: const Text('ฟีเจอร์นี้กำลังพัฒนา'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
        ],
      ),
    );
  }
}

class _WorkOrderCard extends StatelessWidget {
  final WorkOrder workOrder;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _WorkOrderCard({
    required this.workOrder,
    required this.onApprove,
    required this.onReject,
  });

  Color _priorityColor(String p) {
    switch (p) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber;
      default: return Colors.blue;
    }
  }

  String _priorityLabel(String p) {
    switch (p) {
      case 'critical': return 'ด่วนมาก';
      case 'high': return 'ด่วน';
      case 'medium': return 'ปานกลาง';
      default: return 'ปกติ';
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending_approval': return 'รออนุมัติ';
      case 'approved': return 'อนุมัติแล้ว';
      case 'in_progress': return 'กำลังซ่อม';
      case 'completed': return 'เสร็จแล้ว';
      case 'cancelled': return 'ยกเลิก';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending_approval': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'in_progress': return Colors.indigo;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = workOrder.status == 'pending_approval';

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
                    workOrder.woNo ?? 'WO-${workOrder.id.substring(0, 8).toUpperCase()}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _priorityColor(workOrder.priority ?? 'low').withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _priorityLabel(workOrder.priority ?? 'low'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _priorityColor(workOrder.priority ?? 'low'),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(workOrder.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(workOrder.status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _statusColor(workOrder.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              workOrder.description ?? 'ไม่มีรายละเอียด',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  workOrder.vehicleId,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (workOrder.totalCost != null)
                  Text(
                    '฿${workOrder.totalCost!.toStringAsFixed(0)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: const Text('ปฏิเสธ'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('อนุมัติ'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
