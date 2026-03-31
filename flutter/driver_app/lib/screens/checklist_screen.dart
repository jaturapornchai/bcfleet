import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/checklist_bloc.dart';

class ChecklistScreen extends StatefulWidget {
  final String tripId;

  const ChecklistScreen({super.key, required this.tripId});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChecklistBloc>().add(LoadChecklist());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist ก่อนออก')),
      body: BlocConsumer<ChecklistBloc, ChecklistState>(
        listener: (context, state) {
          if (state is ChecklistSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('บันทึก Checklist สำเร็จ'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          }
          if (state is ChecklistError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ChecklistLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! ChecklistLoaded) return const SizedBox.shrink();

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _ChecklistItemCard(
                      item: item,
                      onStatusChanged: (status) {
                        context.read<ChecklistBloc>().add(
                              UpdateChecklistItem(
                                itemName: item['name'] as String,
                                status: status,
                              ),
                            );
                      },
                      onPhotoTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('เปิดกล้องถ่ายรูป (placeholder)')),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<ChecklistBloc>().add(
                              SubmitChecklist(tripId: widget.tripId),
                            );
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('ยืนยัน Checklist'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChecklistItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onPhotoTap;

  const _ChecklistItemCard({
    required this.item,
    required this.onStatusChanged,
    required this.onPhotoTap,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'ok':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'fail':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = item['name'] as String;
    final status = item['status'] as String? ?? 'ok';
    final hasPhoto = item['photo'] != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _statusColor(status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 88,
              child: DropdownButton<String>(
                value: status,
                underline: const SizedBox.shrink(),
                isDense: true,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'ok', child: Text('ปกติ')),
                  DropdownMenuItem(
                      value: 'warning', child: Text('ต้องระวัง')),
                  DropdownMenuItem(
                      value: 'fail', child: Text('ผิดปกติ')),
                ],
                onChanged: (val) {
                  if (val != null) onStatusChanged(val);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                hasPhoto ? Icons.photo : Icons.camera_alt_outlined,
                color: hasPhoto ? Colors.green : Colors.grey,
                size: 20,
              ),
              onPressed: onPhotoTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
