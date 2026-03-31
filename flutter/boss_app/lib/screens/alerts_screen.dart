import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alert_bloc.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AlertBloc>().add(LoadAlerts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แจ้งเตือน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AlertBloc>().add(RefreshAlerts()),
          ),
        ],
      ),
      body: BlocBuilder<AlertBloc, AlertState>(
        builder: (context, state) {
          if (state is AlertLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AlertLoaded) {
            final alerts = state.alerts;
            if (alerts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('ไม่มีแจ้งเตือน', style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              );
            }

            // Group by status: active first, then acknowledged
            final active = state.active;
            final acknowledged = alerts.where((a) => a.status == 'acknowledged').toList();

            return RefreshIndicator(
              onRefresh: () async => context.read<AlertBloc>().add(RefreshAlerts()),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (active.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'ต้องดำเนินการ (${active.length})',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ...active.map((a) => _AlertCard(
                      alert: a,
                      onAcknowledge: () =>
                          context.read<AlertBloc>().add(AcknowledgeAlert(alertId: a.id, acknowledgedBy: 'admin')),
                    )),
                  ],
                  if (acknowledged.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        'รับทราบแล้ว (${acknowledged.length})',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ...acknowledged.map((a) => _AlertCard(alert: a, onAcknowledge: null)),
                  ],
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final FleetAlert alert;
  final VoidCallback? onAcknowledge;

  const _AlertCard({required this.alert, required this.onAcknowledge});

  Color _severityColor(String s) {
    switch (s) {
      case 'critical': return Colors.red;
      case 'warning': return Colors.orange;
      default: return Colors.blue;
    }
  }

  IconData _severityIcon(String s) {
    switch (s) {
      case 'critical': return Icons.error_rounded;
      case 'warning': return Icons.warning_rounded;
      default: return Icons.info_rounded;
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'insurance_expiry': return 'ประกันภัย';
      case 'tax_due': return 'ภาษีรถ';
      case 'act_due': return 'พ.ร.บ.';
      case 'license_expiry': return 'ใบขับขี่';
      case 'maintenance_due': return 'ซ่อมบำรุง';
      case 'geofence_alert': return 'Geofence';
      case 'speeding': return 'ขับเร็วเกิน';
      default: return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _severityColor(alert.severity);
    final isAcknowledged = alert.status == 'acknowledged';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: isAcknowledged ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_severityIcon(alert.severity), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _typeLabel(alert.type),
                            style: theme.textTheme.labelSmall?.copyWith(color: color),
                          ),
                        ),
                        if (alert.daysRemaining != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            'เหลือ ${alert.daysRemaining} วัน',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.title,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (onAcknowledge != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: onAcknowledge,
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('รับทราบ'),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
