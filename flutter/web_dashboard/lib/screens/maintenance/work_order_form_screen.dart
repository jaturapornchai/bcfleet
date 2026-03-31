import 'package:flutter/material.dart';

class WorkOrderFormScreen extends StatefulWidget {
  final String? workOrderId;
  const WorkOrderFormScreen({super.key, this.workOrderId});

  @override
  State<WorkOrderFormScreen> createState() => _WorkOrderFormScreenState();
}

class _WorkOrderFormScreenState extends State<WorkOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'preventive';
  String _priority = 'medium';
  String _providerType = 'internal';

  final _parts = <Map<String, String>>[
    {'name': 'น้ำมันเครื่อง SHELL 15W-40', 'qty': '8', 'unit': 'ลิตร', 'price': '280', 'total': '2,240'},
    {'name': 'กรองน้ำมันเครื่อง', 'qty': '1', 'unit': 'ชิ้น', 'price': '350', 'total': '350'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.workOrderId != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isEdit ? 'แก้ไขใบสั่งซ่อม' : 'สร้างใบสั่งซ่อม',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton(onPressed: () {}, child: const Text('ยกเลิก')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save, size: 18),
                label: Text(isEdit ? 'บันทึกการแก้ไข' : 'สร้างใบสั่งซ่อม'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Section 1: ข้อมูลทั่วไป
                    _buildSection(cs, 'ข้อมูลทั่วไป', [
                      Row(children: [
                        Expanded(child: _field('รถที่ต้องซ่อม (ทะเบียน) *', hint: 'กท-1234', required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _dropdown('ประเภทการซ่อม *', _type,
                            ['preventive', 'corrective', 'emergency'],
                            ['ซ่อมบำรุงตามกำหนด', 'ซ่อมแก้ไข', 'ฉุกเฉิน'],
                            (v) => setState(() => _type = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _dropdown('ความเร่งด่วน', _priority,
                            ['low', 'medium', 'high', 'critical'],
                            ['ต่ำ', 'ปานกลาง', 'สูง', 'วิกฤต'],
                            (v) => setState(() => _priority = v!))),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('เลขไมล์ปัจจุบัน', hint: '85,000')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('วันที่แจ้ง', hint: 'dd/mm/yyyy')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('กำหนดเสร็จ', hint: 'dd/mm/yyyy')),
                      ]),
                      const SizedBox(height: 16),
                      TextFormField(
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'รายละเอียดการซ่อม *',
                          hintText: 'อธิบายอาการ หรือรายการซ่อมที่ต้องการ...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Section 2: อู่/ช่าง
                    _buildSection(cs, 'อู่ / ช่าง', [
                      Row(children: [
                        Expanded(child: _dropdown('ประเภทผู้ให้บริการ', _providerType,
                            ['internal', 'external'],
                            ['ช่างใน (อู่ใน)', 'อู่ภายนอก'],
                            (v) => setState(() => _providerType = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _field('ชื่ออู่ / ช่าง', hint: 'ช่างสมศักดิ์')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('เบอร์โทรติดต่อ', hint: '089-345-6789')),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('ค่าแรง (บาท)', hint: '1,000')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('จำนวนชั่วโมง', hint: '2')),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()),
                      ]),
                    ]),
                    const SizedBox(height: 16),

                    // Section 3: รายการอะไหล่
                    _buildSection(cs, 'รายการอะไหล่', [
                      DataTable(
                        headingRowColor: WidgetStateProperty.all(cs.surfaceContainerLow),
                        columns: const [
                          DataColumn(label: Text('ชื่ออะไหล่')),
                          DataColumn(label: Text('จำนวน'), numeric: true),
                          DataColumn(label: Text('หน่วย')),
                          DataColumn(label: Text('ราคา/หน่วย'), numeric: true),
                          DataColumn(label: Text('รวม'), numeric: true),
                          DataColumn(label: Text('ลบ')),
                        ],
                        rows: _parts.map((p) => DataRow(cells: [
                          DataCell(Text(p['name']!)),
                          DataCell(Text(p['qty']!)),
                          DataCell(Text(p['unit']!)),
                          DataCell(Text('฿${p['price']!}')),
                          DataCell(Text('฿${p['total']!}', style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            onPressed: () => setState(() => _parts.remove(p)),
                          )),
                        ])).toList(),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _addPart,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('เพิ่มอะไหล่'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('ค่าอะไหล่รวม: ', style: TextStyle(color: cs.onSurfaceVariant)),
                          Text('฿3,040', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 16)),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Section 4: รูปถ่าย
                    _buildSection(cs, 'รูปถ่าย', [
                      Row(children: [
                        Expanded(child: _photoBox(cs, 'ก่อนซ่อม')),
                        const SizedBox(width: 16),
                        Expanded(child: _photoBox(cs, 'หลังซ่อม')),
                      ]),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ColorScheme cs, String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cs.primary)),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field(String label, {String? hint, bool required = false}) {
    return TextFormField(
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder(), isDense: true),
      validator: required ? (v) => v == null || v.isEmpty ? 'กรุณากรอก $label' : null : null,
    );
  }

  Widget _dropdown(String label, String value, List<String> values, List<String> labels, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      items: List.generate(values.length, (i) => DropdownMenuItem(value: values[i], child: Text(labels[i]))),
      onChanged: onChanged,
    );
  }

  Widget _photoBox(ColorScheme cs, String label) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        color: cs.surfaceContainerLowest,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 32, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          Text('คลิกเพื่ออัปโหลด', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  void _addPart() {
    setState(() {
      _parts.add({'name': 'อะไหล่ใหม่', 'qty': '1', 'unit': 'ชิ้น', 'price': '0', 'total': '0'});
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกใบสั่งซ่อมเรียบร้อย')),
      );
    }
  }
}
