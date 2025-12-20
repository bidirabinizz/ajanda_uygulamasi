import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../servisler/api_servisi.dart';
import '../modeller/ajanda_modelleri.dart';

class EtkinlikFormu extends StatefulWidget {
  final int userId;
  final Etkinlik? duzenlenecekEtkinlik;
  final DateTime? initialDate; 

  const EtkinlikFormu({
    super.key, 
    required this.userId, 
    this.duzenlenecekEtkinlik,
    this.initialDate
  });

  @override
  State<EtkinlikFormu> createState() => _EtkinlikFormuState();
}

class _EtkinlikFormuState extends State<EtkinlikFormu> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _api = ApiService(); 

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _priority = 'Orta'; 
  
  List<Kategori> _categories = [];
  Kategori? _selectedCategory;
  bool _isLoadingCategories = true;

  bool _isRecurring = false; 
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  final List<bool> _selectedWeekDays = [false, false, false, false, false, false, false];
  final List<String> _dayLabels = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];

  bool _isEditing = false;
  bool _isReminderOn = false; 
  bool _isSaving = false; 

  final List<Map<String, dynamic>> _colors = [
    {'color': const Color(0xFFFF5252), 'priority': 'Yüksek', 'icon': Icons.priority_high}, 
    {'color': const Color(0xFFFFAB40), 'priority': 'Orta', 'icon': Icons.work_outline},    
    {'color': const Color(0xFF448AFF), 'priority': 'Düşük', 'icon': Icons.waves},          
    {'color': const Color(0xFF69F0AE), 'priority': 'Düşük', 'icon': Icons.eco_outlined},   
  ];

  late Map<String, dynamic> _selectedColorOption;

  @override
  void initState() {
    super.initState();
    _selectedColorOption = _colors[1]; 
    _fetchCategories(); 

    if (widget.duzenlenecekEtkinlik != null) {
      _isEditing = true;
      _titleController.text = widget.duzenlenecekEtkinlik!.baslik;
      _descController.text = widget.duzenlenecekEtkinlik!.aciklama ?? "";
      
      _selectedDate = widget.duzenlenecekEtkinlik!.baslangicTarihi.toLocal();
      _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
      
      _priority = widget.duzenlenecekEtkinlik!.oncelik;
      _isReminderOn = true; 
      _isRecurring = false;

      try {
        _selectedColorOption = _colors.firstWhere(
          (element) => element['priority'] == _priority,
          orElse: () => _colors[1],
        );
      } catch (e) {
        _selectedColorOption = _colors[1];
      }
    } else {
      if (widget.initialDate != null) {
        _selectedDate = widget.initialDate!.toLocal();
      }
      int todayIndex = _selectedDate.weekday - 1; 
      _selectedWeekDays[todayIndex] = true;
    }

    _titleController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await _api.getCategories(widget.userId);
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoadingCategories = false;
          if (_isEditing && widget.duzenlenecekEtkinlik?.kategoriId != null) {
            try {
              _selectedCategory = _categories.firstWhere((c) => c.id == widget.duzenlenecekEtkinlik!.kategoriId);
            } catch (e) {}
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        debugPrint("Kategori hatası: $e");
      }
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final List<Color> catColors = [Colors.purple, Colors.pink, Colors.teal, Colors.indigo, Colors.brown];
    Color selectedCatColor = catColors[0];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardTheme.color,
              title: Text("Yeni Kategori Ekle", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: const InputDecoration(labelText: "Kategori Adı", hintText: "Örn: Spor, İş..."),
                  ),
                  const SizedBox(height: 20),
                  const Text("Renk Seç", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: catColors.map((c) => GestureDetector(
                      onTap: () => setStateDialog(() => selectedCatColor = c),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: selectedCatColor == c ? Border.all(color: Colors.white, width: 3) : null,
                          boxShadow: selectedCatColor == c ? [const BoxShadow(blurRadius: 5)] : [],
                        ),
                      ),
                    )).toList(),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      String colorCode = "0x${selectedCatColor.value.toRadixString(16).toUpperCase()}";
                      try {
                        await _api.addCategory(widget.userId, nameController.text, null, colorCode);
                        Navigator.pop(ctx);
                        _fetchCategories(); 
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
                      }
                    }
                  },
                  child: const Text("Ekle"),
                )
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (context, child) => _buildTheme(child!),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) => _buildTheme(child!),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Widget _buildTheme(Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: _selectedColorOption['color'], 
          onPrimary: Colors.white,
          surface: Theme.of(context).cardTheme.color ?? Colors.white,
          onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
        ),
      ),
      child: child,
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => _buildTheme(child!),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      PermissionStatus status = await Permission.notification.status;
      if (status.isDenied) status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() => _isReminderOn = true);
      } else {
        setState(() => _isReminderOn = false);
      }
    } else {
      setState(() => _isReminderOn = false);
    }
  }

  // --- YENİ: ÇAKIŞMA KONTROLÜ ---
  Future<bool> _checkForConflict(DateTime newStart) async {
    try {
      final events = await _api.getEvents(widget.userId);
      // Yeni etkinliğin bitiş saati (Varsayılan 1 saat ekliyoruz)
      final newEnd = newStart.add(const Duration(hours: 1));

      for (var event in events) {
        // Düzenleme modundaysak, kendisiyle çakışmasını göz ardı et
        if (_isEditing && event.id == widget.duzenlenecekEtkinlik!.id) continue;

        // Mevcut etkinliğin tarih aralığı
        // API'den gelen tarihler UTC olabilir, onları da yerel saate çevirelim güvenli olsun
        DateTime existingStart = event.baslangicTarihi.toLocal();
        DateTime existingEnd = event.bitisTarihi.toLocal();

        // Çakışma Mantığı:
        // (Yeni Başlangıç < Eski Bitiş) VE (Yeni Bitiş > Eski Başlangıç)
        // Aynı dakikaya denk geliyorsa da çakışma sayabiliriz.
        // Basit kontrol: Tam olarak aynı saat ve dakikada başlıyorsa uyaralım.
        
        bool sameDay = existingStart.year == newStart.year && 
                       existingStart.month == newStart.month && 
                       existingStart.day == newStart.day;
                       
        if (sameDay) {
           // Aynı gün içinde saat kontrolü
           // Eğer yeni etkinlik, mevcut etkinliğin süresi içinde başlıyorsa
           if (newStart.isAtSameMomentAs(existingStart) || 
              (newStart.isAfter(existingStart) && newStart.isBefore(existingEnd))) {
             return true; // Çakışma VAR
           }
        }
      }
      return false; // Çakışma YOK
    } catch (e) {
      print("Çakışma kontrolü hatası: $e");
      return false; // Hata olursa engelleme
    }
  }

  void _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir başlık gir.')));
      return;
    }

    setState(() => _isSaving = true);

    int? catId = _selectedCategory?.id;
    
    // --- ÇAKIŞMA KONTROLÜ İÇİN TARİHİ HAZIRLA ---
    final fullDate = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute
    );

    // Sadece TEKİL ekleme/düzenleme yaparken kontrol edelim (Tekrarlı da mantık karışabilir)
    if (!_isRecurring) {
        bool hasConflict = await _checkForConflict(fullDate);
        
        if (hasConflict) {
            setState(() => _isSaving = false); // Yükleniyor'u durdur

            // Kullanıcıya sor
            bool? confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                    title: const Text("⚠️ Çakışma Var"),
                    content: Text(
                        "${DateFormat('d MMMM, HH:mm', 'tr_TR').format(fullDate)} saatinde zaten bir göreviniz var.\nYine de eklemek istiyor musunuz?",
                        style: const TextStyle(fontSize: 14)
                    ),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false), // Hayır
                            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true), // Evet
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0055FF), foregroundColor: Colors.white),
                            child: const Text("Evet, Ekle"),
                        ),
                    ],
                ),
            );

            // Eğer "İptal" dediyse veya boş kapattıysa fonksiyondan çık
            if (confirm != true) return;
            
            // "Evet" dediyse tekrar yükleniyor'u aç ve devam et
            setState(() => _isSaving = true);
        }
    }

    try {
      if (_isRecurring && !_isEditing) {
        if (!_selectedWeekDays.contains(true)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen en az bir gün seçin.')));
          setState(() => _isSaving = false);
          return;
        }

        DateTime loopDate = _startDate;
        while (loopDate.compareTo(_endDate) <= 0) {
          int weekDayIndex = loopDate.weekday - 1; 
          if (_selectedWeekDays[weekDayIndex]) {
            final recurringDate = DateTime(
              loopDate.year, loopDate.month, loopDate.day,
              _selectedTime.hour, _selectedTime.minute
            );
            
            await _api.addEvent(
              widget.userId, 
              _titleController.text, 
              _descController.text, 
              recurringDate, 
              _priority, 
              kategoriId: catId
            );
          }
          loopDate = loopDate.add(const Duration(days: 1));
        }
        if (mounted) Navigator.pop(context, true);

      } else {
        bool success;
        if (_isEditing) {
          success = await _api.updateEvent(
            widget.duzenlenecekEtkinlik!.id, 
            _titleController.text, 
            _descController.text, 
            fullDate, 
            _priority, 
            kategoriId: catId
          );
        } else {
          success = await _api.addEvent(
            widget.userId, 
            _titleController.text, 
            _descController.text, 
            fullDate, 
            _priority, 
            kategoriId: catId
          );
        }

        if (success && mounted) {
          Navigator.pop(context, true); 
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem başarısız oldu.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
    
    if (mounted) setState(() => _isSaving = false);
  }

  Color _parseColor(String? colorCode) {
    if (colorCode == null) return Colors.grey;
    try {
      if (colorCode.startsWith("0x")) {
        return Color(int.parse(colorCode));
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey;
    final iconColor = isDark ? Colors.white70 : Colors.black87;
    final dividerColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final Color mainColor = _selectedColorOption['color'];
    final Color lightColor = mainColor.withOpacity(0.2);

    final String heroTag = widget.duzenlenecekEtkinlik != null 
        ? 'event-${widget.duzenlenecekEtkinlik!.id}' 
        : 'create-event-new';

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: iconColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? "Planı Düzenle" : "Yeni Plan",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("İptal", style: TextStyle(color: Colors.grey))
          )
        ],
      ),
      body: Hero(
        tag: heroTag,
        child: Material(
          type: MaterialType.transparency, 
          child: _isSaving 
            ? Center(child: CircularProgressIndicator(color: mainColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [mainColor.withOpacity(0.8), mainColor], 
                          begin: Alignment.topLeft, 
                          end: Alignment.bottomRight
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: mainColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                            child: Icon(_selectedColorOption['icon'], color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _titleController.text.isEmpty ? "Başlık Girin..." : _titleController.text,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Öncelik: $_priority",
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, decoration: TextDecoration.none),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor, decoration: TextDecoration.none)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: _isLoadingCategories 
                        ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                        : DropdownButtonHideUnderline(
                        child: DropdownButton<Kategori?>(
                          value: _selectedCategory,
                          hint: Text("Kategori Seçin", style: TextStyle(color: hintColor)),
                          isExpanded: true,
                          dropdownColor: cardColor,
                          icon: Icon(Icons.keyboard_arrow_down, color: iconColor),
                          items: [
                            ..._categories.map((Kategori cat) {
                              return DropdownMenuItem<Kategori?>(
                                value: cat,
                                child: Row(
                                  children: [
                                    Icon(Icons.circle, color: _parseColor(cat.renkKodu), size: 12),
                                    const SizedBox(width: 10),
                                    Text(cat.baslik, style: TextStyle(color: textColor)),
                                  ],
                                ),
                              );
                            }).toList(),
                            DropdownMenuItem<Kategori?>(
                              value: null,
                              onTap: () {
                                Future.delayed(const Duration(milliseconds: 100), _showAddCategoryDialog);
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline, color: mainColor),
                                  const SizedBox(width: 10),
                                  Text("Yeni Kategori Ekle", style: TextStyle(color: mainColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ], 
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Text("Öncelik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor, decoration: TextDecoration.none)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _colors.map((option) {
                        final isSelected = _selectedColorOption == option;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColorOption = option;
                              _priority = option['priority'];
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: option['color'],
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: textColor, width: 3) : null,
                              boxShadow: isSelected ? [BoxShadow(color: (option['color'] as Color).withOpacity(0.4), blurRadius: 10, spreadRadius: 2)] : [],
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: TextField(
                              controller: _titleController,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(hintText: "Plan Başlığı", hintStyle: TextStyle(color: hintColor), prefixIcon: Icon(Icons.edit_outlined, color: hintColor), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                            ),
                          ),
                          Divider(height: 1, indent: 20, endIndent: 20, color: dividerColor),
                          
                          if (!_isEditing) ...[
                            ListTile(
                              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.repeat, color: mainColor, size: 20)),
                              title: Text("Tekrarlı Plan", style: TextStyle(color: textColor)),
                              trailing: Switch(value: _isRecurring, activeColor: mainColor, onChanged: (val) => setState(() => _isRecurring = val)),
                            ),
                            if (_isRecurring) ...[
                              Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),
                              ListTile(
                                leading: const SizedBox(),
                                title: const Text("Tarih Aralığı", style: TextStyle(fontSize: 14, color: Colors.grey)),
                                trailing: Row(children: [Text("${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)}", style: TextStyle(color: mainColor, fontWeight: FontWeight.bold)), const SizedBox(width: 8), const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)]),
                                onTap: _pickDateRange,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (index) {
                                  final isSelected = _selectedWeekDays[index];
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedWeekDays[index] = !isSelected),
                                    child: Container(width: 35, height: 35, alignment: Alignment.center, decoration: BoxDecoration(color: isSelected ? mainColor : (isDark ? Colors.grey[800] : Colors.grey[100]), shape: BoxShape.circle), child: Text(_dayLabels[index], style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey), fontSize: 10, fontWeight: FontWeight.bold))),
                                  );
                                })),
                              ),
                            ],
                            Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),
                          ],

                          if (!_isRecurring) ...[
                            ListTile(
                              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.calendar_today, color: mainColor, size: 20)),
                              title: Text("Tarih", style: TextStyle(color: textColor)),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate), style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)), const SizedBox(width: 8), const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)]),
                              onTap: _pickDate,
                            ),
                            Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),
                          ],

                          ListTile(
                            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.access_time, color: mainColor, size: 20)),
                            title: Text("Saat", style: TextStyle(color: textColor)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text("${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)), const SizedBox(width: 8), const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)]),
                            onTap: _pickTime,
                          ),
                          Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),

                          ListTile(
                            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.notifications_none, color: mainColor, size: 20)),
                            title: Text("Hatırlatıcı", style: TextStyle(color: textColor)),
                            trailing: Switch(value: _isReminderOn, activeColor: mainColor, onChanged: _toggleReminder),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    Text("Detaylar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor, decoration: TextDecoration.none)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: TextField(controller: _descController, maxLines: 3, style: TextStyle(color: textColor), decoration: InputDecoration(hintText: "Varsa notlarınızı buraya ekleyin...", hintStyle: TextStyle(color: hintColor), border: InputBorder.none)),
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E0D46), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5, shadowColor: const Color(0xFF0E0D46).withOpacity(0.4)),
                        child: Text(_isEditing ? "Değişiklikleri Kaydet" : (_isRecurring ? "Planları Oluştur" : "Planı Oluştur"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
            ),
        ),
      ),
    );
  }
}