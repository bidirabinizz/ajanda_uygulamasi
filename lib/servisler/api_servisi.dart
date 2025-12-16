import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; 
import '../modeller/ajanda_modelleri.dart';

class ApiService {
  // KYK/Üniversite ağında olduğun için TEK ÇAREN bu adresi kullanmak.
  // Ama önce terminalden 'adb reverse tcp:3000 tcp:3000' komutunu çalıştırman şart!
  static const String bilgisayarIpAdresi = '127.0.0.1';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else {
      return 'http://$bilgisayarIpAdresi:3000/api';
    }
  }

  // --- AUTH ---
  
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

   Future<Map<String, dynamic>> login(String email, String password) async {
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
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'userId': data['user']['id'],
          'userName': data['user']['ad_soyad'],
          'role': data['user']['rol'] ?? 'user', // Backend'den 'rol' gelmeli, yoksa 'user' varsay
        };
      } else {
        return {'success': false, 'message': 'Giriş başarısız.'};
      }
    } catch (e) {
      print("Login Hatası: $e");
      return {'success': false, 'message': 'Bağlantı hatası: $e'};
    }
  }

  // --- KATEGORİLER ---

  Future<List<Kategori>> getCategories(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories/$userId'));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Kategori.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Get Categories Hatası: $e");
      return [];
    }
  }

  Future<bool> addCategory(int userId, String baslik, int? ustKategoriId, String renkKodu) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullanici_id': userId,
          'baslik': baslik,
          'ust_kategori_id': ustKategoriId,
          'renk_kodu': renkKodu
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Add Category Hatası: $e");
      return false;
    }
  }

  Future<bool> updateCategory(int catId, String baslik, String renkKodu) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$catId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'baslik': baslik,
          'renk_kodu': renkKodu
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Category Hatası: $e");
      return false;
    }
  }

  Future<bool> deleteCategory(int catId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/categories/$catId'));
      return response.statusCode == 200;
    } catch (e) {
      print("Delete Category Hatası: $e");
      return false;
    }
  }

  // --- ETKİNLİKLER ---

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

  Future<bool> addEvent(int userId, String baslik, String aciklama, DateTime tarih, String oncelik, {int? kategoriId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullanici_id': userId,
          'baslik': baslik,
          'aciklama': aciklama,
          'baslangic_tarihi': tarih.toIso8601String(),
          'oncelik_duzeyi': oncelik,
          'kategori_id': kategoriId
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Add Event Hatası: $e");
      return false;
    }
  }
  
  Future<bool> updateEvent(int eventId, String baslik, String aciklama, DateTime tarih, String oncelik, {int? kategoriId}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'baslik': baslik,
          'aciklama': aciklama,
          'baslangic_tarihi': tarih.toIso8601String(),
          'oncelik_duzeyi': oncelik,
          'kategori_id': kategoriId
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Event Hatası: $e");
      return false;
    }
  }

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

  Future<bool> deleteEvent(int eventId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/events/$eventId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

   // --- YENİ: GÜNLÜK NOT ve DUYGU İŞLEMLERİ ---

  // Belirli bir günün notunu getir
  Future<GunlukNot?> getDailyNote(int userId, DateTime date) async {
    try {
      // Tarihi YYYY-MM-DD formatına çevir
      String formattedDate = date.toIso8601String().substring(0, 10);
      final response = await http.get(Uri.parse('$baseUrl/daily-notes/$userId/$formattedDate'));
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body != null) {
          return GunlukNot.fromJson(body);
        }
      }
      return null;
    } catch (e) {
      print("API Hatası (getDailyNote): $e");
      return null;
    }
  }

  // Günlük notu veya duyguyu kaydet (Varsa günceller, yoksa ekler - Upsert)
  Future<bool> saveDailyNote(GunlukNot note) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/daily-notes'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(note.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("API Hatası (saveDailyNote): $e");
      return false;
    }
  }
}