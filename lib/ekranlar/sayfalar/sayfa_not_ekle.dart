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
  
  // Örnek etiket listesi (İstersen veritabanından da çekebilirsin)
  final List<String> _tumEtiketler = [
    '#mutlu', '#yorgun', '#heyecanlı', '#hüzünlü', 
    '#iş', '#okul', '#spor', '#gezi', '#aile', 
    '#arkadaşlar', '#film', '#kitap', '#yemek'
  ];
  
  // O an gösterilecek öneriler
  List<String> _onerilenEtiketler = [];
  bool _etiketModu = false;
  String _arananEtiket = "";
  int _etiketBaslangicIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.mevcutNot);
    _controller.addListener(_metinDegisti);
  }

  void _metinDegisti() {
    String text = _controller.text;
    TextSelection selection = _controller.selection;
    
    // İmleç pozisyonunu kontrol et (Hata almamak için)
    if (selection.baseOffset < 0) return;

    // İmlecin solundaki metni al
    String cursorOncesi = text.substring(0, selection.baseOffset);
    
    // Son kelimeyi veya karakter grubunu bul
    int sonBosluk = cursorOncesi.lastIndexOf(' ');
    String sonKelime = "";
    
    if (sonBosluk != -1) {
      sonKelime = cursorOncesi.substring(sonBosluk + 1);
      _etiketBaslangicIndex = sonBosluk + 1;
    } else {
      sonKelime = cursorOncesi;
      _etiketBaslangicIndex = 0;
    }

    // Eğer son kelime '#' ile başlıyorsa etiket modunu aç
    if (sonKelime.startsWith('#')) {
      setState(() {
        _etiketModu = true;
        _arananEtiket = sonKelime;
        // Filtreleme yap
        _onerilenEtiketler = _tumEtiketler
            .where((etiket) => etiket.toLowerCase().contains(_arananEtiket.toLowerCase()))
            .toList();
      });
    } else {
      setState(() {
        _etiketModu = false;
        _onerilenEtiketler = [];
      });
    }
  }

  void _etiketSec(String secilenEtiket) {
    String text = _controller.text;
    
    // Eski yarım etiketi sil ve yenisini ekle
    String yeniMetin = text.replaceRange(
      _etiketBaslangicIndex, 
      _controller.selection.baseOffset, 
      "$secilenEtiket "
    );

    _controller.text = yeniMetin;
    
    // İmleci etiketten sonraya taşı
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _etiketBaslangicIndex + secilenEtiket.length + 1)
    );

    setState(() {
      _etiketModu = false;
      _onerilenEtiketler = [];
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_metinDegisti);
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
          onPressed: () => Navigator.pop(context), 
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {
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
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarih Bilgisi
                  Text(
                    DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now()),
                    style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  
                  // Başlık
                  Text(
                    "Bugün Nasıl Geçti?",
                    style: TextStyle(
                      color: textColor, 
                      fontSize: 28, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Yazma Alanı
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null, 
                      expands: true, 
                      style: TextStyle(fontSize: 16, color: textColor, height: 1.5),
                      decoration: InputDecoration(
                        hintText: "Düşüncelerini buraya yaz... (Etiket için # kullan)",
                        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // ETİKET ÖNERİ ÇUBUĞU (Klavye üstünde çıkar)
          if (_etiketModu && _onerilenEtiketler.isNotEmpty)
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2)))
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _onerilenEtiketler.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 8, bottom: 8),
                    child: ActionChip(
                      label: Text(_onerilenEtiketler[index]),
                      backgroundColor: const Color(0xFF0055FF).withOpacity(0.1),
                      labelStyle: const TextStyle(color: Color(0xFF0055FF), fontWeight: FontWeight.bold),
                      onPressed: () => _etiketSec(_onerilenEtiketler[index]),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}