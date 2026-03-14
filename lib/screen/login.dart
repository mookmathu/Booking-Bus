import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Firebase login ──────────────────────────────────────────
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMsg = 'ไม่พบบัญชีผู้ใช้นี้';
            break;
          case 'wrong-password':
            _errorMsg = 'รหัสผ่านไม่ถูกต้อง';
            break;
          case 'invalid-email':
            _errorMsg = 'รูปแบบอีเมลไม่ถูกต้อง';
            break;
          case 'too-many-requests':
            _errorMsg = 'ลองใหม่อีกครั้งในภายหลัง';
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
          // ── Decorative background blobs ──────────────────────
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

          // ── Main content ─────────────────────────────────────
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
                        const SizedBox(height: 48),

                        // ── Logo / Brand ────────────────────────
                        Center(
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4A80C4), Color(0xFF1E3F75)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3F6FB6).withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.directions_bus_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Heading ─────────────────────────────
                        const Center(
                          child: Text(
                            'ยินดีต้อนรับ',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A2744),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'เข้าสู่ระบบเพื่อจองรถตู้',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Card form ───────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3F6FB6).withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // Email
                              _fieldLabel('อีเมล'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1A2744),
                                ),
                                decoration: _inputDecoration(
                                  hint: 'example@email.com',
                                  icon: Icons.mail_outline_rounded,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'กรุณากรอกอีเมล';
                                  }
                                  if (!v.contains('@')) {
                                    return 'รูปแบบอีเมลไม่ถูกต้อง';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Password
                              _fieldLabel('รหัสผ่าน'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _signIn(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1A2744),
                                ),
                                decoration: _inputDecoration(
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
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

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotDialog,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'ลืมรหัสผ่าน?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF3F6FB6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              // Error message
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
                                      Text(
                                        _errorMsg!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFE53935),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              const SizedBox(height: 4),

                              // Login button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _signIn,
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
                                          'เข้าสู่ระบบ',
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

                        const SizedBox(height: 28),

                        // ── Divider ─────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'หรือ',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Register link ───────────────────────
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ยังไม่มีบัญชี? ',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/register'),
                                child: const Text(
                                  'สมัครสมาชิก',
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

                        const SizedBox(height: 32),
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

  // ── Forgot password dialog ──────────────────────────────────
  void _showForgotDialog() {
    final resetCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ลืมรหัสผ่าน',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'กรอกอีเมลของคุณ ระบบจะส่งลิงก์รีเซ็ตรหัสผ่านไปให้',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                hint: 'อีเมลของคุณ',
                icon: Icons.mail_outline_rounded,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก',
                style: TextStyle(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C4C85),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (resetCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: resetCtrl.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ส่งอีเมลรีเซ็ตรหัสผ่านแล้ว'),
                      backgroundColor: Color(0xFF43A047),
                    ),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่'),
                      backgroundColor: Color(0xFFE53935),
                    ),
                  );
                }
              }
            },
            child: const Text('ส่งลิงก์'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────
  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A2744),
        ),
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