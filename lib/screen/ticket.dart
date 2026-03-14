import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_appbar.dart';

// ============================================================
// Model — แปลงจาก Firestore document
// ============================================================
class BusTicket {
  final String id;
  final String userName;
  final String from;
  final String to;
  final String time;
  final String paymentMethod;
  final int seats;
  final int total;
  final String note;
  final String status;     
  final DateTime? createdAt;

  const BusTicket({
    required this.id,
    required this.userName,
    required this.from,
    required this.to,
    required this.time,
    required this.paymentMethod,
    required this.seats,
    required this.total,
    required this.note,
    required this.status,
    this.createdAt,
  });

  factory BusTicket.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BusTicket(
      id:            doc.id,
      userName:      d['userName'] ?? 'ผู้ใช้งาน',
      from:          d['from'] ?? '-',
      to:            d['to'] ?? '-',
      time:          d['time'] ?? '-',
      paymentMethod: d['paymentMethod'] ?? '-',
      seats:         (d['seats'] ?? 1) as int,
      total:         (d['total'] ?? 0) as int,
      note:          d['note'] ?? '',
      status:        d['status'] ?? 'confirmed',
      createdAt:     (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  String get shortId =>
      id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  String get formattedDate {
    if (createdAt == null) return '-';
    return '${createdAt!.day.toString().padLeft(2, '0')}/'
        '${createdAt!.month.toString().padLeft(2, '0')}/'
        '${createdAt!.year + 543}';
  }
}

// ============================================================
// Ticket List Screen
// ============================================================
class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppAppBar(
        title: "BUS",
        subtitle: "ตั๋วการเดินทางของคุณ",
        automaticallyImplyLeading: Navigator.canPop(context),
      ),
      body: user == null
          ? _buildNotLoggedIn()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3F6FB6)),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          'เกิดข้อผิดพลาด\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return _buildEmpty();

                final tickets =
                    docs.map((d) => BusTicket.fromFirestore(d)).toList()
                      ..sort((a, b) {
                        if (a.createdAt == null) return 1;
                        if (b.createdAt == null) return -1;
                        return b.createdAt!.compareTo(a.createdAt!);
                      });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketDetailScreen(ticket: ticket),
                        ),
                      ),
                      child: _TicketCard(ticket: ticket),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmpty() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined,
                size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text("ยังไม่มีตั๋ว",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            SizedBox(height: 8),
            Text("จองตั๋วได้ที่หน้าหลักเลยค่ะ",
                style: TextStyle(fontSize: 13, color: Colors.grey)),
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
}

// ============================================================
// Ticket Card Widget
// ============================================================
class _TicketCard extends StatelessWidget {
  final BusTicket ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = ticket.status == 'cancelled';

    return Opacity(
      opacity: isCancelled ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 160,
        child: Row(
          children: [
            // ── Left blue section ──────────────────────────
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCancelled
                        ? [Colors.grey.shade500, Colors.grey.shade700]
                        : const [Color(0xFF3F6FB6), Color(0xFF2C4C85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 5),
                        const Text("Bus Ticket",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(ticket.shortId,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 9)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ticket.userName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        _routeRow(Icons.flag, ticket.from),
                        _routeRow(Icons.location_on, ticket.to),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white54, size: 10),
                        const SizedBox(width: 3),
                        Text(ticket.formattedDate,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10)),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time,
                            color: Colors.white54, size: 10),
                        const SizedBox(width: 3),
                        Text("${ticket.time} น.",
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCancelled
                                ? Colors.red.withOpacity(0.25)
                                : Colors.green.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCancelled ? "ยกเลิก" : "ยืนยันแล้ว",
                            style: TextStyle(
                              color: isCancelled
                                  ? Colors.red.shade200
                                  : Colors.green.shade200,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Notch divider ─────────────────────────────
            SizedBox(
              width: 20,
              child: CustomPaint(
                painter: _NotchPainter(
                    bgColor: isCancelled
                        ? Colors.grey.shade700
                        : const Color(0xFF2C4C85)),
                child: const SizedBox(height: double.infinity),
              ),
            ),

            // ── Right QR section ──────────────────────────
            Container(
              width: 90,
              decoration: BoxDecoration(
                color: isCancelled
                    ? Colors.grey.shade700
                    : const Color(0xFF2C4C85),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/QRBooking.png',
                      width: 55,
                      height: 55,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text("QR Code",
                      style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 11),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Notch Painter
// ============================================================
class _NotchPainter extends CustomPainter {
  final Color bgColor;
  _NotchPainter({required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(
        Rect.fromLTWH(0, 10, size.width, size.height - 20), bgPaint);

    double y = 14;
    while (y < size.height - 14) {
      canvas.drawLine(Offset(size.width / 2, y),
          Offset(size.width / 2, y + 5), dashPaint);
      y += 9;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ============================================================
// Ticket Detail Screen — พร้อมปุ่มยกเลิกการจอง
// ============================================================
class TicketDetailScreen extends StatefulWidget {
  final BusTicket ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  bool _cancelling = false;

  // ── ยกเลิกการจอง ─────────────────────────────────────────
  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text("ยืนยันการยกเลิก",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("คุณต้องการยกเลิกการจองนี้ใช่หรือไม่?",
                style: TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "เส้นทาง: ${widget.ticket.from} → ${widget.ticket.to}\n"
                      "เวลา: ${widget.ticket.time} น.",
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("ไม่ยกเลิก",
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("ยืนยันยกเลิก"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancelling = true);

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.ticket.id)
          .update({'status': 'cancelled'});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("ยกเลิกการจองเรียบร้อยแล้ว"),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // กลับหน้ารายการตั๋ว
      Navigator.pop(context);
    } catch (e) {
      setState(() => _cancelling = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("เกิดข้อผิดพลาด: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final bool isCancelled = ticket.status == 'cancelled';

    return Scaffold(
      appBar: const AppAppBar(title: "BUS", subtitle: "รายละเอียดตั๋ว"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── QR Card ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: Image(
                        image:
                            const AssetImage('assets/images/QRBooking.png'),
                        fit: BoxFit.contain,
                        color: isCancelled ? Colors.grey : null,
                        colorBlendMode:
                            isCancelled ? BlendMode.saturation : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ticket.shortId,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isCancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Text(
                        "ตั๋วนี้ถูกยกเลิกแล้ว",
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    )
                  else ...[
                    const Text(
                      "โปรดยื่น QR Code นี้ให้กับคนขับรถตู้",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF2C3E50)),
                      textAlign: TextAlign.center,
                    ),
                    const Text("เพื่อยืนยันตัวตน",
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Booking Detail Card ─────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "รายละเอียดการจอง",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3F6FB6),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCancelled
                              ? Colors.red.withOpacity(0.1)
                              : const Color(0xFF43A047).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCancelled ? "ยกเลิกแล้ว" : "ยืนยันแล้ว",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCancelled
                                ? Colors.red
                                : const Color(0xFF43A047),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _detailRow("ชื่อผู้จอง", ticket.userName),
                  _detailRow("ต้นทาง", ticket.from),
                  _detailRow("ปลายทาง", ticket.to),
                  _detailRow("จำนวนที่นั่ง", "${ticket.seats} ที่นั่ง"),
                  _detailRow("วันที่จอง", ticket.formattedDate),
                  _detailRow("เวลา", "${ticket.time} น."),
                  _detailRow("การชำระเงิน", ticket.paymentMethod),
                  _detailRow("ราคารวม", "${ticket.total} บาท"),
                  if (ticket.note.isNotEmpty)
                    _detailRow("หมายเหตุ", ticket.note),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.airport_shuttle,
                      size: 64,
                      color: const Color(0xFF3F6FB6).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── ปุ่มยกเลิกการจอง ────────────────────────────
            if (!isCancelled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _cancelling ? null : _cancelBooking,
                  icon: _cancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.red, strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined, size: 20),
                  label: Text(
                    _cancelling ? "กำลังยกเลิก..." : "ยกเลิกการจอง",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            if (isCancelled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: Text(
                  "การจองนี้ถูกยกเลิกแล้ว",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}