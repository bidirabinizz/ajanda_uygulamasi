import 'package:flutter/material.dart';
import '../../servisler/tema_yoneticisi.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  
  // YENİ: Switch'in takılmaması için yerel bir değişken tutuyoruz
  late bool _isDarkLocal;

  @override
  void initState() {
    super.initState();
    // Sayfa açılırken mevcut tema durumunu alıyoruz
    _isDarkLocal = TemaYoneticisi().isDarkMode;
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
                    // DİKKAT: Artık global değeri değil, yerel değişkeni kullanıyoruz
                    value: _isDarkLocal, 
                    onChanged: (val) async {
                      // 1. Önce sadece butonu kaydır (Hızlı tepki)
                      setState(() {
                        _isDarkLocal = val;
                      });
                      
                      // 2. Buton animasyonu bitene kadar bekle (300ms)
                      await Future.delayed(const Duration(milliseconds: 300));
                      
                      // 3. Şimdi ağır işlemi yap (Temayı değiştir)
                      temaYoneticisi.temayiDegistir(val); 
                    },
                  ),
                  Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),
                  _buildSwitchTile(
                    title: "Bildirimler",
                    icon: Icons.notifications_outlined,
                    iconColor: Colors.blue,
                    iconBgColor: iconBgColor,
                    textColor: textColor,
                    value: _notificationsEnabled,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                  ),
                  Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),
                  _buildSwitchTile(
                    title: "Uygulama Sesleri",
                    icon: Icons.volume_up_outlined,
                    iconColor: Colors.orange,
                    iconBgColor: iconBgColor,
                    textColor: textColor,
                    value: _soundEnabled,
                    onChanged: (val) => setState(() => _soundEnabled = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- BÖLÜM 2: HESAP ---
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

            // --- BÖLÜM 3: TEHLİKELİ BÖLGE ---
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