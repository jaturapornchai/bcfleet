import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/partner_bloc.dart';
import 'package:fleet_core/models/partner_vehicle.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PartnerBloc>().add(LoadPartners());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รถร่วม'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showFindAvailable(context),
            tooltip: 'ค้นหารถว่าง',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<PartnerBloc>().add(RefreshPartners()),
          ),
        ],
      ),
      body: BlocBuilder<PartnerBloc, PartnerState>(
        builder: (context, state) {
          if (state is PartnerLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PartnerLoaded) {
            if (state.partners.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.handshake_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('ยังไม่มีรถร่วม', style: TextStyle(color: Colors.grey[500])),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _showRegisterDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('ลงทะเบียนรถร่วม'),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<PartnerBloc>().add(RefreshPartners()),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: state.partners.length,
                itemBuilder: (context, i) => _PartnerCard(partner: state.partners[i]),
              ),
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('ลงทะเบียนรถร่วม'),
      ),
    );
  }

  void _showFindAvailable(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ค้นหารถร่วมว่าง',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'ประเภทรถ',
                hintText: 'เช่น 6ล้อ, 10ล้อ',
                prefixIcon: Icon(Icons.local_shipping_outlined),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'พื้นที่',
                hintText: 'เช่น เชียงใหม่-ลำพูน',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<PartnerBloc>().add(FindAvailablePartners(
                    vehicleType: '6ล้อ',
                    zone: 'เชียงใหม่',
                    date: DateTime.now(),
                  ));
                },
                child: const Text('ค้นหา'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegisterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลงทะเบียนรถร่วม'),
        content: const Text('ฟีเจอร์นี้กำลังพัฒนา\nจะเชื่อมกับ API จริงในเร็วๆ นี้'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final PartnerVehicle partner;
  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.plate ?? '-',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${partner.vehicleType} · ${partner.ownerName ?? '-'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Star rating
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Colors.amber[600]),
                    const SizedBox(width: 2),
                    Text(
                      partner.rating?.toStringAsFixed(1) ?? '-',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.route_rounded,
                  label: '${partner.totalTrips} เที่ยว',
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.place_outlined,
                  label: partner.vehicleType ?? 'ไม่ระบุ',
                ),
                const Spacer(),
                if (partner.baseRate != null)
                  Text(
                    '฿${partner.baseRate!.toStringAsFixed(0)}/เที่ยว',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
