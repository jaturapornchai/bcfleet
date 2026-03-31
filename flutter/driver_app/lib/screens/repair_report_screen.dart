import 'package:flutter/material.dart';

class RepairReportScreen extends StatefulWidget {
  const RepairReportScreen({super.key});

  @override
  State<RepairReportScreen> createState() => _RepairReportScreenState();
}

class _RepairReportScreenState extends State<RepairReportScreen> {
  final _symptomsCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  String _urgency = 'medium';
  final List<String> _photos = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mock current mileage
    _mileageCtrl.text = '85,234';
  }

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _addPhoto() {
    setState(() => _photos.add('repair_photo_${_photos.length + 1}.jpg'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เพิ่มรูปภาพแล้ว (ในระบบจริงจะเปิดกล้อง)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    if (_symptomsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาอธิบายอาการ/ปัญหา')),
      );
      return;
    }
    setState(() => _isSending = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ส่งแจ้งซ่อมสำเร็จ — ทีมช่างจะติดต่อกลับ'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งซ่อมรถ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current mileage (read-only display)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.speed, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  const Text('เลขไมล์ปัจจุบัน',
                      style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const Spacer(),
                  Text(
                    '${_mileageCtrl.text} กม.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Urgency
            const Text('ความเร่งด่วน',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _urgency,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.priority_high,
                  color: _urgencyColor(_urgency),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('ต่ำ — ซ่อมตามนัด')),
                DropdownMenuItem(
                    value: 'medium', child: Text('ปานกลาง — ภายในวันนี้')),
                DropdownMenuItem(
                    value: 'high', child: Text('สูง — ด่วน ภายใน 2 ชั่วโมง')),
                DropdownMenuItem(
                    value: 'emergency', child: Text('ฉุกเฉิน — หยุดรถแล้ว!')),
              ],
              onChanged: (val) => setState(() => _urgency = val ?? 'medium'),
            ),
            const SizedBox(height: 20),

            // Symptoms
            const Text('อาการ/ปัญหา',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _symptomsCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'อธิบายอาการหรือปัญหาที่พบ เช่น เบรคมีเสียงดัง น้ำมันรั่ว ยางแบน...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 64),
                  child: Icon(Icons.build_outlined),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // Photos
            const Text('รูปภาพประกอบ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'ถ่ายรูปจุดที่มีปัญหาเพื่อช่วยให้ช่างประเมินได้แม่นยำขึ้น',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _photos.length + 1,
              itemBuilder: (context, index) {
                if (index == _photos.length) {
                  return GestureDetector(
                    onTap: _addPhoto,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey.shade400,
                            style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.grey),
                          SizedBox(height: 4),
                          Text('ถ่ายรูป',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(Icons.image,
                            color: Colors.orange.shade400, size: 36),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _photos.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Urgency warning banner for emergency
            if (_urgency == 'emergency')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'กรณีฉุกเฉิน กรุณาจอดรถในที่ปลอดภัยก่อน แล้วโทรหาผู้จัดการทันที',
                        style: TextStyle(
                            color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _submit,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSending ? 'กำลังส่ง...' : 'ส่งแจ้งซ่อม'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _urgency == 'emergency' ? Colors.red : null,
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
