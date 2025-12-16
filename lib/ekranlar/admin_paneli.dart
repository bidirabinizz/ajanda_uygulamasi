import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // LoginScreen'e dönmek için

class AdminPaneli extends StatelessWidget {
  final String adminName;

  const AdminPaneli({super.key, required this.adminName});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yönetici Paneli"),
        backgroundColor: Colors.redAccent, // Admin olduğunu hissettirelim :)
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hoşgeldin, Şef $adminName! 👮‍♂️",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // İstatistik Kartları
            Row(
              children: [
                _buildAdminCard(
                  icon: Icons.people,
                  title: "Kullanıcılar",
                  count: "15", // Backend'den çekilebilir
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildAdminCard(
                  icon: Icons.event_note,
                  title: "Toplam Etkinlik",
                  count: "128", // Backend'den çekilebilir
                  color: Colors.orange,
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            const Text("Yönetim Araçları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.person_search, color: Colors.blue),
              title: const Text("Kullanıcıları Listele"),
              subtitle: const Text("Tüm kayıtlı üyeleri gör"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Kullanıcı listesi sayfasına git
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu özellik yakında eklenecek!")));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text("Sistem Logları"),
              subtitle: const Text("Hata kayıtlarını incele"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
             const Divider(),
             ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text("Uygulama Ayarları"),
              subtitle: const Text("Genel yapılandırma"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard({required IconData icon, required String title, required String count, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 10),
            Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}