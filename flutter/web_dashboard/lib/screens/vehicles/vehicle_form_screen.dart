import 'package:flutter/material.dart';

class VehicleFormScreen extends StatefulWidget {
  final String? vehicleId;
  const VehicleFormScreen({super.key, this.vehicleId});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = '6ล้อ';
  String _fuelType = 'ดีเซล';
  String _ownership = 'own';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicleId != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isEdit ? 'แก้ไขข้อมูลรถ' : 'เพิ่มรถใหม่',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton(onPressed: () {}, child: const Text('ยกเลิก')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save, size: 18),
                label: Text(isEdit ? 'บันทึกการแก้ไข' : 'บันทึกรถใหม่'),
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
                    // Section 1: ข้อมูลพื้นฐาน
                    _buildSection(context, 'ข้อมูลพื้นฐาน', [
                      Row(children: [
                        Expanded(child: _field('ทะเบียนรถ *', hint: 'กท-1234', required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('ยี่ห้อ *', hint: 'ISUZU', required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('รุ่น *', hint: 'FRR 210', required: true)),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('ปี (ค.ศ.)', hint: '2023')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('สี', hint: 'ขาว')),
                        const SizedBox(width: 16),
                        Expanded(child: _dropdown('ประเภทรถ *', _type, ['4ล้อ', '6ล้อ', '10ล้อ', 'หัวลาก', 'กระบะ'],
                            (v) => setState(() => _type = v!))),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _dropdown('ประเภทเชื้อเพลิง', _fuelType, ['ดีเซล', 'เบนซิน', 'NGV', 'EV'],
                            (v) => setState(() => _fuelType = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _field('น้ำหนักบรรทุกสูงสุด (กก.)', hint: '6000')),
                        const SizedBox(width: 16),
                        Expanded(child: _dropdown('ประเภทการเป็นเจ้าของ', _ownership, ['own', 'partner', 'rental'],
                            (v) => setState(() => _ownership = v!))),
                      ]),
                    ]),
                    const SizedBox(height: 16),

                    // Section 2: เลขตัวถัง / เครื่องยนต์
                    _buildSection(context, 'เลขตัวถัง / เครื่องยนต์', [
                      Row(children: [
                        Expanded(child: _field('เลขตัวถัง (Chassis No.)', hint: 'MPATFS66JMT000123')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('เลขเครื่องยนต์ (Engine No.)', hint: '4HK1-123456')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('เลขไมล์ปัจจุบัน (กม.)', hint: '85000')),
                      ]),
                    ]),
                    const SizedBox(height: 16),

                    // Section 3: ประกัน / ภาษี / พ.ร.บ.
                    _buildSection(context, 'ประกันภัย / ภาษี / พ.ร.บ.', [
                      Row(children: [
                        Expanded(child: _field('บริษัทประกันภัย', hint: 'วิริยะประกันภัย')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('เลขกรมธรรม์', hint: 'INS-2024-001')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('ประเภทประกัน', hint: 'ชั้น 1')),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('วันหมดอายุประกันภัย', hint: 'dd/mm/yyyy')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('วันครบกำหนดภาษีรถยนต์', hint: 'dd/mm/yyyy')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('วันครบกำหนด พ.ร.บ.', hint: 'dd/mm/yyyy')),
                      ]),
                    ]),
                    const SizedBox(height: 16),

                    // Section 4: คนขับประจำ
                    _buildSection(context, 'คนขับประจำ', [
                      Row(children: [
                        Expanded(child: _field('คนขับประจำ (ชื่อ / รหัส)', hint: 'สมชาย ใจดี')),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()),
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
        const SnackBar(content: Text('บันทึกข้อมูลรถเรียบร้อย')),
      );
    }
  }
}
