import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/expense_bloc.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  String _type = 'fuel';
  final _litersCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _stationCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _litersCtrl.dispose();
    _priceCtrl.dispose();
    _odometerCtrl.dispose();
    _stationCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _calcFuelAmount() {
    final liters = double.tryParse(_litersCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (liters > 0 && price > 0) {
      _amountCtrl.text = (liters * price).toStringAsFixed(2);
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกจำนวนเงิน')),
      );
      return;
    }
    setState(() => _isSaving = true);
    context.read<ExpenseBloc>().add(
          CreateExpense({
            'type': _type,
            'amount': amount,
            'description': _descCtrl.text,
            if (_type == 'fuel') ...{
              'fuel_liters': double.tryParse(_litersCtrl.text),
              'fuel_price_per_liter': double.tryParse(_priceCtrl.text),
              'odometer_km': int.tryParse(_odometerCtrl.text),
              'station': _stationCtrl.text,
            },
          }),
        );
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บันทึกค่าใช้จ่ายสำเร็จ'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _litersCtrl.clear();
    _priceCtrl.clear();
    _amountCtrl.clear();
    _odometerCtrl.clear();
    _stationCtrl.clear();
    _descCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('บันทึกค่าใช้จ่าย')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            const Text('ประเภทค่าใช้จ่าย',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'fuel', child: Text('น้ำมัน')),
                DropdownMenuItem(value: 'toll', child: Text('ค่าทางด่วน')),
                DropdownMenuItem(
                    value: 'parking', child: Text('ค่าที่จอดรถ')),
                DropdownMenuItem(value: 'other', child: Text('อื่นๆ')),
              ],
              onChanged: (val) => setState(() => _type = val ?? 'fuel'),
            ),
            const SizedBox(height: 20),

            // Fuel-specific fields
            if (_type == 'fuel') ...[
              const Text('รายละเอียดน้ำมัน',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _litersCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'))
                      ],
                      decoration: const InputDecoration(
                        labelText: 'จำนวนลิตร',
                        suffixText: 'ลิตร',
                      ),
                      onChanged: (_) => _calcFuelAmount(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'))
                      ],
                      decoration: const InputDecoration(
                        labelText: 'ราคา/ลิตร',
                        suffixText: '฿',
                      ),
                      onChanged: (_) => _calcFuelAmount(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _odometerCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'เลขไมล์',
                  suffixText: 'กม.',
                  prefixIcon: Icon(Icons.speed),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stationCtrl,
                decoration: const InputDecoration(
                  labelText: 'ชื่อปั๊มน้ำมัน',
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              decoration: const InputDecoration(
                labelText: 'จำนวนเงิน *',
                prefixText: '฿ ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),

            if (_type != 'fuel')
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียด',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
            const SizedBox(height: 12),

            // Receipt photo
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('เปิดกล้องถ่ายใบเสร็จ (placeholder)'),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('ถ่ายรูปใบเสร็จ'),
            ),
            const SizedBox(height: 24),

            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึก'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
