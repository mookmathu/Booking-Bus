import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_appbar.dart';

// ============================================================
// StationPriceService — ดึงข้อมูลจาก Firestore พร้อม cache
// ============================================================
class StationPriceService {
  static List<String>? _stations;
  static Map<String, int>? _prices;

  static Future<void> load() async {
    if (_stations != null && _prices != null) return;

    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection('config').doc('stations').get(),
      db.collection('config').doc('prices').get(),
    ]);

    _stations = List<String>.from(results[0].data()?['list'] ?? []);
    _prices = Map<String, int>.from(
      (results[1].data() ?? {}).map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      ),
    );
  }

  static List<String> get stations => _stations ?? [];

  static int getPrice(String from, String to) {
    if (from == to) return 0;
    if (_prices == null) return 60;
    final key = '$from||$to';
    if (_prices!.containsKey(key)) return _prices![key]!;
    final fromIdx = stations.indexOf(from);
    final toIdx = stations.indexOf(to);
    if (fromIdx == -1 || toIdx == -1) return 60;
    return ((fromIdx - toIdx).abs() * 10).clamp(20, 120);
  }
}

// ============================================================
// TripSeatService
//
// โครงสร้าง Firestore:
//   tripSeats/{tripId}
//     - initialSeats : int   ← สุ่มครั้งแรกของวัน
//     - date         : string ← วันที่ในรูปแบบ "dd/MM/yyyy" เพื่อ reset รายวัน
//     - createdAt    : Timestamp
//
// ที่นั่งว่างจริง = initialSeats − (ที่นั่งที่จองแล้วใน bookings)
// ============================================================
class TripSeatService {
  static const int maxSeatsPerTrip = 14;
  static final _rng = Random();

  // ── สร้าง tripId unique ต่อ 1 เที่ยว ──────────────────────
  static String buildTripId({
    required String date,
    required String time,
    required String from,
    required String to,
  }) {
    final fromKey = from.replaceAll(' ', '_');
    final toKey = to.replaceAll(' ', '_');
    return '${date}_${time}_${fromKey}_$toKey';
  }

  // ── key วันที่ (dd/MM/yyyy) ใช้เปรียบเทียบว่า reset แล้วหรือยัง ──
  static String _todayKey(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  // ── ดึง initialSeats จาก Firestore (สุ่มถ้ายังไม่มีของวันนี้) ──
  static Future<int> getOrCreateInitialSeats({
    required String tripId,
    required DateTime date,
  }) async {
    final db = FirebaseFirestore.instance;
    final ref = db.collection('tripSeats').doc(tripId);
    final todayKey = _todayKey(date);

    final snap = await ref.get();

    // ถ้ามี document แล้ว และเป็นของวันนี้ → ใช้ค่าเดิม
    if (snap.exists && snap.data()?['date'] == todayKey) {
      return (snap.data()!['initialSeats'] as num).toInt();
    }

    // ไม่มี หรือเป็นของวันก่อน → สุ่มใหม่แล้วบันทึก
    final newSeats = _rng.nextInt(maxSeatsPerTrip + 1); // 0–14
    await ref.set({
      'initialSeats': newSeats,
      'date': todayKey,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return newSeats;
  }

  // ── Stream ที่นั่งว่างแบบ real-time ─────────────────────────
  // รวม: initialSeats − ที่นั่งที่จองไปแล้ว
  static Stream<int> seatsLeftStream({
    required String tripId,
    required int initialSeats,
  }) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('tripId', isEqualTo: tripId)
        .where('status', isNotEqualTo: 'cancelled')
        .snapshots()
        .map((snap) {
      int booked = 0;
      for (final doc in snap.docs) {
        booked += ((doc.data()['seats'] ?? 1) as num).toInt();
      }
      return (initialSeats - booked).clamp(0, initialSeats);
    });
  }
}

// ============================================================
// Search Result Screen
// ============================================================
class SearchResultScreen extends StatefulWidget {
  const SearchResultScreen({super.key});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  bool _isLoading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  static List<String> _generateTimes({int startHour = 5, int endHour = 18}) {
    return [
      for (int h = startHour; h <= endHour; h++)
        '${h.toString().padLeft(2, '0')}:00',
    ];
  }

  final List<String> _times = _generateTimes(startHour: 5, endHour: 18);

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      await StationPriceService.load();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'โหลดข้อมูลไม่ได้: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year + 543;
    const weekdays = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
    return '${weekdays[d.weekday - 1]} $day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String fromStation = args['from'] ?? 'ต้นทาง';
    final String toStation = args['to'] ?? 'ปลายทาง';

    if (_isLoading) {
      return const Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(72),
          child: AppAppBar(title: 'เที่ยวรถ', subtitle: 'กำลังโหลดข้อมูล...'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: const AppAppBar(title: 'เที่ยวรถ'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() {
                  _isLoading = true;
                  _error = null;
                  _loadConfig();
                }),
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    final int ticketPrice =
        StationPriceService.getPrice(fromStation, toStation);
    final String formattedDate = _formatDate(_selectedDate);

    return Scaffold(
      appBar: const AppAppBar(
        title: 'เที่ยวรถ',
        subtitle: 'เลือกเวลาเดินทางที่ต้องการ',
      ),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // เส้นทาง
                Row(
                  children: [
                    const Icon(Icons.flag,
                        size: 16, color: Color(0xFF3F6FB6)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fromStation,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_forward,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    const Icon(Icons.location_on,
                        size: 16, color: Color(0xFFE53935)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        toStation,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // เลือกวันที่เดินทาง
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 90)),
                      locale: const Locale('th', 'TH'),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF3F6FB6),
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F6FB6).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF3F6FB6).withOpacity(0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Color(0xFF3F6FB6)),
                        const SizedBox(width: 6),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3F6FB6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down,
                            size: 18, color: Color(0xFF3F6FB6)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ราคา
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F6FB6).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payments_outlined,
                          size: 15, color: Color(0xFF3F6FB6)),
                      const SizedBox(width: 6),
                      Text(
                        'ราคาต่อที่นั่ง  $ticketPrice บาท',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3F6FB6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── รายการเที่ยวรถ ─────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _times.length,
              itemBuilder: (context, index) {
                final String time = _times[index];
                final String tripId = TripSeatService.buildTripId(
                  date: formattedDate,
                  time: time,
                  from: fromStation,
                  to: toStation,
                );
                return _VanTripCard(
                  time: time,
                  tripId: tripId,
                  from: fromStation,
                  to: toStation,
                  price: ticketPrice,
                  date: formattedDate,
                  dateRaw: _selectedDate.toIso8601String(),
                  selectedDate: _selectedDate,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Van Trip Card
// ============================================================
class _VanTripCard extends StatefulWidget {
  final String time;
  final String tripId;
  final String from;
  final String to;
  final int price;
  final String date;
  final String dateRaw;
  final DateTime selectedDate;

  const _VanTripCard({
    required this.time,
    required this.tripId,
    required this.from,
    required this.to,
    required this.price,
    required this.date,
    required this.dateRaw,
    required this.selectedDate,
  });

  @override
  State<_VanTripCard> createState() => _VanTripCardState();
}

class _VanTripCardState extends State<_VanTripCard> {
  // initialSeats จาก Firestore (สุ่มรายวัน)
  int? _initialSeats;
  bool _loadingSeats = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialSeats();
  }

  @override
  void didUpdateWidget(_VanTripCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // เมื่อเปลี่ยนวัน ให้โหลด initialSeats ใหม่
    if (oldWidget.tripId != widget.tripId) {
      setState(() {
        _initialSeats = null;
        _loadingSeats = true;
      });
      _fetchInitialSeats();
    }
  }

  Future<void> _fetchInitialSeats() async {
    try {
      final seats = await TripSeatService.getOrCreateInitialSeats(
        tripId: widget.tripId,
        date: widget.selectedDate,
      );
      if (mounted) setState(() { _initialSeats = seats; _loadingSeats = false; });
    } catch (_) {
      if (mounted) setState(() { _initialSeats = TripSeatService.maxSeatsPerTrip; _loadingSeats = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── กำลังโหลด initialSeats ──────────────────────────────
    if (_loadingSeats) {
      return _cardShell(
        child: const SizedBox(
          height: 56,
          child: Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    final int initialSeats = _initialSeats!;

    // ── real-time ที่นั่งว่าง ────────────────────────────────
    return StreamBuilder<int>(
      stream: TripSeatService.seatsLeftStream(
        tripId: widget.tripId,
        initialSeats: initialSeats,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _cardShell(
            child: const SizedBox(
              height: 56,
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        final int seatsLeft = snapshot.data ?? initialSeats;
        final bool isFull = seatsLeft == 0;
        final bool isAlmostFull = seatsLeft <= 3 && !isFull;

        return _cardShell(
          child: Row(
            children: [
              // Time box
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF3F6FB6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time,
                        size: 18, color: Color(0xFF3F6FB6)),
                    const SizedBox(height: 2),
                    Text(
                      widget.time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F6FB6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เที่ยว ${widget.time} น.',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ราคา ${widget.price} บาท / ที่นั่ง',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.event_seat,
                          size: 13,
                          color: isFull || isAlmostFull
                              ? const Color(0xFFE53935)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isFull
                              ? 'ที่นั่งเต็มแล้ว'
                              : 'ที่นั่งว่าง $seatsLeft ที่',
                          style: TextStyle(
                            fontSize: 12,
                            color: isFull || isAlmostFull
                                ? const Color(0xFFE53935)
                                : Colors.grey,
                            fontWeight: isFull || isAlmostFull
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ปุ่ม
              isFull
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'เต็มแล้ว',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F6FB6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onPressed: () => _showBookingSheet(
                        context,
                        seatsLeft: seatsLeft,
                      ),
                      child: const Text(
                        'จอง',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  void _showBookingSheet(BuildContext context, {required int seatsLeft}) {
    int seats = 1;
    final TextEditingController noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final int total = widget.price * seats;
            return ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const Text(
                          'รายละเอียดการจอง',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'เที่ยว ${widget.time} น. • ${widget.price} บาท/ที่นั่ง',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        _sheetRow(
                          icon: Icons.directions_bus,
                          iconColor: const Color(0xFF3F6FB6),
                          label: 'เส้นทาง',
                          value: '${widget.from} → ${widget.to}',
                        ),
                        const SizedBox(height: 12),
                        _sheetRow(
                          icon: Icons.calendar_today,
                          iconColor: const Color(0xFF43A047),
                          label: 'วันที่',
                          value: widget.date,
                        ),
                        const SizedBox(height: 12),
                        _sheetRow(
                          icon: Icons.access_time,
                          iconColor: const Color(0xFF43A047),
                          label: 'เวลา',
                          value: '${widget.time} น.',
                        ),
                        const SizedBox(height: 20),

                        // Seat selector
                        const Text(
                          'จำนวนที่นั่ง',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ที่นั่งว่าง $seatsLeft ที่',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                              Row(
                                children: [
                                  _circleButton(
                                    icon: Icons.remove,
                                    onTap: () {
                                      if (seats > 1) {
                                        setSheetState(() => seats--);
                                      }
                                    },
                                    enabled: seats > 1,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      '$seats',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ),
                                  _circleButton(
                                    icon: Icons.add,
                                    onTap: () {
                                      if (seats < seatsLeft) {
                                        setSheetState(() => seats++);
                                      }
                                    },
                                    enabled: seats < seatsLeft,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Note
                        const Text(
                          'หมายเหตุ / จุดรับที่ต้องการ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: noteController,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                'ระบุจุดรับปลายทางที่ต้องการ หรือข้อความเพิ่มเติม...',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFFF5F6FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Price summary
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F6FB6).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${widget.price} บาท × $seats ที่นั่ง',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                  Text(
                                    '$total บาท',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const Divider(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'ราคารวม',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  Text(
                                    '$total บาท',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3F6FB6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3F6FB6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(
                                context,
                                '/payment',
                                arguments: {
                                  'from': widget.from,
                                  'to': widget.to,
                                  'time': widget.time,
                                  'date': widget.date,
                                  'dateRaw': widget.dateRaw,
                                  'price': widget.price,
                                  'seats': seats,
                                  'total': total,
                                  'note': noteController.text.trim(),
                                  'tripId': widget.tripId,
                                },
                              );
                            },
                            child: const Text(
                              'ยืนยันการจอง',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
        );
      },
    );
  }

  Widget _sheetRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF3F6FB6) : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}