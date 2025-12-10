import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Web/Mobil ayrımı için gerekli
import '../modeller/ajanda_modelleri.dart';

class ApiService {
  // DİKKAT: Buraya cmd'den bulduğun IPv4 adresini yazmalısın!
  // Telefonunun ve bilgisayarının aynı Wi-Fi ağında olduğundan emin ol.
  static const String bilgisayarIpAdresi = '127.0.0.1';

  static String get baseUrl {
    if (kIsWeb) {
      // Web tarayıcıda çalışıyorsa localhost kullanılır
      return 'http://localhost:3000/api';
    } else {
      // Telefondan test ediyorsan bilgisayarının IP'sine bağlanır
      return 'http://$bilgisayarIpAdresi:3000/api';
    }
  }

  // --- AUTH ---
  
  // Kayıt Ol
  Future<bool> register(String adSoyad, String email, String password, String unvan) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ad_soyad': adSoyad,
          'eposta': email,
          'sifre': password,
          'unvan': unvan,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Register Hatası: $e");
      return false;
    }
  }

  // Giriş Yap
  // Başarılıysa User objesi, değilse null döner
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eposta': email,
          'sifre': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // {message: ..., user: {...}}
      }
      return null;
    } catch (e) {
      print("Login Hatası: $e");
      return null;
    }
  }

  // --- ETKİNLİKLER ---

  // Listele
  Future<List<Etkinlik>> getEvents(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events/$userId'));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Etkinlik.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Get Events Hatası: $e");
      return [];
    }
  }

  // Ekle
  Future<bool> addEvent(int userId, String baslik, String aciklama, DateTime tarih, String oncelik) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullanici_id': userId,
          'baslik': baslik,
          'aciklama': aciklama,
          'baslangic_tarihi': tarih.toIso8601String(), // Tarihi ISO formatında gönder
          'oncelik_duzeyi': oncelik
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Add Event Hatası: $e");
      return false;
    }
  }
  
  // Güncelle
  Future<bool> updateEvent(int eventId, String baslik, String aciklama, DateTime tarih, String oncelik) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'baslik': baslik,
          'aciklama': aciklama,
          'baslangic_tarihi': tarih.toIso8601String(),
          'oncelik_duzeyi': oncelik
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Event Hatası: $e");
      return false;
    }
  }

  // Durum Güncelle (Tamamlandı/Tamamlanmadı)
  Future<bool> toggleEventStatus(int eventId, bool status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/$eventId/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tamamlandi_mi': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Sil
  Future<bool> deleteEvent(int eventId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/events/$eventId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}