import 'package:flutter/material.dart';
import '../servisler/api_servisi.dart';
import 'grup_detay_ekrani.dart'; // Detay sayfasına gitmek için bunu import ettik

class GruplarEkrani extends StatefulWidget {
  const GruplarEkrani({super.key});

  @override
  State<GruplarEkrani> createState() => _GruplarEkraniState();
}

class _GruplarEkraniState extends State<GruplarEkrani> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _gruplar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verileriGetir();
  }

  // Verileri API'den çekme
  void _verileriGetir() async {
    setState(() => _isLoading = true);
    final veri = await _api.getGruplar();
    if (mounted) {
      setState(() {
        _gruplar = veri;
        _isLoading = false;
      });
    }
  }

  // Ekleme ve Düzenleme Penceresi
  void _grupIslemiDialog({Map<String, dynamic>? grup}) {
    final controller = TextEditingController(text: grup != null ? grup['ad'] : '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(grup == null ? "Yeni Grup Oluştur" : "Grubu Düzenle"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Grup Adı", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              
              Navigator.pop(context); // Pencreyi kapat
              
              bool basarili;
              if (grup == null) {
                // Yeni Ekle
                basarili = await _api.addGrup(controller.text);
              } else {
                // Düzenle
                basarili = await _api.updateGrup(grup['id'], controller.text);
              }

              if (basarili) {
                _verileriGetir(); // Listeyi yenile
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İşlem Başarılı!")));
              }
            },
            child: const Text("Kaydet"),
          )
        ],
      ),
    );
  }

  // Silme Onayı
  void _silmeOnayi(int id, String ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Grubu Sil"),
        content: Text("'$ad' grubunu silmek istediğine emin misin? Gruptaki kullanıcılar boşa düşecek."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _api.deleteGrup(id);
              _verileriGetir(); // Silindikten sonra listeyi yenile
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gruplar & Ekipler")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _grupIslemiDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _gruplar.isEmpty
              ? const Center(child: Text("Henüz grup yok."))
              : ListView.builder(
                  itemCount: _gruplar.length,
                  itemBuilder: (context, index) {
                    final grup = _gruplar[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        // Sol taraftaki ikon
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withOpacity(0.2),
                          child: const Icon(Icons.group, color: Colors.blueAccent),
                        ),
                        // Grup İsmi
                        title: Text(grup['ad'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        
                        // --- YENİ EKLENEN KISIM: DETAY SAYFASINA GİT ---
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GrupDetayEkrani(grup: grup),
                            ),
                          );
                        },

                        // Sağ taraftaki butonlar (Düzenle / Sil)
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _grupIslemiDialog(grup: grup),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _silmeOnayi(grup['id'], grup['ad']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}