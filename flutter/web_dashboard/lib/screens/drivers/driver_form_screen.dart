import 'package:flutter/material.dart';

class DriverFormScreen extends StatefulWidget {
  final String? driverId;
  const DriverFormScreen({super.key, this.driverId});

  @override
  State<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends State<DriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _employmentType = 'permanent';
  String _licenseType = 'ท.2';
  String _shift = 'เช้า';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.driverId != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isEdit ? 'แก้ไขข้อมูลคนขับ' : 'เพิ่มคนขับใหม่',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton(onPressed: () {}, child: const Text('ยกเลิก')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save, size: 18),
                label: Text(isEdit ? 'บันทึกการแก้ไข' : 'บันทึกคนขับใหม่'),
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
                    _buildSection(context, 'ข้อมูลส่วนตัว', [
                      Row(children: [
                        Expanded(child: _field('ชื่อ-นามสกุล *', hint: 'สมชาย ใจดี', required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('ชื่อเล่น', hint: 'ชาย')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('เบอร์โทรศัพท์ *', hint: '081-234-5678', required: true)),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('เลขบัตรประชาชน', hint: '1-1234-12345-12-1')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('วันเกิด', hint: 'dd/mm/yyyy')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('ที่อยู่', hint: '123 ถ.เชียงใหม่-ลำปาง')),
                      ]),
                    ]),
                    const SizedBox(height: 16),

                    _buildSection(context, 'ใบขับขี่ & เอกสาร', [
                      Row(children: [
                        Expanded(child: _field('เลขใบขับขี่ *', hint: '12345678', required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _dropdown('ประเภทใบขับขี่', _licenseType, ['ท.1', 'ท.2', 'ท.3', 'ท.4'],
                            (v) => setState(() => _licenseType = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _field('วันหมดอายุใบขับขี่', hint: 'dd/mm/yyyy')),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('เลขบัตร DLT', hint: 'DLT-001')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('วันหมดอายุ DLT', hint: 'dd/mm/yyyy')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('ตรวจสุขภาพล่าสุด', hint: 'dd/mm/yyyy')),
                      ]),
                    ]),
                    const SizedBox(height: 16),

                    _buildSection(context, 'ข้อมูลการจ้างงาน', [
                      Row(children: [
                        Expanded(child: _dropdown('ประเภทการจ้างงาน', _employmentType,
                            ['permanent', 'contract', 'daily', 'partner'],
                            (v) => setState(() => _employmentType = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _field('วันเริ่มงาน', hint: 'dd/mm/yyyy')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('เงินเดือนฐาน (บาท)', hint: '15000')),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('เบี้ยเลี้ยงต่อวัน (บาท)', hint: '300')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('โบนัสต่อเที่ยว (บาท)', hint: '200')),
                        const SizedBox(width: 16),
                        Expanded(child: _dropdown('กะงาน', _shift, ['เช้า', 'บ่าย', 'ปกติ'],
                            (v) => setState(() => _shift = v!))),
                      ]),
                    ]),
                    const SizedBox(height: 16),

                    _buildSection(context, 'การมอบหมายรถ', [
                      Row(children: [
                        Expanded(child: _field('รถที่รับผิดชอบ (ทะเบียน)', hint: 'กท-1234')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('พื้นที่ให้บริการ', hint: 'เชียงใหม่, ลำพูน, ลำปาง')),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()),
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

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final cs = Theme.of(context).colorScheme;
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: required ? (v) => v == null || v.isEmpty ? 'กรุณากรอก $label' : null : null,
    );
  }

  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลคนขับเรียบร้อย')),
      );
    }
  }
}
