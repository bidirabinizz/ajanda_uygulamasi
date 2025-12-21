import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // User ID almak için
import 'package:permission_handler/permission_handler.dart'; // YENİ: İzin kontrolü için
import '../../servisler/tema_yoneticisi.dart'; 
import 'sayfa_kategori_yonetimi.dart'; // Kategori yönetimi sayfası
import '../../servisler/bildirim_servisi.dart'; // YENİ: Bildirim servisi

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// WidgetsBindingObserver ekledik: Kullanıcı ayarlara gidip geri gelirse durumu kontrol etmek için
class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _isDarkLocal = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Uygulama durumunu dinle
    _isDarkLocal = TemaYoneticisi().isDarkMode;
    _ayarlariYukle(); // Kayıtlı ayarları ve gerçek izin durumunu çek
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Dinlemeyi bırak
    super.dispose();
  }

  // Kullanıcı uygulamayı alta atıp (ayarlara gidip) geri döndüğünde çalışır
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _gercekIzinDurumunuKontrolEt();
    }
  }

  // --- AYARLARI YÜKLE ---
  Future<void> _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    });
    // Veritabanında açık olsa bile, telefondan izin kapalıysa kapalı göster
    await _gercekIzinDurumunuKontrolEt();
  }

  // --- TELEFONUN GERÇEK İZİN DURUMUNA BAK ---
  Future<void> _gercekIzinDurumunuKontrolEt() async {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        setState(() => _notificationsEnabled = false);
      }
    } else if (status.isGranted) {
       // İzin verildiyse ve bizde de açıksa senkronize kalsın
       final prefs = await SharedPreferences.getInstance();
       bool userPref = prefs.getBool('notifications_enabled') ?? true;
       if (userPref && mounted) {
          setState(() => _notificationsEnabled = true);
       }
    }
  }

  // --- BİLDİRİM SWITCH MANTIĞI (Entegre Edilen Kısım) ---
  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (value) {
      // --- AÇMAYA ÇALIŞIYOR ---
      var status = await Permission.notification.status;

      if (status.isDenied) {
        // Hiç sorulmamışsa izin iste
        status = await Permission.notification.request();
      }

      if (status.isGranted) {
        // İzin Verildi -> Aç ve Servisi Başlat
        setState(() => _notificationsEnabled = true);
        await prefs.setBool('notifications_enabled', true);
        
        if (userId != null) {
          BildirimServisi().baslat(userId);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bildirimler açıldı ✅")));
      
      } else if (status.isPermanentlyDenied) {
        // Kullanıcı "Bir daha sorma" demiş -> Ayarlara gönder
        _izinDialogGoster();
        // Switch'i geri kapat (Çünkü henüz açamadı)
        setState(() => _notificationsEnabled = false);
      } else {
        // İzin vermedi
        setState(() => _notificationsEnabled = false);
      }
    } else {
      // --- KAPATMAYA ÇALIŞIYOR ---
      setState(() => _notificationsEnabled = false);
      await prefs.setBool('notifications_enabled', false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bildirimler kapatıldı 🔕")));
    }
  }

  // --- İZİN DİYALOG PENCERESİ ---
  void _izinDialogGoster() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;

        return AlertDialog(
          backgroundColor: cardColor,
          title: Text("İzin Gerekli", style: TextStyle(color: textColor)),
          content: Text("Bildirim gönderebilmemiz için ayarlardan izin vermeniz gerekiyor.", style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings(); // BENİ AYARLARA GÖTÜR
              },
              child: const Text("Ayarlara Git"),
            ),
          ],
        );
      },
    );
  }

  // Kategoriler sayfasına gitmek için yardımcı fonksiyon
  Future<void> _navigateToCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CategoryManagementScreen(userId: userId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final temaYoneticisi = TemaYoneticisi();
    
    // --- TEMA AYARLARI ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Renkleri temaya göre seçiyoruz
    final scaffoldColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final sectionTitleColor = isDark ? Colors.grey[400] : Colors.grey;
    final iconBgColor = isDark ? Colors.white.withOpacity(0.1) : null; 
    final dividerColor = isDark ? Colors.grey[800] : Colors.grey[200];

    return Scaffold(
      backgroundColor: scaffoldColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Ayarlar", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BÖLÜM 1: GENEL ---
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 10),
              child: Text("GENEL", style: TextStyle(color: sectionTitleColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardColor, 
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: "Karanlık Mod",
                    icon: Icons.dark_mode_outlined,
                    iconColor: Colors.purple,
                    iconBgColor: iconBgColor,
                    textColor: textColor,
                    value: _isDarkLocal, 
                    onChanged: (val) async {
                      setState(() {
                        _isDarkLocal = val;
                      });
                      await Future.delayed(const Duration(milliseconds: 300));
                      temaYoneticisi.temayiDegistir(val); 
                    },
                  ),
                  Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),
                  
                  // --- GÜNCELLENEN BİLDİRİM SWITCH'İ ---
                  _buildSwitchTile(
                    title: "Bildirimler",
                    icon: Icons.notifications_outlined,
                    iconColor: Colors.blue,
                    iconBgColor: iconBgColor,
                    textColor: textColor,
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications, // Yeni mantığı buraya bağladık
                  ),
                  
                  Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),
                  _buildSwitchTile(
                    title: "Uygulama Sesleri",
                    icon: Icons.volume_up_outlined,
                    iconColor: Colors.orange,
                    iconBgColor: iconBgColor,
                    textColor: textColor,
                    value: _soundEnabled,
                    onChanged: (val) async {
                       setState(() => _soundEnabled = val);
                       final prefs = await SharedPreferences.getInstance();
                       await prefs.setBool('sound_enabled', val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- BÖLÜM 2: İÇERİK YÖNETİMİ ---
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 10),
              child: Text("İÇERİK YÖNETİMİ", style: TextStyle(color: sectionTitleColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildNavTile(
                    title: "Kategorilerim",
                    icon: Icons.category_outlined,
                    iconColor: Colors.deepOrange, 
                    iconBgColor: iconBgColor,
                    textColor: textColor,
                    onTap: _navigateToCategories,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- BÖLÜM 3: HESAP & GÜVENLİK ---
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 10),
              child: Text("HESAP & GÜVENLİK", style: TextStyle(color: sectionTitleColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildNavTile(
                    title: "Şifre Değiştir",
                    icon: Icons.lock_outline,
                    iconColor: Colors.green,
                    iconBgColor: iconBgColor,
                    textColor: textColor,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yakında eklenecek!")));
                    },
                  ),
                  Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),
                  _buildNavTile(
                    title: "Gizlilik Politikası",
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Colors.teal,
                    iconBgColor: iconBgColor,
                    textColor: textColor,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- BÖLÜM 4: TEHLİKELİ BÖLGE ---
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
                title: const Text("Hesabı Sil", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: cardColor, 
                      title: Text("Hesabı Sil", style: TextStyle(color: textColor)),
                      content: Text("Hesabını ve tüm verilerini kalıcı olarak silmek istediğine emin misin? Bu işlem geri alınamaz.", style: TextStyle(color: textColor)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç", style: TextStyle(color: Colors.grey))),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            // Hesabı silme işlemleri buraya
                          },
                          child: const Text("Sil", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 40),
            const Center(child: Text("Versiyon 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  // Yardımcı Widget: Switch
  Widget _buildSwitchTile({
    required String title, 
    required IconData icon, 
    required Color iconColor, 
    Color? iconBgColor, 
    required bool value, 
    required Function(bool) onChanged,
    required Color textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBgColor ?? iconColor.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(8)
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
      trailing: Switch(
        value: value,
        activeColor: const Color(0xFF0055FF),
        onChanged: onChanged,
      ),
    );
  }

  // Yardımcı Widget: Navigasyon
  Widget _buildNavTile({
    required String title, 
    required IconData icon, 
    required Color iconColor, 
    Color? iconBgColor,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBgColor ?? iconColor.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(8)
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}