import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'api_servisi.dart';

class BildirimServisi {
  static final BildirimServisi _instance = BildirimServisi._internal();
  factory BildirimServisi() => _instance;
  BildirimServisi._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _timer;

  // Başlatma Ayarları
  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS Ayarları
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(settings);
  }

  // --- PERİYODİK KONTROLÜ BAŞLAT ---
  void baslat(int userId) {
    _timer?.cancel(); // Varsa eskisini durdur
    
    // 10 saniyede bir kontrol et
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _yeniBildirimleriKontrolEt(userId);
    });
    print("🔔 Bildirim servisi başlatıldı (Kullanıcı: $userId)");
  }

  void durdur() {
    _timer?.cancel();
    print("🔕 Bildirim servisi durduruldu.");
  }

  // API'den sorgulama yap
  Future<void> _yeniBildirimleriKontrolEt(int userId) async {
    print("⏳ Bildirim kontrol ediliyor... Kullanıcı: $userId"); // <-- BUNU EKLE
    try {
      // DÜZELTME: Artık ApiService.baseUrl kullanıyoruz.
      // Bu, ApiService'de tanımladığın 'http://127.0.0.1:3000/api' adresini çeker.
      final uri = Uri.parse('${ApiService.baseUrl}/notifications/unread/$userId');
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> bildirimler = jsonDecode(response.body);

        for (var bildirim in bildirimler) {
          // 1. Telefonda bildirimi göster
          await _bildirimGoster(
            id: bildirim['id'],
            title: bildirim['baslik'],
            body: bildirim['mesaj'],
          );

          // 2. Veritabanında "okundu" olarak işaretle
          // Yine ApiService.baseUrl kullanıyoruz
          await http.put(Uri.parse('${ApiService.baseUrl}/notifications/${bildirim['id']}/read'));
        }
      }
    } catch (e) {
      // Bağlantı hatası olursa konsola basar (artık timeout yerine connection refused alabilirsin eğer reverse yapmazsan)
      print("Bildirim hatası: $e");
    }
  }

  // Ekrana bildirim basan fonksiyon
  Future<void> _bildirimGoster({required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ajanda_channel', 
      'Ajanda Bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _notificationsPlugin.show(id, title, body, details);
  }
}