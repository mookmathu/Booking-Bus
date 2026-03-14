import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_appbar.dart';

// ============================================================
// Model ประวัติการจอง
// ============================================================
class BookingHistory {
  final String id;
  final String from;
  final String to;
  final String date;
  final String tripStatus;
  final String status;
  final DateTime? createdAt;
  final int seats;
  final double total;

  const BookingHistory({
    required this.id,
    required this.from,
    required this.to,
    required this.date,
    required this.tripStatus,
    required this.status,
    this.createdAt,
    required this.seats,
    required this.total,
  });

  factory BookingHistory.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookingHistory(
      id: doc.id,
      from: d['from'] ?? '',
      to: d['to'] ?? '',
      date: d['date'] ?? '',
      tripStatus: d['tripStatus'] ?? 'pending',
      status: d['status'] ?? 'confirmed',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      seats: (d['seats'] ?? 1) is int ? d['seats'] : int.tryParse('${d['seats']}') ?? 1,
      total: (d['total'] ?? 0).toDouble(),
    );
  }

  String get route => '$from → $to';
  bool get isOngoing => tripStatus == 'pending' || tripStatus == 'waiting' || tripStatus == 'onboard';
}

// ============================================================
// Profile Screen
// ============================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showHistory = false;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get _user => _auth.currentUser;
  String get _userEmail => _user?.email ?? '-';

  // ข้อมูล profile ที่โหลดจาก Firestore
  String _displayName = '';
  String _phone = '';
  String _gender = '';       // 'ชาย' | 'หญิง' | 'ไม่ระบุ'
  DateTime? _birthDate;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── โหลด profile จาก Firestore ────────────────────────────
  Future<void> _loadProfile() async {
    final uid = _user?.uid;
    if (uid == null) {
      setState(() => _loadingProfile = false);
      return;
    }
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final d = doc.data()!;
        setState(() {
          _displayName = d['displayName'] ?? _user?.displayName ?? '';
          _phone = d['phone'] ?? '';
          _gender = d['gender'] ?? '';
          final bd = d['birthDate'];
          _birthDate = bd is Timestamp ? bd.toDate() : null;
        });
      } else {
        setState(() {
          _displayName = _user?.displayName ?? '';
        });
      }
    } catch (_) {}
    setState(() => _loadingProfile = false);
  }

  // ── Stream การจอง ──────────────────────────────────────────
  Stream<List<BookingHistory>> _bookingsStream() {
    final uid = _user?.uid;
    if (uid == null || uid.isEmpty) return Stream.value([]);
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(BookingHistory.fromDoc).toList();
      list.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Profile',
        subtitle: 'ข้อมูลผู้ใช้งาน',
        automaticallyImplyLeading: Navigator.canPop(context),
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<BookingHistory>>(
              stream: _bookingsStream(),
              builder: (context, snapshot) {
                final bookings = snapshot.data ?? [];
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                return SingleChildScrollView(
                  child: _showHistory
                      ? _buildHistoryView(bookings, isLoading)
                      : _buildMainView(bookings, isLoading),
                );
              },
            ),
    );
  }

  // ============================================================
  // Main Profile View
  // ============================================================
  Widget _buildMainView(List<BookingHistory> bookings, bool isLoading) {
    final doneCount = bookings.where((b) => b.tripStatus == 'completed').length;
    final nameDisplay = _displayName.isNotEmpty
        ? _displayName
        : _userEmail.split('@').first;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF3F6FB6).withOpacity(0.15),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    nameDisplay.isNotEmpty
                        ? nameDisplay[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            nameDisplay,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _userEmail,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),

          if (_phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _phone,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],

          if (_gender.isNotEmpty || _birthDate != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_gender.isNotEmpty) ...[
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(_gender,
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
                if (_gender.isNotEmpty && _birthDate != null)
                  const Text('  •  ',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                if (_birthDate != null) ...[
                  const Icon(Icons.cake_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year + 543}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Stats card
          GestureDetector(
            onTap: () => setState(() => _showHistory = true),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "ประวัติการจอง",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3F6FB6),
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.chevron_right,
                            color: Color(0xFF3F6FB6), size: 20),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statItem("${bookings.length}", "จำนวนที่เคยจอง"),
                      Container(width: 1, height: 40, color: Colors.grey.shade200),
                      _statItem("$doneCount", "สำเร็จ"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Manage Profile
          _menuItem(
            icon: Icons.edit,
            iconColor: const Color(0xFF43A047),
            label: "จัดการโปรไฟล์",
            onTap: () => _showEditProfileSheet(context),
          ),

          const SizedBox(height: 10),

          _menuItem(
            icon: Icons.dark_mode,
            iconColor: const Color(0xFF3F6FB6),
            label: "Dark Mode",
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Dark Mode (coming soon)")),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                await _auth.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                }
              },
              child: const Text(
                "ออกจากระบบ",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Edit Profile Bottom Sheet
  // ============================================================
  void _showEditProfileSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _displayName);
    final phoneCtrl = TextEditingController(text: _phone);
    String selectedGender = _gender.isNotEmpty ? _gender : '';
    DateTime? selectedBirth = _birthDate;
    bool saving = false;
    String? errorMsg;

    // helper format วันเกิด → พ.ศ.
    String formatBirth(DateTime d) {
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      final year = d.year + 543;
      return '$day/$month/$year';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> save() async {
            final name = nameCtrl.text.trim();
            final phone = phoneCtrl.text.trim();

            if (name.isEmpty) {
              setSheet(() => errorMsg = 'กรุณากรอกชื่อ-นามสกุล');
              return;
            }
            if (phone.isNotEmpty &&
                !RegExp(r'^0[0-9]{8,9}$').hasMatch(phone)) {
              setSheet(() => errorMsg = 'รูปแบบเบอร์โทรไม่ถูกต้อง (เช่น 0812345678)');
              return;
            }

            setSheet(() {
              saving = true;
              errorMsg = null;
            });

            try {
              final uid = _user!.uid;
              await _db.collection('users').doc(uid).set({
                'displayName': name,
                'phone': phone,
                'gender': selectedGender,
                'birthDate': selectedBirth != null
                    ? Timestamp.fromDate(selectedBirth!)
                    : null,
                'email': _userEmail,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              await _user!.updateDisplayName(name);

              if (mounted) {
                setState(() {
                  _displayName = name;
                  _phone = phone;
                  _gender = selectedGender;
                  _birthDate = selectedBirth;
                });
              }

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text("บันทึกข้อมูลสำเร็จ"),
                      ],
                    ),
                    backgroundColor: Color(0xFF43A047),
                  ),
                );
              }
            } catch (e) {
              setSheet(() {
                saving = false;
                errorMsg = 'เกิดข้อผิดพลาด: ${e.toString()}';
              });
            }
          }

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Header
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF43A047).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit,
                                color: Color(0xFF43A047), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "จัดการโปรไฟล์",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              Text(
                                "ข้อมูลจะถูกบันทึกไว้กับบัญชีของคุณ",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 20),

                      // ── ชื่อ-นามสกุล ──────────────────────
                      _sheetLabel("ชื่อ-นามสกุล *"),
                      const SizedBox(height: 8),
                      _sheetTextField(
                        controller: nameCtrl,
                        hint: "เช่น นายสมชาย ใจดี",
                        icon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                      ),

                      const SizedBox(height: 16),

                      // ── เบอร์โทรศัพท์ ──────────────────────
                      _sheetLabel("เบอร์โทรศัพท์"),
                      const SizedBox(height: 8),
                      _sheetTextField(
                        controller: phoneCtrl,
                        hint: "เช่น 0812345678",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 16),

                      // ── เพศ ────────────────────────────────
                      _sheetLabel("เพศ"),
                      const SizedBox(height: 8),
                      Row(
                        children: ['ชาย', 'หญิง', 'ไม่ระบุ'].map((g) {
                          final selected = selectedGender == g;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setSheet(() => selectedGender = g),
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: g != 'ไม่ระบุ' ? 8 : 0,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF3F6FB6)
                                      : const Color(0xFFF5F6FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF3F6FB6)
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Text(
                                  g,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? Colors.white : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // ── วันเกิด ────────────────────────────
                      _sheetLabel("วันเกิด"),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedBirth ??
                                DateTime(now.year - 20, now.month, now.day),
                            firstDate: DateTime(1950),
                            lastDate: now,
                            locale: const Locale('th', 'TH'),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF3F6FB6),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Color(0xFF2C3E50),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setSheet(() => selectedBirth = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedBirth != null
                                  ? const Color(0xFF3F6FB6).withOpacity(0.5)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cake_outlined,
                                size: 20,
                                color: selectedBirth != null
                                    ? const Color(0xFF3F6FB6)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedBirth != null
                                      ? formatBirth(selectedBirth!)
                                      : 'เลือกวันเกิด',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedBirth != null
                                        ? const Color(0xFF2C3E50)
                                        : Colors.grey,
                                    fontWeight: selectedBirth != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down,
                                  color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Email (แสดงอย่างเดียว) ─────────────
                      _sheetLabel("อีเมล (ไม่สามารถแก้ไขได้)"),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline,
                                size: 18, color: Colors.grey.shade400),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _userEmail,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Error message
                      if (errorMsg != null) ...[
                        const SizedBox(height: 14),
                        Container(
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
                                  errorMsg!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFE53935)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── ปุ่มบันทึก ─────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3F6FB6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: saving ? null : save,
                          child: saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "บันทึกข้อมูล",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // History View
  // ============================================================
  Widget _buildHistoryView(List<BookingHistory> bookings, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => setState(() => _showHistory = false),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  _displayName.isNotEmpty
                      ? _displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName.isNotEmpty
                          ? _displayName
                          : _userEmail.split('@').first,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (_phone.isNotEmpty)
                      Text(_phone,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "ประวัติการจอง",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3F6FB6),
                    ),
                  ),
                ),
                const Divider(height: 1),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )
                else if (bookings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text("ยังไม่มีประวัติการจอง",
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                else
                  ...bookings
                      .asMap()
                      .entries
                      .map((e) => _historyItem(e.value, e.key + 1))
                      .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyItem(BookingHistory h, int number) {
    final statusLabel = switch (h.tripStatus) {
      'pending'   => 'รอดำเนินการ',
      'waiting'   => 'มารอรถแล้ว',
      'onboard'   => 'ขึ้นรถแล้ว',
      'completed' => 'เดินทางสำเร็จ',
      'cancelled' => 'ยกเลิก',
      _ => h.tripStatus,
    };
    final statusColor = switch (h.tripStatus) {
      'pending'   => const Color(0xFF1E88E5),
      'waiting'   => const Color(0xFFE53935),
      'onboard'   => const Color(0xFFF57C00),
      'completed' => const Color(0xFF43A047),
      'cancelled' => const Color(0xFFE53935),
      _ => Colors.grey,
    };
    final displayDate = h.date.isNotEmpty
        ? h.date
        : h.createdAt != null
            ? '${h.createdAt!.day}/${h.createdAt!.month}/${h.createdAt!.year + 543}'
            : '-';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text("$number",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: statusColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.route,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 2),
                    Text(statusLabel,
                        style: TextStyle(fontSize: 11, color: statusColor)),
                    Text(displayDate,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('฿${h.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50))),
                  Text('${h.seats} ที่นั่ง',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                switch (h.tripStatus) {
                  'completed' => Icons.check_circle_outline,
                  'cancelled' => Icons.cancel_outlined,
                  'waiting'   => Icons.where_to_vote,
                  'onboard'   => Icons.directions_bus,
                  _ => Icons.access_time,
                },
                color: statusColor,
                size: 22,
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  // ============================================================
  // Helpers
  // ============================================================
  Widget _statItem(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3F6FB6))),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );

  Widget _menuItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50))),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      );

  Widget _sheetTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF3F6FB6)),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
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
          borderSide:
              const BorderSide(color: Color(0xFF3F6FB6), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}