import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorMsg;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Firebase Register ───────────────────────────────────────
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      // 1. สร้าง user ใน Firebase Auth
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      // 2. อัปเดต displayName
      await credential.user?.updateDisplayName(
        '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
      );

      // 3. บันทึกข้อมูลลง Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'fullName':
            '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMsg = 'อีเมลนี้ถูกใช้งานแล้ว';
            break;
          case 'invalid-email':
            _errorMsg = 'รูปแบบอีเมลไม่ถูกต้อง';
            break;
          case 'weak-password':
            _errorMsg = 'รหัสผ่านไม่ปลอดภัยพอ กรุณาใช้อย่างน้อย 6 ตัวอักษร';
            break;
          default:
            _errorMsg = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: Stack(
        children: [
          // ── Background blobs ────────────────────────────────
          Positioned(
            top: -60,
            left: -60,
            child: _blob(220, const Color(0xFF3F6FB6), 0.12),
          ),
          Positioned(
            top: 80,
            right: -80,
            child: _blob(260, const Color(0xFF2C4C85), 0.09),
          ),
          Positioned(
            bottom: -80,
            left: size.width * 0.2,
            child: _blob(300, const Color(0xFF3F6FB6), 0.08),
          ),

          // ── Main content ────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 36),

                        // ── Back button ─────────────────────────
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 16,
                              color: Color(0xFF2C4C85),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Logo ────────────────────────────────
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4A80C4), Color(0xFF1E3F75)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF3F6FB6).withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Heading ─────────────────────────────
                        const Center(
                          child: Text(
                            'สมัครสมาชิก',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A2744),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'กรอกข้อมูลเพื่อสร้างบัญชีใหม่',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Form card ───────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF3F6FB6).withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // ── ชื่อ + นามสกุล (2 columns) ──────
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel('ชื่อ'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _firstNameCtrl,
                                          textInputAction: TextInputAction.next,
                                          style: _inputTextStyle,
                                          decoration: _inputDecoration(
                                            hint: 'ชื่อจริง',
                                            icon: Icons.person_outline_rounded,
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                                  ? 'กรุณากรอกชื่อ'
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel('นามสกุล'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _lastNameCtrl,
                                          textInputAction: TextInputAction.next,
                                          style: _inputTextStyle,
                                          decoration: _inputDecoration(
                                            hint: 'นามสกุล',
                                            icon: Icons.person_outline_rounded,
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                                  ? 'กรุณากรอก'
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // ── เบอร์โทร ─────────────────────────
                              _fieldLabel('เบอร์โทรศัพท์'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                style: _inputTextStyle,
                                decoration: _inputDecoration(
                                  hint: '0XX-XXX-XXXX',
                                  icon: Icons.phone_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'กรุณากรอกเบอร์โทร';
                                  }
                                  final digits = v.replaceAll(RegExp(r'\D'), '');
                                  if (digits.length < 9) {
                                    return 'เบอร์โทรไม่ถูกต้อง';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 18),

                              // ── อีเมล ────────────────────────────
                              _fieldLabel('อีเมล'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: _inputTextStyle,
                                decoration: _inputDecoration(
                                  hint: 'example@email.com',
                                  icon: Icons.mail_outline_rounded,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'กรุณากรอกอีเมล';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                      .hasMatch(v)) {
                                    return 'รูปแบบอีเมลไม่ถูกต้อง';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 18),

                              // ── รหัสผ่าน ─────────────────────────
                              _fieldLabel('รหัสผ่าน'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                style: _inputTextStyle,
                                decoration: _inputDecoration(
                                  hint: 'อย่างน้อย 6 ตัวอักษร',
                                  icon: Icons.lock_outline_rounded,
                                ).copyWith(
                                  suffixIcon: _eyeButton(
                                    _obscurePassword,
                                    () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'กรุณากรอกรหัสผ่าน';
                                  }
                                  if (v.length < 6) {
                                    return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 18),

                              // ── ยืนยันรหัสผ่าน ───────────────────
                              _fieldLabel('ยืนยันรหัสผ่าน'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _confirmCtrl,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _register(),
                                style: _inputTextStyle,
                                decoration: _inputDecoration(
                                  hint: 'กรอกรหัสผ่านอีกครั้ง',
                                  icon: Icons.lock_outline_rounded,
                                ).copyWith(
                                  suffixIcon: _eyeButton(
                                    _obscureConfirm,
                                    () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'กรุณายืนยันรหัสผ่าน';
                                  }
                                  if (v != _passwordCtrl.text) {
                                    return 'รหัสผ่านไม่ตรงกัน';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // ── Error message ────────────────────
                              if (_errorMsg != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Color(0xFFE53935), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMsg!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFFE53935),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // ── Register button ──────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2C4C85),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0xFF2C4C85).withOpacity(0.6),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'สมัครสมาชิก',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Login link ──────────────────────────
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'มีบัญชีอยู่แล้ว? ',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'เข้าสู่ระบบ',
                                  style: TextStyle(
                                    color: Color(0xFF3F6FB6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────
  static const TextStyle _inputTextStyle = TextStyle(
    fontSize: 15,
    color: Color(0xFF1A2744),
  );

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A2744),
        ),
      );

  Widget _eyeButton(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: Colors.grey.shade400,
        ),
        onPressed: onTap,
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFF5F7FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3F6FB6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _blob(double size, Color color, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
        ),
      );
}