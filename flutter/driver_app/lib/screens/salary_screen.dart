import 'package:flutter/material.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Mock salary data
  final Map<String, dynamic> _salaryData = {
    'base_salary': 15000.0,
    'daily_allowance': 3600.0, // 12 วัน × 300
    'trip_bonus': 4600.0,      // 23 เที่ยว × 200
    'overtime': 1200.0,        // 12 ชม. × 100
    'deduction_social': 750.0,
    'deduction_tax': 0.0,
    'deduction_advance': 2000.0,
    'trips': [
      {'date': '01/12/2567', 'trip_no': 'TRIP-2024-001210', 'route': 'CMI → LPN', 'bonus': 200},
      {'date': '02/12/2567', 'trip_no': 'TRIP-2024-001215', 'route': 'CMI → LPN', 'bonus': 200},
      {'date': '03/12/2567', 'trip_no': 'TRIP-2024-001218', 'route': 'CMI → LPG', 'bonus': 200},
      {'date': '05/12/2567', 'trip_no': 'TRIP-2024-001225', 'route': 'CMI → CNX', 'bonus': 200},
      {'date': '06/12/2567', 'trip_no': 'TRIP-2024-001230', 'route': 'CMI → LPN', 'bonus': 200},
    ],
  };

  double get _grossPay =>
      (_salaryData['base_salary'] as double) +
      (_salaryData['daily_allowance'] as double) +
      (_salaryData['trip_bonus'] as double) +
      (_salaryData['overtime'] as double);

  double get _totalDeduction =>
      (_salaryData['deduction_social'] as double) +
      (_salaryData['deduction_tax'] as double) +
      (_salaryData['deduction_advance'] as double);

  double get _netPay => _grossPay - _totalDeduction;

  final List<String> _thaiMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
    'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
    'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สลิปเงินเดือน')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Month selector
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          if (_selectedMonth == 1) {
                            _selectedMonth = 12;
                            _selectedYear--;
                          } else {
                            _selectedMonth--;
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        '${_thaiMonths[_selectedMonth - 1]} ${_selectedYear + 543}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          if (_selectedMonth == 12) {
                            _selectedMonth = 1;
                            _selectedYear++;
                          } else {
                            _selectedMonth++;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Net pay summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'ยอดรับสุทธิ',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '฿${_netPay.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'รอบจ่าย 25 ${_thaiMonths[_selectedMonth - 1]} ${_selectedYear + 543}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Income breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('รายได้',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    _SalaryRow(
                      label: 'เงินเดือนฐาน',
                      amount: _salaryData['base_salary'] as double,
                      color: Colors.black87,
                    ),
                    _SalaryRow(
                      label: 'เบี้ยเลี้ยง (12 วัน)',
                      amount: _salaryData['daily_allowance'] as double,
                      color: Colors.black87,
                    ),
                    _SalaryRow(
                      label: 'โบนัสเที่ยว (23 เที่ยว)',
                      amount: _salaryData['trip_bonus'] as double,
                      color: Colors.black87,
                    ),
                    _SalaryRow(
                      label: 'ค่าล่วงเวลา (12 ชม.)',
                      amount: _salaryData['overtime'] as double,
                      color: Colors.black87,
                    ),
                    const Divider(),
                    _SalaryRow(
                      label: 'รวมรายได้',
                      amount: _grossPay,
                      color: Colors.green.shade700,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Deduction breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('หักออก',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    _SalaryRow(
                      label: 'ประกันสังคม (5%)',
                      amount: _salaryData['deduction_social'] as double,
                      isDeduction: true,
                    ),
                    _SalaryRow(
                      label: 'ภาษีหัก ณ ที่จ่าย',
                      amount: _salaryData['deduction_tax'] as double,
                      isDeduction: true,
                    ),
                    _SalaryRow(
                      label: 'หักเงินยืม',
                      amount: _salaryData['deduction_advance'] as double,
                      isDeduction: true,
                    ),
                    const Divider(),
                    _SalaryRow(
                      label: 'รวมหักออก',
                      amount: _totalDeduction,
                      color: Colors.red.shade700,
                      isBold: true,
                      isDeduction: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Trip list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('รายการเที่ยว',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '${(_salaryData['trips'] as List).length} เที่ยว',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                    const Divider(),
                    ...(_salaryData['trips'] as List).map((trip) {
                      final t = trip as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['trip_no'] as String,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${t['date']} · ${t['route']}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+฿${t['bonus']}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if ((_salaryData['trips'] as List).length < 23)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '... และอีก ${23 - (_salaryData['trips'] as List).length} เที่ยว',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ดาวน์โหลดสลิป PDF (placeholder)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('ดาวน์โหลดสลิป PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;
  final bool isBold;
  final bool isDeduction;

  const _SalaryRow({
    required this.label,
    required this.amount,
    this.color,
    this.isBold = false,
    this.isDeduction = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (isDeduction ? Colors.red.shade700 : Colors.black87);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isDeduction ? '-' : '+'}฿${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
