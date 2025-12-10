import 'package:flutter/material.dart';
import '../../servisler/api_servisi.dart';
import '../../modeller/ajanda_modelleri.dart';

class CategoryManagementScreen extends StatefulWidget {
  final int userId;
  const CategoryManagementScreen({super.key, required this.userId});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _api = ApiService();
  List<Kategori> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final cats = await _api.getCategories(widget.userId);
    setState(() {
      _categories = cats;
      _isLoading = false;
    });
  }

  // Ekleme ve Düzenleme Dialogu
  void _showCategoryDialog({Kategori? category}) {
    final nameController = TextEditingController(text: category?.baslik ?? "");
    final List<Color> catColors = [
      Colors.purple, Colors.pink, Colors.red, Colors.orange, 
      Colors.amber, Colors.green, Colors.teal, Colors.blue, Colors.indigo, Colors.brown
    ];
    Color selectedColor = category?.renk ?? catColors[0];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Tema Ayarları
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black87;
            final cardColor = Theme.of(context).cardTheme.color;
            final hintColor = isDark ? Colors.grey[400] : Colors.grey;

            return AlertDialog(
              backgroundColor: cardColor,
              title: Text(
                category == null ? "Kategori Ekle" : "Kategoriyi Düzenle", 
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: "Kategori Adı",
                      hintText: "Örn: Spor, İş...",
                      hintStyle: TextStyle(color: hintColor),
                      labelStyle: TextStyle(color: hintColor),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: hintColor!)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0055FF))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Renk Seç", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: catColors.map((c) => GestureDetector(
                      onTap: () => setStateDialog(() => selectedColor = c),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: selectedColor == c ? Border.all(color: textColor, width: 3) : null,
                          boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 4)],
                        ),
                        child: selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    )).toList(),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: const Text("İptal", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0055FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      String colorCode = "0x${selectedColor.value.toRadixString(16).toUpperCase()}";
                      bool success;
                      
                      if (category == null) {
                        // Yeni Ekle
                        success = await _api.addCategory(widget.userId, nameController.text, null, colorCode);
                      } else {
                        // Güncelle
                        success = await _api.updateCategory(category.id, nameController.text, colorCode);
                      }

                      if (success) {
                        Navigator.pop(ctx);
                        _loadCategories(); // Listeyi yenile
                      }
                    }
                  },
                  child: Text(category == null ? "Ekle" : "Güncelle"),
                )
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Text("Kategoriyi Sil?", style: TextStyle(color: Colors.red)),
        content: Text(
          "Bu kategoriyi silersen, bu kategoriye bağlı etkinliklerin kategorisi boş görünecektir.",
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _api.deleteCategory(id);
              _loadCategories();
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tema Ayarları
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Kategorilerim", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("Henüz kategori eklemedin.", style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Dismissible(
                  key: Key(cat.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    _confirmDelete(cat.id);
                    return false; // Silme işlemini dialog ile yapıyoruz
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: cat.renk.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.folder, color: cat.renk, size: 20),
                      ),
                      title: Text(cat.baslik, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                        onPressed: () => _showCategoryDialog(category: cat),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: const Color(0xFF0055FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Yeni Kategori", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}