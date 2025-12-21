import 'package:flutter/material.dart';
import 'sayfa_ayarlar.dart'; 
import '../destek_talepleri_ekrani.dart';

// DİKKAT: Sınıf ismini 'ProfilSayfasi' yaptık
class ProfilSayfasi extends StatelessWidget {
  final String userName;
  final int userId; // EKLENDİ: Destek talebi için gerekli
  final VoidCallback onLogout;

  const ProfilSayfasi({
    super.key, 
    required this.userName, 
    required this.userId, // EKLENDİ
    required this.onLogout
  });

  @override
  Widget build(BuildContext context) {
    // Tema verilerini al
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final tileColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[100];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0055FF), width: 2),
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF0055FF),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
          Text("Üye", style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 40),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.settings, color: textColor),
                  ),
                  title: Text("Ayarlar", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // --- DESTEK TALEPLERİ BUTONU ---
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.support_agent, color: Colors.orange),
                  ),
                  title: const Text("Destek Taleplerim", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DestekTalepleriEkrani(userId: userId)),
                    );
                  },
                ),
                const Divider(),

                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.logout, color: Colors.red),
                  ),
                  title: const Text("Çıkış Yap", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}