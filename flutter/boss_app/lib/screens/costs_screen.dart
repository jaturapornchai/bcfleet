import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/cost_chart.dart';

class CostsScreen extends StatelessWidget {
  const CostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ต้นทุนขนส่ง'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {},
            tooltip: 'Export',
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardLoaded) {
            return _CostsContent(state: state);
          }
          return const Center(child: Text('ไม่มีข้อมูล'));
        },
      ),
    );
  }
}

class _CostsContent extends StatelessWidget {
  final DashboardLoaded state;
  const _CostsContent({required this.state});

  String _formatCurrency(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = state.todayTrips;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(child: _SummaryCard(
              label: 'รายได้วันนี้',
              value: '฿${_formatCurrency(t.totalRevenue)}',
              icon: Icons.payments_rounded,
              color: Colors.green,
            )),
            const SizedBox(width: 8),
            Expanded(child: _SummaryCard(
              label: 'ต้นทุนวันนี้',
              value: '฿${_formatCurrency(t.totalCost)}',
              icon: Icons.receipt_long_rounded,
              color: Colors.red,
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _SummaryCard(
              label: 'กำไรวันนี้',
              value: '฿${_formatCurrency(t.totalProfit)}',
              icon: Icons.trending_up_rounded,
              color: Colors.indigo,
            )),
            const SizedBox(width: 8),
            Expanded(child: _SummaryCard(
              label: 'อัตรากำไร',
              value: t.totalRevenue > 0
                  ? '${(t.totalProfit / t.totalRevenue * 100).toStringAsFixed(1)}%'
                  : '0%',
              icon: Icons.percent_rounded,
              color: Colors.teal,
            )),
          ],
        ),
        const SizedBox(height: 16),

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
                    Text('รายได้ vs ต้นทุน 7 วัน',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const CostChartLegend(),
                  ],
                ),
                const SizedBox(height: 16),
                CostChart(data: state.kpi.weeklyRevenue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cost breakdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ประเภทต้นทุน (เดือนนี้)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _CostBreakdownItem(label: 'น้ำมันเชื้อเพลิง', amount: 45200, percent: 0.42, color: Colors.orange),
                _CostBreakdownItem(label: 'ซ่อมบำรุง', amount: 18500, percent: 0.17, color: Colors.red),
                _CostBreakdownItem(label: 'เบี้ยเลี้ยงคนขับ', amount: 22000, percent: 0.20, color: Colors.blue),
                _CostBreakdownItem(label: 'ทางด่วน/จอดรถ', amount: 8400, percent: 0.08, color: Colors.purple),
                _CostBreakdownItem(label: 'รถร่วม', amount: 14200, percent: 0.13, color: Colors.teal),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Fuel report summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('สรุปน้ำมันเดือนนี้',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FuelStatItem(
                        label: 'ปริมาณรวม',
                        value: '1,240 ลิตร',
                        icon: Icons.local_gas_station_rounded,
                      ),
                    ),
                    Expanded(
                      child: _FuelStatItem(
                        label: 'ค่าเฉลี่ย',
                        value: '฿28.5/ลิตร',
                        icon: Icons.attach_money_rounded,
                      ),
                    ),
                    Expanded(
                      child: _FuelStatItem(
                        label: 'ประสิทธิภาพ',
                        value: '5.2 km/L',
                        icon: Icons.speed_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _CostBreakdownItem extends StatelessWidget {
  final String label;
  final double amount;
  final double percent;
  final Color color;

  const _CostBreakdownItem({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
              Text('฿${amount.toStringAsFixed(0)}',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _FuelStatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
