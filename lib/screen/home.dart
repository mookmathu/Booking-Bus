import 'package:flutter/material.dart';
import '../widgets/app_appbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<String> stations = [
    "มหาวิทยาลัยเกษตรศาสตร์ วิทยาเขตกำแพงแสน",
    "โลตัสกำแพงแสน",
    "มหาวิทยาลัยศิลปากร",
    "เซ็นทรัลนครปฐม",
    "เซ็นทรัลศาลายา",
    "โลตัสศาลายา",
    "มหาวิทยาลัยมหิดล ศาลายา",
    "ศูนย์การแพทย์กาญจนาภิเษก",
    "สถานีขนส่งสายใต้ใหม่",
    "เมเจอร์ ปิ่นเกล้า",
    "เซ็นทรัลปิ่นเกล้า",
    "วิคตอรี่ พลาซ่า",
    "MRT บางยี่ขัน",
    "BTS พญาไท",
    "BTS อนุสาวรีย์ชัยสมรภูมิ",
    "มหาลัยราชภัฏสวนดุสิต",
    "ร.พ.ประสาทวิทยา",
    "ร.พ.รามาธิบดี",
    "ร.พ.พระมงกุฎเกล้า",
    "สถาบันมะเร็ง",
    "ร.พ.ราชวิถี",
  ];

  // ข้อมูลโปรโมชัน
  final List<Map<String, dynamic>> promotions = [
    {
      "title": "สมาชิกใหม่รับส่วนลด 10%",
      "subtitle": "ใช้โค้ด NEW10 เมื่อจองครั้งแรก",
      "color": const Color(0xFFFF8C00),
      "icon": Icons.local_offer,
    },
    {
      "title": "นักศึกษาลด 5%",
      "subtitle": "แสดงบัตรนักศึกษาเมื่อขึ้นรถ",
      "color": const Color(0xFF6A1B9A),
      "icon": Icons.school,
    },
  ];

  // ข้อมูลข่าวสาร/ประกาศ
  final List<Map<String, dynamic>> news = [
    {
      "title": "แจ้งปรับเวลาเดินรถเส้นทางกำแพงแสน - อนุสาวรีย์ชัยสมรภูมิ",
      "body": "ในวันที่ 16 มี.ค. รถเที่ยว 07:00 น. ปรับเป็น 07:30 น.",
      "date": "8 มี.ค. 2568",
      "isNew": false,
    },
    {
      "title": "ปิดให้บริการชั่วคราว วันหยุดสงกรานต์",
      "body": "งดให้บริการวันที่ 13-14 เม.ย. 2568",
      "date": "15 มี.ค. 2568",
      "isNew": true,
    },
  ];

  String? from;
  String? to;

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  late AnimationController _swapAnimController;
  late Animation<double> _swapRotation;

  @override
  void initState() {
    super.initState();
    _swapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _swapRotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _swapAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _swapAnimController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _swapStations() {
    _swapAnimController.forward(from: 0);
    setState(() {
      final tempFrom = from;
      final tempTo = to;
      final tempFromText = _fromController.text;
      final tempToText = _toController.text;
      from = tempTo;
      to = tempFrom;
      _fromController.text = tempToText;
      _toController.text = tempFromText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: "Van Booking",
        subtitle: "เดินทางวันนี้อย่างมั่นใจ",
        automaticallyImplyLeading: false,
        showNotificationAction: true,
        showProfileAction: true,
        notificationCount: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Search Card
            _buildSearchCard(),

            const SizedBox(height: 24),

            /// โปรโมชัน
            const Text(
              "โปรโมชัน",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            ...promotions.map((promo) => _buildPromoCard(promo)).toList(),

            const SizedBox(height: 24),

            /// ข่าวสาร/ประกาศ
            const Text(
              "ข่าวสาร / ประกาศ",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            ...news.map((item) => _buildNewsCard(item)).toList(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // แสดง Dialog แจ้งเตือน validation
  // ============================================================
  void _showValidationDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ไอคอนแจ้งเตือน
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF8C00),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F6FB6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "ตกลง",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3F6FB6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F6FB6).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.topLeft,
            child: Icon(Icons.directions_bus, color: Colors.white70, size: 28),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildAutocompleteField(
                      label: "ต้นทาง",
                      icon: Icons.flag,
                      controller: _fromController,
                      onSelected: (value) => setState(() => from = value),
                    ),
                    const SizedBox(height: 10),
                    _buildAutocompleteField(
                      label: "ปลายทาง",
                      icon: Icons.location_on,
                      controller: _toController,
                      onSelected: (value) => setState(() => to = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _swapStations,
                child: AnimatedBuilder(
                  animation: _swapRotation,
                  builder:
                      (context, child) => Transform.rotate(
                        angle: _swapRotation.value * 3.14159,
                        child: child,
                      ),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.swap_vert,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C4C85),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                final fromText = _fromController.text.trim();
                final toText = _toController.text.trim();

                // ยังไม่ได้กรอกเลย
                if (fromText.isEmpty && toText.isEmpty) {
                  _showValidationDialog(context,
                      "กรุณากรอกข้อมูล", "โปรดระบุต้นทางและปลายทางก่อนค้นหา");
                  return;
                }
                if (fromText.isEmpty) {
                  _showValidationDialog(context,
                      "ยังไม่ได้ระบุต้นทาง", "กรุณาเลือกสถานีต้นทางก่อนค้นหา");
                  return;
                }
                if (toText.isEmpty) {
                  _showValidationDialog(context,
                      "ยังไม่ได้ระบุปลายทาง", "กรุณาเลือกสถานีปลายทางก่อนค้นหา");
                  return;
                }
                // พิมพ์เองแต่ไม่ตรงกับสถานีจริง
                if (!stations.contains(fromText)) {
                  _showValidationDialog(context,
                      "ไม่พบสถานีต้นทาง", "\"$fromText\"\nไม่มีในระบบ กรุณาเลือกจากรายการที่แนะนำ");
                  return;
                }
                if (!stations.contains(toText)) {
                  _showValidationDialog(context,
                      "ไม่พบสถานีปลายทาง", "\"$toText\"\nไม่มีในระบบ กรุณาเลือกจากรายการที่แนะนำ");
                  return;
                }
                if (fromText == toText) {
                  _showValidationDialog(context,
                      "ต้นทางและปลายทางเหมือนกัน", "กรุณาเลือกสถานีที่แตกต่างกัน");
                  return;
                }
                Navigator.pushNamed(
                  context,
                  '/search',
                  arguments: {"from": fromText, "to": toText},
                );
              },
              child: const Text(
                "ค้นหารถ",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (promo["color"] as Color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              promo["icon"] as IconData,
              color: promo["color"] as Color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  promo["subtitle"],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              if (item["isNew"] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "ใหม่",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item["body"],
            style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                item["date"],
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutocompleteField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required ValueChanged<String> onSelected,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue text) {
        if (text.text.isEmpty) return stations;
        return stations.where(
          (s) => s.toLowerCase().contains(text.text.toLowerCase()),
        );
      },
      onSelected: (value) {
        onSelected(value);
        controller.text = value;
      },
      fieldViewBuilder: (
        context,
        autoController,
        focusNode,
        onEditingComplete,
      ) {
        if (controller.text != autoController.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            autoController.text = controller.text;
            autoController.selection = TextSelection.collapsed(
              offset: controller.text.length,
            );
          });
        }
        return TextField(
          controller: autoController,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(fontSize: 13),
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
    );
  }
}