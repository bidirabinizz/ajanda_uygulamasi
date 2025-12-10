class Kullanici {
  final int id;
  final String adSoyad;
  final String email;
  final String? unvan;

  Kullanici({required this.id, required this.adSoyad, required this.email, this.unvan});

  factory Kullanici.fromJson(Map<String, dynamic> json) {
    return Kullanici(
      id: json['id'],
      adSoyad: json['ad_soyad'],
      email: json['eposta'], // Backend'den 'eposta' geliyor
      unvan: json['unvan'],
    );
  }
}

class Etkinlik {
  final int id;
  final int kullaniciId;
  final String baslik;
  final String? aciklama;
  final DateTime baslangicTarihi;
  final String oncelik;
  bool tamamlandiMi;

  Etkinlik({
    required this.id,
    required this.kullaniciId,
    required this.baslik,
    this.aciklama,
    required this.baslangicTarihi,
    this.oncelik = 'Orta',
    this.tamamlandiMi = false,
  });

  factory Etkinlik.fromJson(Map<String, dynamic> json) {
    return Etkinlik(
      id: json['id'],
      kullaniciId: json['kullanici_id'],
      baslik: json['baslik'],
      aciklama: json['aciklama'],
      // MySQL tarihi string gelir, bunu DateTime'a çeviriyoruz
      baslangicTarihi: DateTime.parse(json['baslangic_tarihi']),
      oncelik: json['oncelik_duzeyi'] ?? 'Orta',
      // MySQL'de 1/0, Flutter'da true/false
      tamamlandiMi: json['tamamlandi_mi'] == 1,
    );
  }
}