import 'package:flutter/material.dart';

class Kategori {
  final int id;
  final String baslik;
  final String renkKodu;
  final String userId;

  Kategori({
    required this.id, 
    required this.baslik, 
    required this.renkKodu, 
    required this.userId
  });

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(
      id: json['id'] ?? 0,
      baslik: json['baslik'] ?? "",
      renkKodu: json['renk_kodu'] ?? "0xFF000000",
      userId: json['user_id']?.toString() ?? "",
    );
  }

  // Eksik olan renk getter'ı eklendi
  Color get renk {
    try {
      if (renkKodu.startsWith("0x")) {
        return Color(int.parse(renkKodu));
      }
      return Colors.blue; 
    } catch (e) {
      return Colors.blue;
    }
  }
}

class Etkinlik {
  final int id;
  final String baslik;
  final String? aciklama;
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final String kategori;
  final int? kategoriId;
  final String oncelik;
  bool tamamlandiMi;
  final String userId;

  Etkinlik({
    required this.id,
    required this.baslik,
    this.aciklama,
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.kategori,
    this.kategoriId,
    required this.oncelik,
    this.tamamlandiMi = false,
    required this.userId,
  });

  factory Etkinlik.fromJson(Map<String, dynamic> json) {
    return Etkinlik(
      id: json['id'] ?? 0,
      baslik: json['baslik'] ?? "", // Boş gelirse hata verme, boş string yap
      aciklama: json['aciklama'],
      // --- SAAT FARKI ÇÖZÜMÜ BURADA ---
      // .toLocal() ekleyerek sunucudan gelen saati Türkiye saatine çeviriyoruz
      baslangicTarihi: DateTime.tryParse(json['baslangic_tarihi'] ?? "")?.toLocal() ?? DateTime.now(),
      bitisTarihi: DateTime.tryParse(json['bitis_tarihi'] ?? "")?.toLocal() ?? DateTime.now(),
      kategori: json['kategori_adi'] ?? 'Genel',
      kategoriId: json['kategori_id'],
      oncelik: json['oncelik_duzeyi'] ?? json['oncelik'] ?? "Orta", // Backend alan adı kontrolü
      tamamlandiMi: json['tamamlandi_mi'] == 1 || json['tamamlandi_mi'] == true,
      userId: json['user_id']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baslik': baslik,
      'aciklama': aciklama,
      'baslangic_tarihi': baslangicTarihi.toIso8601String(),
      'bitis_tarihi': bitisTarihi.toIso8601String(),
      'kategori_id': kategoriId,
      'oncelik': oncelik,
      'tamamlandi_mi': tamamlandiMi,
      'user_id': userId,
    };
  }
}

class GunlukNot {
  final int? id;
  final int userId;
  final DateTime tarih;
  final String notIcerik;
  final int duyguDurumu; 

  GunlukNot({
    this.id,
    required this.userId,
    required this.tarih,
    this.notIcerik = "",
    this.duyguDurumu = 0, 
  });

  factory GunlukNot.fromJson(Map<String, dynamic> json) {
    return GunlukNot(
      id: json['id'],
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      tarih: DateTime.tryParse(json['tarih'] ?? "")?.toLocal() ?? DateTime.now(), // Burada da saat düzeltmesi
      notIcerik: json['not_icerik'] ?? "",
      duyguDurumu: json['duygu_durumu'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'tarih': tarih.toIso8601String().substring(0, 10), 
      'not_icerik': notIcerik,
      'duygu_durumu': duyguDurumu,
    };
  }
}