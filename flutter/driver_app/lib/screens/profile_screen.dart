import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Mock driver profile data
  static const Map<String, dynamic> _profile = {
    'name': 'สมชาย ใจดี',
    'nickname': 'ชาย',
    'employee_id': 'EMP-001',
    'phone': '081-234-5678',
    'id_card': '1-1234-12345-12-1',
    'license_type': 'ท.2',
    'license_no': '12345678',
    'license_expiry': '15/01/2569',
    'vehicle_plate': 'กท-1234',
    'vehicle_type': 'ISUZU FRR 6 ล้อ',
    'shift': 'เช้า (06:00–18:00)',
    'employment_type': 'พนักงานประจำ',
    'start_date': '01/01/2563',
    'score': 92,
    'total_trips': 450,
    'on_time_rate': 0.95,
    'fuel_efficiency': 5.2,
    'customer_rating': 4.8,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('แก้ไขข้อมูลส่วนตัว (placeholder)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with avatar
            Container(
              width: double.infinity,
              color: const Color(0xFF1565C0),
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (_profile['name'] as String).substring(0, 2),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _profile['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_profile['employee_id']} · ${_profile['employment_type']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // KPI Score card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('คะแนนผลงาน',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Score circle
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _scoreColor(
                                      _profile['score'] as int),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${_profile['score']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'คะแนน',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _KpiRow(
                                      label: 'เที่ยวทั้งหมด',
                                      value:
                                          '${_profile['total_trips']} เที่ยว',
                                    ),
                                    _KpiRow(
                                      label: 'ตรงเวลา',
                                      value:
                                          '${((_profile['on_time_rate'] as double) * 100).toStringAsFixed(0)}%',
                                    ),
                                    _KpiRow(
                                      label: 'ประหยัดน้ำมัน',
                                      value:
                                          '${_profile['fuel_efficiency']} กม/ล',
                                    ),
                                    _KpiRow(
                                      label: 'คะแนนลูกค้า',
                                      value:
                                          '${_profile['customer_rating']}/5.0',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Personal info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ข้อมูลส่วนตัว',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const Divider(),
                          _InfoTile(
                            icon: Icons.phone,
                            label: 'เบอร์โทร',
                            value: _profile['phone'] as String,
                          ),
                          _InfoTile(
                            icon: Icons.badge_outlined,
                            label: 'เลขบัตรประชาชน',
                            value: _profile['id_card'] as String,
                          ),
                          _InfoTile(
                            icon: Icons.work_outline,
                            label: 'ประเภทการจ้าง',
                            value: _profile['employment_type'] as String,
                          ),
                          _InfoTile(
                            icon: Icons.calendar_today,
                            label: 'วันเริ่มงาน',
                            value: _profile['start_date'] as String,
                          ),
                          _InfoTile(
                            icon: Icons.access_time,
                            label: 'กะทำงาน',
                            value: _profile['shift'] as String,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // License info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ใบขับขี่ & รถที่ใช้',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const Divider(),
                          _InfoTile(
                            icon: Icons.credit_card,
                            label: 'ประเภทใบขับขี่',
                            value: _profile['license_type'] as String,
                          ),
                          _InfoTile(
                            icon: Icons.tag,
                            label: 'เลขใบขับขี่',
                            value: _profile['license_no'] as String,
                          ),
                          _InfoTile(
                            icon: Icons.event,
                            label: 'หมดอายุ',
                            value: _profile['license_expiry'] as String,
                            valueColor: Colors.orange.shade700,
                          ),
                          _InfoTile(
                            icon: Icons.local_shipping,
                            label: 'รถที่ใช้',
                            value:
                                '${_profile['vehicle_plate']} (${_profile['vehicle_type']})',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout button
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('ออกจากระบบ'),
                          content: const Text('ต้องการออกจากระบบหรือไม่?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('ยกเลิก'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              },
                              child: const Text(
                                'ออกจากระบบ',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 85) return Colors.green.shade600;
    if (score >= 70) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}

class _KpiRow extends StatelessWidget {
  final String label;
  final String value;

  const _KpiRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
