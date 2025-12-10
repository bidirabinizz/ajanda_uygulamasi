import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SayfaNotEkle extends StatefulWidget {
  final String mevcutNot;

  const SayfaNotEkle({super.key, required this.mevcutNot});

  @override
  State<SayfaNotEkle> createState() => _SayfaNotEkleState();
}

class _SayfaNotEkleState extends State<SayfaNotEkle> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.mevcutNot);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context), // Kaydetmeden çık
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {
                // Yazılan metni geri gönderiyoruz
                Navigator.pop(context, _controller.text); 
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0055FF).withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("Kaydet", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0055FF))),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarih Bilgisi
            Text(
              DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now()),
              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            
            // Başlık
            Text(
              "Bugün Nasıl Geçti?",
              style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Yazma Alanı (Tüm ekranı kaplar)
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null, // Sınırsız satır
                expands: true, // Alanı doldur
                autofocus: true, // Açılınca klavye gelsin
                style: TextStyle(fontSize: 16, color: textColor, height: 1.5),
                decoration: InputDecoration(
                  hintText: "Düşüncelerini, anılarını veya notlarını buraya dök...",
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}