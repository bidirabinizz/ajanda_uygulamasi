import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // LoginScreen için
import '../servisler/api_servisi.dart';
import 'tum_kullanicilar_ekrani.dart'; 
import 'admin_destek_ekrani.dart'; // Admin Sohbet Ekranını içeri aldık
import 'gruplar_ekrani.dart'; // Dosya adın farklıysa düzeltirsin
import '../servisler/bildirim_servisi.dart';

class AdminPaneli extends StatefulWidget {
  final String adminName;
  const AdminPaneli({super.key, required this.adminName});

  @override
  State<AdminPaneli> createState() => _AdminPaneliState();
}

class _AdminPaneliState extends State<AdminPaneli> {
  final ApiService _api = ApiService();
  int _userCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();

    BildirimServisi().baslat(4);
  }

  Future<void> _fetchStats() async {
    final users = await _api.getAllUsers();
    if (mounted) {
      setState(() {
        _userCount = users.length;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // Basit Duyuru Penceresi
  void _showAnnouncementDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Duyuru Gönder"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Başlık", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: "İçerik", border: OutlineInputBorder()), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Duyuru gönderildi!")));
            },
            child: const Text("Gönder"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yönetici Paneli"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: () => _logout(context))
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Merhaba, ${widget.adminName} 👋", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // --- İSTATİSTİK KARTLARI ---
                Row(
                  children: [
                    _buildSummaryCard(title: "Kayıtlı Kullanıcı", value: "$_userCount", icon: Icons.group, color: Colors.blue),
                    const SizedBox(width: 15),
                    _buildSummaryCard(title: "Aktif Duyurular", value: "0", icon: Icons.campaign, color: Colors.orange),
                  ],
                ),
                
                const SizedBox(height: 30),
                const Text("Yönetim Menüsü", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // --- KULLANICI YÖNETİMİ BUTONU ---
                _buildMenuButton(
                  icon: Icons.manage_accounts,
                  title: "Kullanıcı Yönetimi",
                  subtitle: "Kullanıcıları ara, düzenle, görev ata.",
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TumKullanicilarEkrani()),
                    ).then((_) => _fetchStats());
                  },
                ),
                
                const SizedBox(height: 15),

                // --- [YENİ] GRUPLAR & EKİPLER BUTONU ---
                _buildMenuButton(
                  icon: Icons.groups, // İkon tam oturdu
                  title: "Gruplar & Ekipler",
                  subtitle: "Departman kur, düzenle, toplu görev ata.",
                  color: Colors.orangeAccent, // Turuncu güzel patlar
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GruplarEkrani()),
                    );
                  },
                ),

                const SizedBox(height: 15),

                // --- DUYURU BUTONU ---
                _buildMenuButton(
                  icon: Icons.notifications_active,
                  title: "Duyuru Gönder",
                  subtitle: "Tüm kullanıcılara bildirim yolla.",
                  color: Colors.purple,
                  onTap: _showAnnouncementDialog,
                ),

                const SizedBox(height: 15),

                // --- YENİ EKLENEN: DESTEK TALEPLERİ BUTONU ---
                _buildMenuButton(
                  icon: Icons.support_agent,
                  title: "Destek Talepleri",
                  subtitle: "Gelen yardım mesajlarını cevapla.",
                  color: Colors.teal,
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminDestekEkrani()),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(children: [Icon(icon, size: 30, color: color), const SizedBox(height: 10), Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)), Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12))]),
      ),
    );
  }

  Widget _buildMenuButton({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}