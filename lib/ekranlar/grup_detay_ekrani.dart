import 'package:flutter/material.dart';
import '../servisler/api_servisi.dart';
// Harici importlara gerek yok, her şey burada!

class GrupDetayEkrani extends StatefulWidget {
  final Map<String, dynamic> grup;

  const GrupDetayEkrani({super.key, required this.grup});

  @override
  State<GrupDetayEkrani> createState() => _GrupDetayEkraniState();
}

class _GrupDetayEkraniState extends State<GrupDetayEkrani> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _uyeler = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _uyeleriGetir();
  }

  Future<void> _uyeleriGetir() async {
    final veri = await _api.getGrupUyeleri(widget.grup['id']);
    if (mounted) {
      setState(() {
        _uyeler = veri;
        _isLoading = false;
      });
    }
  }

  // --- ÜYE EKLEME PENCERESİ ---
  void _uyeEkleDialog() async {
    final tumKullanicilar = await _api.getAllUsers();
    final eklenebilecekler = tumKullanicilar.where((k) => k['grup_id'] != widget.grup['id']).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gruba Üye Ekle"),
        content: SizedBox(
          width: double.maxFinite,
          child: eklenebilecekler.isEmpty 
          ? const Text("Eklenebilecek boşta kullanıcı bulunamadı.")
          : ListView.builder(
              shrinkWrap: true,
              itemCount: eklenebilecekler.length,
              itemBuilder: (context, index) {
                final user = eklenebilecekler[index];
                return ListTile(
                  leading: const Icon(Icons.person_add),
                  title: Text(user['ad_soyad'] ?? "İsimsiz"),
                  subtitle: Text(user['eposta'] ?? ""),
                  onTap: () async {
                    Navigator.pop(context);
                    await _api.addUyeToGrup(user['id'], widget.grup['id']);
                    _uyeleriGetir();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Üye eklendi!")));
                  },
                );
              },
            ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))],
      ),
    );
  }

  // --- DUYURU PENCERESİ ---
  void _duyuruYapDialog() {
    final baslikController = TextEditingController();
    final mesajController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("'${widget.grup['ad']}' Grubuna Duyuru"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: baslikController, decoration: const InputDecoration(labelText: "Başlık")),
            TextField(controller: mesajController, decoration: const InputDecoration(labelText: "Mesaj"), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (baslikController.text.isNotEmpty) {
                Navigator.pop(context);
                await _api.sendGrupDuyuru(widget.grup['id'], baslikController.text, mesajController.text);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Duyuru gönderildi!")));
              }
            },
            child: const Text("Gönder"),
          )
        ],
      ),
    );
  }

  // --- GÖREV ATAMA PENCERESİ (YENİ VE DETAYLI) ---
  void _gorevAtaDialog() {
    final baslikController = TextEditingController();
    final aciklamaController = TextEditingController();
    
    DateTime secilenTarih = DateTime.now().add(const Duration(days: 1)); // Yarın
    TimeOfDay secilenSaat = const TimeOfDay(hour: 09, minute: 00); // Sabah 09:00

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder: Dialog içinde tarih/saat seçince ekranın güncellenmesi için şart!
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Ekip Görevi Ata", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Başlık
                    TextField(
                      controller: baslikController,
                      decoration: const InputDecoration(
                        labelText: "Görev Başlığı",
                        prefixIcon: Icon(Icons.task_alt),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // 2. Açıklama
                    TextField(
                      controller: aciklamaController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Açıklama / Detaylar",
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 3. Tarih Seçici
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                      title: Text(
                        "${secilenTarih.day}.${secilenTarih.month}.${secilenTarih.year}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text("Bitiş Tarihi"),
                      trailing: const Icon(Icons.edit, size: 16),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: secilenTarih,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setStateDialog(() => secilenTarih = picked);
                        }
                      },
                    ),

                    // 4. Saat Seçici
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time, color: Colors.orangeAccent),
                      title: Text(
                        "${secilenSaat.hour}:${secilenSaat.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text("Bitiş Saati"),
                      trailing: const Icon(Icons.edit, size: 16),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: secilenSaat,
                        );
                        if (picked != null) {
                          setStateDialog(() => secilenSaat = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("İptal")
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (baslikController.text.isNotEmpty) {
                      // Tarih ve Saati birleştir
                      final fullDate = DateTime(
                        secilenTarih.year, secilenTarih.month, secilenTarih.day,
                        secilenSaat.hour, secilenSaat.minute
                      );

                      Navigator.pop(context);
                      
                      // API'ye gönder
                      await _api.assignTaskToGroup(
                        widget.grup['id'], 
                        baslikController.text, 
                        aciklamaController.text, 
                        fullDate
                      );
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Görev tüm ekibe atandı! 🚀"), backgroundColor: Colors.green)
                      );
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Lütfen bir başlık girin."))
                      );
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text("Görevi Ata"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E0D46), foregroundColor: Colors.white),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.grup['ad'])),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uyeEkleDialog,
        icon: const Icon(Icons.add),
        label: const Text("Üye Ekle"),
      ),
      body: Column(
        children: [
          // --- HIZLI AKSİYON BUTONLARI ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(Icons.assignment, "Görev Ata", Colors.orange, _gorevAtaDialog),
                _actionButton(Icons.campaign, "Duyuru Yap", Colors.blue, _duyuruYapDialog),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // --- ÜYE LİSTESİ ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _uyeler.isEmpty
                    ? const Center(child: Text("Bu grupta henüz kimse yok."))
                    : ListView.builder(
                        itemCount: _uyeler.length,
                        itemBuilder: (context, index) {
                          final uye = _uyeler[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text(uye['ad_soyad'][0])),
                            title: Text(uye['ad_soyad']),
                            subtitle: Text(uye['eposta']),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                              onPressed: () async {
                                await _api.removeUyeFromGrup(uye['id']);
                                _uyeleriGetir(); // Listeyi yenile
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Üye çıkarıldı.")));
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}