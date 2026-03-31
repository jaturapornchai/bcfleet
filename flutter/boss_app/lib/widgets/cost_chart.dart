import 'package:flutter/material.dart';
import '../bloc/dashboard_bloc.dart';

class CostChart extends StatelessWidget {
  final List<WeeklyRevenue> data;
  final double height;

  const CostChart({
    super.key,
    required this.data,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = data.fold<double>(
      0,
      (prev, e) => e.revenue > prev ? e.revenue : prev,
    );

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) => _Bar(
          item: item,
          maxValue: maxValue == 0 ? 1 : maxValue,
          revenueColor: theme.colorScheme.primary,
          costColor: theme.colorScheme.error.withValues(alpha: 0.7),
        )).toList(),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final WeeklyRevenue item;
  final double maxValue;
  final Color revenueColor;
  final Color costColor;

  const _Bar({
    required this.item,
    required this.maxValue,
    required this.revenueColor,
    required this.costColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final revenueH = (item.revenue / maxValue) * 130;
    final costH = (item.cost / maxValue) * 130;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Revenue bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              height: revenueH,
              decoration: BoxDecoration(
                color: revenueColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            // Cost bar (stacked below as overlay effect — shown separately)
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              height: costH,
              decoration: BoxDecoration(
                color: costColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.day,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CostChartLegend extends StatelessWidget {
  const CostChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _LegendDot(color: theme.colorScheme.primary, label: 'รายได้'),
        const SizedBox(width: 16),
        _LegendDot(color: theme.colorScheme.error.withValues(alpha: 0.7), label: 'ต้นทุน'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
