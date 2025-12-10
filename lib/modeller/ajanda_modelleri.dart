import 'package:flutter/material.dart';

// YENİ: Kategori Modeli
class Kategori {
  final int id;
  final String baslik;
  final int? ustKategoriId;
  final Color renk; // Renk kodunu Color objesine çevireceğiz

  Kategori({required this.id, required this.baslik, this.ustKategoriId, required this.renk});

  factory Kategori.fromJson(Map<String, dynamic> json) {
    // Renk kodu null ise varsayılan mavi yapalım
    String colorString = json['renk_kodu'] ?? '0xFF2196F3';
    return Kategori(
      id: json['id'],
      baslik: json['baslik'],
      ustKategoriId: json['ust_kategori_id'],
      renk: Color(int.parse(colorString)),
    );
  }
}

// GÜNCELLENDİ: Etkinlik Modeli
class Etkinlik {
  final int id;
  final int kullaniciId;
  final String baslik;
  final String? aciklama;
  final DateTime baslangicTarihi;
  final String oncelik;
  bool tamamlandiMi;
  final int? kategoriId; // YENİ: Kategori ID'si eklendi

  Etkinlik({
    required this.id,
    required this.kullaniciId,
    required this.baslik,
    this.aciklama,
    required this.baslangicTarihi,
    this.oncelik = 'Orta',
    this.tamamlandiMi = false,
    this.kategoriId, // YENİ
  });

  factory Etkinlik.fromJson(Map<String, dynamic> json) {
    return Etkinlik(
      id: json['id'],
      kullaniciId: json['kullanici_id'],
      baslik: json['baslik'],
      aciklama: json['aciklama'],
      baslangicTarihi: DateTime.parse(json['baslangic_tarihi']),
      oncelik: json['oncelik_duzeyi'] ?? 'Orta',
      tamamlandiMi: json['tamamlandi_mi'] == 1,
      kategoriId: json['kategori_id'], // YENİ
    );
  }
}

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
      email: json['eposta'], 
      unvan: json['unvan'],
    );
  }
}