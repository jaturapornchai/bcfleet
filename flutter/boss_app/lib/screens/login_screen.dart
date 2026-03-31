import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกเบอร์โทรให้ถูกต้อง')),
      );
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loading = false;
      _otpSent = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่ง OTP ไปที่ $phone แล้ว')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก OTP ให้ครบ')),
      );
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _loading = false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height - MediaQuery.of(context).padding.top,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo & Brand
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      size: 44,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SML Fleet',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'สำหรับเจ้าของและผู้จัดการ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(flex: 2),

                  // Form Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'เข้าสู่ระบบ',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ยืนยันตัวตนด้วยเบอร์โทรศัพท์',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Phone field
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !_otpSent,
                            decoration: InputDecoration(
                              labelText: 'เบอร์โทรศัพท์',
                              hintText: '08X-XXX-XXXX',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              suffixIcon: _otpSent
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // OTP field (show after sent)
                          if (_otpSent) ...[
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                labelText: 'รหัส OTP',
                                hintText: 'XXXXXX',
                                prefixIcon: Icon(Icons.lock_outline),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : _sendOtp,
                                child: const Text('ส่ง OTP ใหม่'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),

                          // Action button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _loading
                                  ? null
                                  : (_otpSent ? _verifyOtp : _sendOtp),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(_otpSent ? 'เข้าสู่ระบบ' : 'ขอรหัส OTP'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Footer
                  Text(
                    'SML Fleet v1.0 — BC Ai Solution Co., Ltd.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
