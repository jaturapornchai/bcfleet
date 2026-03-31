import 'package:flutter/material.dart';

class PodScreen extends StatefulWidget {
  final String tripId;

  const PodScreen({super.key, required this.tripId});

  @override
  State<PodScreen> createState() => _PodScreenState();
}

class _PodScreenState extends State<PodScreen> {
  final _receiverController = TextEditingController();
  final _notesController = TextEditingController();
  final List<String> _photos = [];
  bool _hasSig = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _receiverController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addPhoto() {
    setState(() => _photos.add('photo_${_photos.length + 1}.jpg'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เพิ่มรูปภาพแล้ว (ในระบบจริงจะเปิดกล้อง)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _captureSignature() {
    setState(() => _hasSig = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บันทึกลายเซ็นแล้ว'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _savePod() async {
    if (_receiverController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อผู้รับ')),
      );
      return;
    }
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บันทึก POD สำเร็จ'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('หลักฐานส่งมอบ (POD)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos section
            const Text('รูปภาพหลักฐาน',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                            color: Colors.grey.shade400, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.grey),
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
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(Icons.image,
                            color: Colors.blue.shade400, size: 36),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _photos.removeAt(index)),
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
            const SizedBox(height: 20),

            // Signature section
            const Text('ลายเซ็นผู้รับ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _captureSignature,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _hasSig
                        ? Colors.green.shade400
                        : Colors.grey.shade400,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _hasSig ? Colors.green.shade50 : Colors.grey.shade50,
                ),
                child: Center(
                  child: _hasSig
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green.shade600, size: 36),
                            const SizedBox(height: 4),
                            Text('บันทึกลายเซ็นแล้ว',
                                style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.draw_outlined,
                                color: Colors.grey.shade500, size: 36),
                            const SizedBox(height: 4),
                            Text('แตะเพื่อเซ็นชื่อ',
                                style:
                                    TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Receiver info
            const Text('ข้อมูลผู้รับ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _receiverController,
              decoration: const InputDecoration(
                labelText: 'ชื่อผู้รับสินค้า *',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'หมายเหตุ',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isSaving ? null : _savePod,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึก POD'),
            ),
          ],
        ),
      ),
    );
  }
}
