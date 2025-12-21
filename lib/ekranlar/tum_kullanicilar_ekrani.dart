import 'package:flutter/material.dart';
import '../servisler/api_servisi.dart';
import '../modeller/ajanda_modelleri.dart';

class TumKullanicilarEkrani extends StatefulWidget {
  const TumKullanicilarEkrani({super.key});

  @override
  State<TumKullanicilarEkrani> createState() => _TumKullanicilarEkraniState();
}

class _TumKullanicilarEkraniState extends State<TumKullanicilarEkrani> {
  final ApiService _api = ApiService();
  
  List<Map<String, dynamic>> _allUsers = []; // Tüm liste
  List<Map<String, dynamic>> _filteredUsers = []; // Arama sonucu
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Arama filtresi
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['ad_soyad'] ?? user['name'] ?? '').toString().toLowerCase();
        final email = (user['eposta'] ?? user['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await _api.getAllUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
        _filteredUsers = users; 
        _isLoading = false;
      });
    }
  }

  // --- AKTİVİTE GEÇMİŞİ (Senin eski kodun buraya taşındı) ---
  void _showUserActivity(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
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
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text("${user['ad_soyad']} - Detaylar", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _getUserDetails(user['id']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        if (snapshot.hasError) return const Center(child: Text("Veri yüklenemedi."));
                        
                        final stats = snapshot.data!['stats'];
                        final List<Etkinlik> tasks = snapshot.data!['tasks'];

                        return ListView(
                          controller: controller,
                          children: [
                            Row(
                              children: [
                                _buildDetailCard("Toplam", "${stats['total_tasks']}", Colors.blue),
                                const SizedBox(width: 10),
                                _buildDetailCard("Biten", "${stats['completed_tasks']}", Colors.green),
                                const SizedBox(width: 10),
                                _buildDetailCard("Başarı", "%${stats['total_tasks'] > 0 ? ((stats['completed_tasks'] / stats['total_tasks']) * 100).toInt() : 0}", Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text("Son Aktiviteler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            if (tasks.isEmpty)
                              const Center(child: Text("Henüz aktivite yok.", style: TextStyle(color: Colors.grey)))
                            else
                              ...tasks.map((task) => Card(
                                color: task.tamamlandiMi ? Colors.green.withOpacity(0.1) : null,
                                child: ListTile(
                                  leading: Icon(task.tamamlandiMi ? Icons.check_circle : Icons.circle_outlined, color: task.tamamlandiMi ? Colors.green : Colors.grey),
                                  title: Text(task.baslik, style: TextStyle(decoration: task.tamamlandiMi ? TextDecoration.lineThrough : null)),
                                  subtitle: Text("${task.baslangicTarihi.day}.${task.baslangicTarihi.month} - ${task.oncelik}"),
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

  Future<Map<String, dynamic>> _getUserDetails(int userId) async {
    try {
      final tasks = await _api.getEvents(userId);
      int completed = tasks.where((t) => t.tamamlandiMi).length;
      tasks.sort((a, b) => b.baslangicTarihi.compareTo(a.baslangicTarihi));
      return {'stats': {'total_tasks': tasks.length, 'completed_tasks': completed}, 'tasks': tasks};
    } catch (e) {
      return {'stats': {'total_tasks': 0, 'completed_tasks': 0}, 'tasks': <Etkinlik>[]};
    }
  }

  Widget _buildDetailCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(children: [Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)), Text(title, style: const TextStyle(fontSize: 12))]),
      ),
    );
  }

  // --- GÖREV ATAMA (Tarih + Saat) ---
  void _showAssignTaskDialog(BuildContext context, int userId, String userName) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = "Orta";
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("$userName - Görev Ata"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Başlık", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Açıklama", border: OutlineInputBorder()), maxLines: 2),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(labelText: "Öncelik", border: OutlineInputBorder()),
                  items: ["Düşük", "Orta", "Yüksek"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setStateDialog(() => selectedPriority = val!),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text("${selectedDate.day}.${selectedDate.month}.${selectedDate.year}"),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (picked != null) setStateDialog(() => selectedDate = picked);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text("${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}"),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: selectedTime);
                    if (picked != null) setStateDialog(() => selectedTime = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final fullDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                  final success = await _api.addEvent(userId, titleController.text, descController.text, fullDate, selectedPriority);
                  if (success) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Görev Atandı!"), backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text("Ata"),
            ),
          ],
        ),
      ),
    );
  }

  // --- KULLANICI SEÇENEKLERİ MENÜSÜ ---
  void _showUserOptions(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final role = user['unvan'] ?? 'user';
        final isAdmin = role.toString().toLowerCase() == 'admin';
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user['ad_soyad'] ?? 'İsimsiz', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text("Aktivite Geçmişi"),
                onTap: () { Navigator.pop(context); _showUserActivity(user); },
              ),
              ListTile(
                leading: const Icon(Icons.assignment_add, color: Colors.purple),
                title: const Text("Görev Ata"),
                onTap: () { Navigator.pop(context); _showAssignTaskDialog(context, user['id'], user['ad_soyad']); },
              ),
              ListTile(
                leading: Icon(isAdmin ? Icons.person_off : Icons.security, color: isAdmin ? Colors.orange : Colors.green),
                title: Text(isAdmin ? "Yönetici Yetkisini Al" : "Yönetici Yap"),
                onTap: () async {
                  Navigator.pop(context);
                  await _api.updateUserRole(user['id'], isAdmin ? 'user' : 'admin');
                  _fetchUsers();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Kullanıcıyı Sil"),
                onTap: () async {
                  Navigator.pop(context);
                  await _api.deleteUser(user['id']);
                  _fetchUsers();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kullanıcı Yönetimi"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "İsim veya E-posta ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _filteredUsers.isEmpty 
                ? const Center(child: Text("Sonuç bulunamadı.")) 
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(user['ad_soyad']?[0] ?? "?")),
                          title: Text(user['ad_soyad'] ?? ""),
                          subtitle: Text(user['eposta'] ?? ""),
                          trailing: const Icon(Icons.more_vert),
                          onTap: () => _showUserOptions(user),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}