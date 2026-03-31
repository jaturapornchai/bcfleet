import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  int _countdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      _showSnackBar('กรุณากรอกเบอร์โทรให้ถูกต้อง');
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _otpSent = true;
      _countdown = 60;
    });
    _startCountdown();
    _showSnackBar('ส่ง OTP ไปยัง $phone แล้ว');
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      return _countdown > 0;
    });
  }

  Future<void> _login() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnackBar('กรุณากรอก OTP 6 หลัก');
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping, size: 80, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'SML Fleet Driver',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'แอปสำหรับคนขับรถ',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'เบอร์โทรศัพท์',
                          hintText: '0812345678',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _requestOtp,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _countdown > 0 ? 'ส่งอีกครั้งใน $_countdown วิ' : 'ขอ OTP',
                              ),
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'รหัส OTP',
                            hintText: '------',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: const Text('เข้าสู่ระบบ'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'OTP จะถูกส่งผ่าน LINE หรือ SMS',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ),
                    ],
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
