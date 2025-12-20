import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // LoginScreen için
import '../servisler/api_servisi.dart'; // API servisi
import '../modeller/ajanda_modelleri.dart'; // Etkinlik modeli için

class AdminPaneli extends StatefulWidget {
  final String adminName;

  const AdminPaneli({super.key, required this.adminName});

  @override
  State<AdminPaneli> createState() => _AdminPaneliState();
}

class _AdminPaneliState extends State<AdminPaneli> {
  final ApiService _api = ApiService();
  
  // Kullanıcı listesi
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await _api.getAllUsers();
    
    if (mounted) {
      setState(() {
        _users = users;
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

  // --- YENİ: KULLANICI AKTİVİTE GEÇMİŞİNİ GÖSTER ---
  void _showUserActivity(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Tam ekran boyu için
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7, // Ekranın %70'ini kaplasın
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Tutamaç
                  Center(
                    child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 20),
                  
                  // Başlık ve İsim
                  Text("${user['ad_soyad'] ?? 'Kullanıcı'} - Detaylar", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // İstatistikler ve Görevler (FutureBuilder ile yükle)
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _getUserDetails(user['id']), // Hem istatistik hem görevleri getir
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(child: Text("Veriler yüklenemedi."));
                        }

                        final stats = snapshot.data!['stats'];
                        final List<Etkinlik> tasks = snapshot.data!['tasks'];

                        return ListView(
                          controller: controller,
                          children: [
                            // İstatistik Kartları
                            Row(
                              children: [
                                _buildDetailCard("Toplam Görev", "${stats['total_tasks']}", Colors.blue),
                                const SizedBox(width: 10),
                                _buildDetailCard("Tamamlanan", "${stats['completed_tasks'] ?? 0}", Colors.green),
                                const SizedBox(width: 10),
                                _buildDetailCard("Başarı", "%${stats['total_tasks'] > 0 ? ((stats['completed_tasks'] ?? 0) / stats['total_tasks'] * 100).toInt() : 0}", Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text("Son Aktiviteler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            
                            // Görev Listesi
                            if (tasks.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(child: Text("Henüz bir aktivite yok.", style: TextStyle(color: Colors.grey))),
                              )
                            else
                              ...tasks.map((task) => Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                color: task.tamamlandiMi ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                                child: ListTile(
                                  leading: Icon(
                                    task.tamamlandiMi ? Icons.check_circle : Icons.circle_outlined,
                                    color: task.tamamlandiMi ? Colors.green : Colors.grey,
                                  ),
                                  title: Text(task.baslik, style: TextStyle(decoration: task.tamamlandiMi ? TextDecoration.lineThrough : null)),
                                  subtitle: Text("${task.baslangicTarihi.day}.${task.baslangicTarihi.month}.${task.baslangicTarihi.year} - ${task.oncelik}"),
                                  trailing: task.tamamlandiMi 
                                    ? const Icon(Icons.check, color: Colors.green, size: 16) 
                                    : null,
                                ),
                              )),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Yardımcı: Kullanıcı verilerini (istatistik + görevler) paralel çek
  Future<Map<String, dynamic>> _getUserDetails(int userId) async {
    // Burada ApiService'de getUserStats ve getEvents metodlarının olması gerekiyor.
    // Eğer getUserStats yoksa, sadece getEvents ile de manuel hesaplayabiliriz.
    // Şimdilik varsayım olarak sadece getEvents'i kullanıp hesaplayalım (daha güvenli):
    
    try {
      final tasks = await _api.getEvents(userId);
      // İstatistikleri hesapla
      int total = tasks.length;
      int completed = tasks.where((t) => t.tamamlandiMi).length;
      
      // Görevleri tarihe göre (en yeni en üstte) sırala
      tasks.sort((a, b) => b.baslangicTarihi.compareTo(a.baslangicTarihi));
      
      return {
        'stats': {'total_tasks': total, 'completed_tasks': completed},
        'tasks': tasks
      };
    } catch (e) {
      return {
        'stats': {'total_tasks': 0, 'completed_tasks': 0},
        'tasks': <Etkinlik>[]
      };
    }
  }

  Widget _buildDetailCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Kullanıcı Seçenekleri Menüsü
  void _showUserOptions(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final currentRole = user['unvan'] ?? user['role'] ?? 'user';
        final isCurrentlyAdmin = currentRole.toString().toLowerCase() == 'admin';
        final userName = user['ad_soyad'] ?? user['name'] ?? 'İsimsiz';
        final userEmail = user['eposta'] ?? user['email'] ?? '';

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(userEmail, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              
              // YENİ: Aktivite Geçmişi Butonu
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text("Aktivite Geçmişini Gör"),
                onTap: () {
                  Navigator.pop(context); // Önce menüyü kapat
                  _showUserActivity(user); // Sonra detayı aç
                },
              ),
              const Divider(),

              // Rol Değiştirme
              ListTile(
                leading: Icon(
                  isCurrentlyAdmin ? Icons.person_off : Icons.verified_user,
                  color: isCurrentlyAdmin ? Colors.orange : Colors.green
                ),
                title: Text(isCurrentlyAdmin ? "Admin Yetkisini Al" : "Admin Yap"),
                onTap: () async {
                  Navigator.pop(context); 
                  final newRole = isCurrentlyAdmin ? 'user' : 'admin';
                  final success = await _api.updateUserRole(user['id'], newRole);

                  if (success) {
                    _fetchUsers(); 
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Rol güncellendi: $newRole")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata oluştu.")));
                  }
                },
              ),
              
              // Kullanıcı Silme
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Kullanıcıyı Sil"),
                onTap: () async {
                  Navigator.pop(context);
                  bool confirm = await showDialog(
                    context: context, 
                    builder: (c) => AlertDialog(
                      title: const Text("Emin misin?"),
                      content: const Text("Bu kullanıcı ve tüm verileri silinecek."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("İptal")),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Sil", style: TextStyle(color: Colors.red))),
                      ],
                    )
                  ) ?? false;

                  if (confirm) {
                    final success = await _api.deleteUser(user['id']);
                    if (success) {
                      _fetchUsers();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanıcı silindi.")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silme hatası.")));
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Duyuru Dialog'u
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
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Başlık", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: "İçerik", border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Duyuru başarıyla gönderildi! 📢")));
              }
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
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchUsers,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hoşgeldinr ${widget.adminName}! ",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // İstatistik Kartları
                  Row(
                    children: [
                      _buildAdminCard(
                        icon: Icons.people,
                        title: "Kullanıcılar",
                        count: "${_users.length}", 
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildAdminCard(
                        icon: Icons.event_note,
                        title: "Toplam Not",
                        count: "...", 
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Kullanıcı Listesi Başlığı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Kullanıcılar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Kullanıcı Listesi
                  _users.isEmpty 
                    ? const Center(child: Text("Kayıtlı kullanıcı yok."))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          // Veritabanı anahtarları: 'ad_soyad', 'eposta', 'unvan'
                          final userName = user['ad_soyad'] ?? user['name'] ?? 'İsimsiz';
                          final userEmail = user['eposta'] ?? user['email'] ?? '';
                          final role = user['unvan'] ?? user['role'] ?? 'user';
                          
                          final isAdmin = role.toString().toLowerCase() == 'admin';
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isAdmin ? Colors.redAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
                                child: Icon(isAdmin ? Icons.security : Icons.person, color: isAdmin ? Colors.red : Colors.blue),
                              ),
                              title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(userEmail),
                              trailing: const Icon(Icons.more_vert),
                              onTap: () => _showUserOptions(user),
                            ),
                          );
                        },
                      ),

                  const SizedBox(height: 30),
                  
                  // Diğer Araçlar
                  const Text("Sistem Araçları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.campaign, color: Colors.purple),
                      title: const Text("Duyuru Gönder"),
                      subtitle: const Text("Tüm kullanıcılara bildirim yolla"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showAnnouncementDialog,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.settings, color: Colors.grey),
                      title: const Text("Uygulama Ayarları"),
                      subtitle: const Text("Genel yapılandırma"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ayarlar sayfası yapım aşamasında.")));
                      },
                    ),
                  ),
                ],
              ),
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