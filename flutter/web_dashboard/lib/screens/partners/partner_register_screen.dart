import 'package:flutter/material.dart';

class PartnerRegisterScreen extends StatefulWidget {
  final String? partnerId;
  const PartnerRegisterScreen({super.key, this.partnerId});

  @override
  State<PartnerRegisterScreen> createState() => _PartnerRegisterScreenState();
}

class _PartnerRegisterScreenState extends State<PartnerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _vehicleType = '6ล้อ';
  String _pricingModel = 'per_trip';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.partnerId != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isEdit ? 'แก้ไขรถร่วม' : 'ลงทะเบียนรถร่วม',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton(onPressed: () {}, child: const Text('ยกเลิก')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save, size: 18),
                label: Text(isEdit ? 'บันทึกการแก้ไข' : 'ลงทะเบียน'),
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
                    // Section 1: ข้อมูลเจ้าของ
                    _buildSection(cs, 'ข้อมูลเจ้าของ / บริษัท', [
                      Row(children: [
                        Expanded(child: _field('ชื่อเจ้าของ *', hint: 'สมหมาย รถเยอะ', required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('ชื่อบริษัท / ห้างหุ้นส่วน', hint: 'บจก.ขนส่งสมหมาย')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('เลขประจำตัวผู้เสียภาษี *', hint: '0105564123456', required: true)),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('เบอร์โทรศัพท์ *', hint: '081-456-7890', required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('LINE ID', hint: '@sommai_truck')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('อีเมล', hint: 'sommai@email.com')),
                      ]),
                      const SizedBox(height: 16),
                      _field('ที่อยู่', hint: '789 ม.2 ต.ป่าแดด อ.เมือง จ.เชียงใหม่'),
                    ]),
                    const SizedBox(height: 16),

                    // Section 2: ข้อมูลรถ
                    _buildSection(cs, 'ข้อมูลรถ', [
                      Row(children: [
                        Expanded(child: _field('ทะเบียนรถ *', hint: '2กร-5678', required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('ยี่ห้อ', hint: 'HINO')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('รุ่น', hint: '500')),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _dropdown('ประเภทรถ *', _vehicleType,
                            ['4ล้อ', '6ล้อ', '10ล้อ', 'หัวลาก', 'กระบะ'],
                            ['4 ล้อ', '6 ล้อ', '10 ล้อ', 'หัวลาก', 'กระบะ'],
                            (v) => setState(() => _vehicleType = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _field('ปีรถ', hint: '2022')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('น้ำหนักบรรทุกสูงสุด (กก.)', hint: '15,000')),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('พื้นที่ให้บริการ', hint: 'เชียงใหม่, ลำพูน, ลำปาง')),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()),
                      ]),
                    ]),
                    const SizedBox(height: 16),

                    // Section 3: คนขับ
                    _buildSection(cs, 'ข้อมูลคนขับ', [
                      Row(children: [
                        Expanded(child: _field('ชื่อคนขับ *', hint: 'วิชัย ขับดี', required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('เบอร์โทรคนขับ', hint: '089-567-8901')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('เลขใบขับขี่', hint: '12345678')),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('ประเภทใบขับขี่', hint: 'ท.2')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('วันหมดอายุใบขับขี่', hint: 'dd/mm/yyyy')),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()),
                      ]),
                    ]),
                    const SizedBox(height: 16),

                    // Section 4: ราคาและบัญชี
                    _buildSection(cs, 'ราคาและบัญชีธนาคาร', [
                      Row(children: [
                        Expanded(child: _dropdown('รูปแบบราคา', _pricingModel,
                            ['per_trip', 'per_km', 'per_day'],
                            ['ราคาต่อเที่ยว', 'ราคาต่อกิโลเมตร', 'ราคาต่อวัน'],
                            (v) => setState(() => _pricingModel = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _field('ราคาเริ่มต้น (บาท)', hint: '3,000')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('ราคาต่อ กม. (ถ้ามี)', hint: '15')),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('ธนาคาร', hint: 'กสิกรไทย')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('เลขบัญชี', hint: '123-4-56789-0')),
                        const SizedBox(width: 16),
                        Expanded(child: _field('ชื่อบัญชี', hint: 'บจก.ขนส่งสมหมาย')),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('อัตราหัก ณ ที่จ่าย (%)', hint: '1')),
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

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลรถร่วมเรียบร้อย')),
      );
    }
  }
}
