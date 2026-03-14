import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_appbar.dart';

// ============================================================
// Trip Status Enum
// pending → waiting → onboard → completed
// ============================================================
enum TripStatus {
  pending,    // รอวันเดินทาง
  waiting,    // ถึงวันแล้ว — ถามว่ามารอรถหรือยัง
  onboard,    // มารอแล้ว — ถามว่าขึ้นรถแล้วหรือยัง
  completed,  // ขึ้นรถแล้ว / เดินทางเสร็จสิ้น
  cancelled,  // ยกเลิก
}

TripStatus _parseTripStatus(String? s) {
  switch (s) {
    case 'waiting':
      return TripStatus.waiting;
    case 'onboard':
      return TripStatus.onboard;
    case 'completed':
      return TripStatus.completed;
    case 'cancelled':
      return TripStatus.cancelled;
    default:
      return TripStatus.pending;
  }
}

// ============================================================
// Notification Screen
// ============================================================
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: AppAppBar(
        title: "Notification",
        subtitle: "อัปเดตการเดินทางล่าสุด",
        automaticallyImplyLeading: canPop,
      ),
      body: user == null
          ? _buildNotLoggedIn()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: user.uid)
                  .where('status', isEqualTo: 'confirmed')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF3F6FB6)),
                  );
                }
                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }

                final docs = snapshot.data?.docs ?? [];

                final active = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final ts = data['tripStatus'] as String? ?? 'pending';
                  return ts != 'completed' && ts != 'cancelled';
                }).toList();

                final done = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final ts = data['tripStatus'] as String? ?? 'pending';
                  return ts == 'completed' || ts == 'cancelled';
                }).toList();

                if (docs.isEmpty) return _buildEmpty();

                return ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  children: [
                    if (active.isNotEmpty) ...[
                      _sectionLabel("การเดินทางที่กำลังมา"),
                      const SizedBox(height: 10),
                      ...active.map((d) => _NotificationCard(docSnapshot: d)),
                    ],
                    if (done.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionLabel("ประวัติการแจ้งเตือน"),
                      const SizedBox(height: 10),
                      ...done.map((d) => _NotificationCard(docSnapshot: d)),
                    ],
                  ],
                );
              },
            ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  Widget _buildEmpty() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 72, color: Colors.grey),
            SizedBox(height: 12),
            Text("ไม่มีการแจ้งเตือน",
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            SizedBox(height: 6),
            Text("การแจ้งเตือนจะปรากฏเมื่อใกล้วันเดินทาง",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );

  Widget _buildNotLoggedIn() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("กรุณาเข้าสู่ระบบ",
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );

  Widget _buildError(String error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
}

// ============================================================
// Notification Card
// ============================================================
class _NotificationCard extends StatelessWidget {
  final DocumentSnapshot docSnapshot;
  const _NotificationCard({required this.docSnapshot});

  Map<String, dynamic> get _data =>
      docSnapshot.data() as Map<String, dynamic>;

  TripStatus get _tripStatus =>
      _parseTripStatus(_data['tripStatus'] as String?);

  Future<void> _updateStatus(String newStatus) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(docSnapshot.id)
        .update({
      'tripStatus': newStatus,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Color get _cardColor {
    switch (_tripStatus) {
      case TripStatus.pending:
        return const Color(0xFF3F6FB6);
      case TripStatus.waiting:
        return const Color(0xFFE53935);
      case TripStatus.onboard:
        return const Color(0xFFF57C00); // ส้ม — รอขึ้นรถ
      case TripStatus.completed:
        return const Color(0xFF43A047); // เขียว — เสร็จแล้ว
      case TripStatus.cancelled:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _cardColor.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_tripStatus) {
      case TripStatus.pending:
        return _PendingContent(
          data: _data,
          onConfirmWaiting: () => _updateStatus('waiting'),
        );
      case TripStatus.waiting:
        return _WaitingContent(
          data: _data,
          onConfirmArrived: () => _updateStatus('onboard'),
        );
      case TripStatus.onboard:
        return _OnboardContent(
          data: _data,
          onConfirmBoarded: () => _updateStatus('completed'),
        );
      case TripStatus.completed:
        return _CompletedContent(data: _data);
      case TripStatus.cancelled:
        return _CancelledContent(data: _data);
    }
  }
}

// ============================================================
// Pending — รอวันเดินทาง (น้ำเงิน)
// ============================================================
class _PendingContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onConfirmWaiting;

  const _PendingContent({
    required this.data,
    required this.onConfirmWaiting,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.confirmation_number_outlined,
            title: "การจองได้รับการยืนยัน",
            subtitle: "${data['from']} → ${data['to']}",
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          _infoRow(Icons.access_time, "เวลาเดินทาง", "${data['time']} น."),
          const SizedBox(height: 6),
          _infoRow(Icons.event_seat, "จำนวนที่นั่ง", "${data['seats']} ที่นั่ง"),
          const SizedBox(height: 6),
          _infoRow(Icons.payments, "ราคารวม", "${data['total']} บาท"),
          if ((data['note'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.note_alt, "หมายเหตุ", data['note']),
          ],
          const SizedBox(height: 16),

          // คำถาม — มารอรถหรือยัง
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "🚌  คุณมารอรถแล้วหรือยัง?",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),

          // ปุ่มยืนยัน "มารอรถแล้ว"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Row(
                      children: [
                        Icon(Icons.where_to_vote,
                            color: Color(0xFF3F6FB6), size: 24),
                        SizedBox(width: 8),
                        Text("ยืนยันการมารอรถ",
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: Text(
                      "ยืนยันว่าคุณมาถึงจุดรับรถแล้ว\n${data['from']} → ${data['to']}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("ยกเลิก",
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F6FB6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("ยืนยัน"),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  onConfirmWaiting();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text("ยืนยันแล้ว! กรุณารอรถสักครู่"),
                          ],
                        ),
                        backgroundColor: const Color(0xFF43A047),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.where_to_vote, size: 18),
              label: const Text(
                "มารอรถแล้ว",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3F6FB6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _statusBadge("รอวันเดินทาง", Icons.schedule),
        ],
      ),
    );
  }
}

// ============================================================
// Waiting — มารอรถหรือยัง? (แดง)
// ============================================================
class _WaitingContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onConfirmArrived;

  const _WaitingContent({
    required this.data,
    required this.onConfirmArrived,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.notifications_active,
            title: "รถกำลังออกเดินทาง!",
            subtitle: "${data['from']} → ${data['to']}",
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          _infoRow(Icons.flag, "ต้นทาง", data['from'] ?? '-'),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on, "ปลายทาง", data['to'] ?? '-'),
          const SizedBox(height: 6),
          _infoRow(Icons.access_time, "เวลา", "${data['time']} น."),
          const SizedBox(height: 16),

          // คำถาม
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "🚌  คุณมารอรถแล้วหรือยัง?",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),

          // ปุ่มยืนยัน "มาถึงจุดรับแล้ว"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Row(
                      children: [
                        Icon(Icons.where_to_vote,
                            color: Color(0xFFE53935), size: 24),
                        SizedBox(width: 8),
                        Text("ยืนยันถึงจุดรับรถ",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: Text(
                      "ยืนยันว่าคุณมาถึงจุดรับรถแล้ว\nกรุณารอรถสักครู่",
                      style: const TextStyle(fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("ยกเลิก",
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("ยืนยัน"),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  onConfirmArrived();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text("ยืนยันแล้ว! กรุณารอสักครู่"),
                          ],
                        ),
                        backgroundColor: const Color(0xFF43A047),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.where_to_vote, size: 18),
              label: const Text(
                "มาถึงจุดรับแล้ว",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Onboard — มารอแล้ว ถามว่าขึ้นรถแล้วหรือยัง (ส้ม)
// ============================================================
class _OnboardContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onConfirmBoarded;

  const _OnboardContent({
    required this.data,
    required this.onConfirmBoarded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.airport_shuttle,
            title: "รถมาถึงแล้ว!",
            subtitle: "${data['from']} → ${data['to']}",
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // แถบข้อมูล
          _infoRow(Icons.flag, "ต้นทาง", data['from'] ?? '-'),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on, "ปลายทาง", data['to'] ?? '-'),
          const SizedBox(height: 6),
          _infoRow(Icons.access_time, "เวลา", "${data['time']} น."),
          const SizedBox(height: 6),
          _infoRow(Icons.event_seat, "ที่นั่ง", "${data['seats']} ที่นั่ง"),
          if ((data['note'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.note_alt, "จุดรับ", data['note']),
          ],
          const SizedBox(height: 16),

          // คำถาม — ขึ้นรถแล้วหรือยัง
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "🎉  คุณขึ้นรถแล้วหรือยัง?",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),

          // ปุ่มยืนยัน "ขึ้นรถแล้ว"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Row(
                      children: [
                        Icon(Icons.directions_bus,
                            color: Color(0xFFF57C00), size: 24),
                        SizedBox(width: 8),
                        Text("ยืนยันการขึ้นรถ",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: Text(
                      "ยืนยันว่าคุณขึ้นรถแล้ว\n${data['from']} → ${data['to']}\nการจองจะสำเร็จเมื่อยืนยัน",
                      style: const TextStyle(fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("ยกเลิก",
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF57C00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("ขึ้นรถแล้ว ✓"),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  onConfirmBoarded();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text("ขึ้นรถสำเร็จ! ขอให้เดินทางปลอดภัย 🙏"),
                          ],
                        ),
                        backgroundColor: const Color(0xFF43A047),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.directions_bus, size: 18),
              label: const Text(
                "ขึ้นรถแล้ว",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFF57C00),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Completed — เดินทางเสร็จสิ้น (เขียว)
// ============================================================
class _CompletedContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CompletedContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.task_alt,
            title: "การเดินทางสำเร็จ!",
            subtitle: "${data['from']} → ${data['to']}",
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Success box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text(
                  "ขอบคุณที่ใช้บริการ!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  "ขอให้เดินทางถึงที่หมายโดยสวัสดิภาพ 🙏",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.access_time, "เวลา", "${data['time']} น."),
          const SizedBox(height: 6),
          _infoRow(Icons.payments, "ราคา", "${data['total']} บาท"),
          const SizedBox(height: 12),
          _statusBadge("เดินทางสำเร็จ", Icons.check_circle_outline),
        ],
      ),
    );
  }
}

// ============================================================
// Cancelled — ยกเลิก (เทา)
// ============================================================
class _CancelledContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CancelledContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.cancel_outlined,
            title: "การจองถูกยกเลิก",
            subtitle: "${data['from']} → ${data['to']}",
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          _infoRow(Icons.access_time, "เวลา", "${data['time']} น."),
          const SizedBox(height: 12),
          _statusBadge("ยกเลิกแล้ว", Icons.cancel_outlined),
        ],
      ),
    );
  }
}

// ============================================================
// Shared Helpers
// ============================================================
Widget _cardHeader({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                )),
            Text(subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ],
  );
}

Widget _infoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, color: Colors.white70, size: 14),
      const SizedBox(width: 6),
      Text("$label: ",
          style: const TextStyle(color: Colors.white60, fontSize: 12)),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget _statusBadge(String label, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    ),
  );
}