import 'package:flutter/material.dart';

class ApprovalDialog extends StatefulWidget {
  final String title;
  final String itemLabel;
  final String? description;
  final String? cost;
  final Function(String? note) onApprove;
  final Function(String reason) onReject;

  const ApprovalDialog({
    super.key,
    required this.title,
    required this.itemLabel,
    this.description,
    this.cost,
    required this.onApprove,
    required this.onReject,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String itemLabel,
    String? description,
    String? cost,
    required Function(String? note) onApprove,
    required Function(String reason) onReject,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ApprovalDialog(
        title: title,
        itemLabel: itemLabel,
        description: description,
        cost: cost,
        onApprove: onApprove,
        onReject: onReject,
      ),
    );
  }

  @override
  State<ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<ApprovalDialog> {
  final _noteController = TextEditingController();
  final _rejectController = TextEditingController();
  bool _showRejectField = false;

  @override
  void dispose() {
    _noteController.dispose();
    _rejectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.itemLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.description != null) ...[
                    const SizedBox(height: 4),
                    Text(widget.description!, style: theme.textTheme.bodySmall),
                  ],
                  if (widget.cost != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'ค่าใช้จ่าย: ${widget.cost}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Note field (approve)
            if (!_showRejectField) ...[
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'หมายเหตุ (ถ้ามี)',
                  hintText: 'เพิ่มหมายเหตุสำหรับการอนุมัติ...',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
            ],

            // Reject reason field
            if (_showRejectField) ...[
              Text(
                'ระบุเหตุผลการปฏิเสธ',
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _rejectController,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'เหตุผลที่ปฏิเสธ...',
                  prefixIcon: const Icon(Icons.cancel_outlined),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.error),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: _showRejectField
          ? [
              TextButton(
                onPressed: () => setState(() => _showRejectField = false),
                child: const Text('ย้อนกลับ'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () {
                  final reason = _rejectController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('กรุณาระบุเหตุผล')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  widget.onReject(reason);
                },
                child: const Text('ยืนยันปฏิเสธ'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => setState(() => _showRejectField = true),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('ปฏิเสธ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApprove(_noteController.text.trim().isEmpty ? null : _noteController.text.trim());
                },
                child: const Text('อนุมัติ'),
              ),
            ],
    );
  }
}
