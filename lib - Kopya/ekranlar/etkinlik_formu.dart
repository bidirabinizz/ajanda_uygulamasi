import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart'; 
import '../servisler/api_servisi.dart';
import '../modeller/ajanda_modelleri.dart';

class EtkinlikFormu extends StatefulWidget {
  final int userId;
  final Etkinlik? duzenlenecekEtkinlik;

  const EtkinlikFormu({super.key, required this.userId, this.duzenlenecekEtkinlik});

  @override
  State<EtkinlikFormu> createState() => _EtkinlikFormuState();
}

class _EtkinlikFormuState extends State<EtkinlikFormu> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _api = ApiService();

  // Tekil Tarih Modu İçin
  DateTime _selectedDate = DateTime.now();
  
  // Tekrarlı Mod İçin
  bool _isRecurring = false; 
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  final List<bool> _selectedWeekDays = [false, false, false, false, false, false, false];
  final List<String> _dayLabels = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];

  TimeOfDay _selectedTime = TimeOfDay.now();
  String _priority = 'Orta'; 
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

    if (widget.duzenlenecekEtkinlik != null) {
      _isEditing = true;
      _titleController.text = widget.duzenlenecekEtkinlik!.baslik;
      _descController.text = widget.duzenlenecekEtkinlik!.aciklama ?? '';
      _selectedDate = widget.duzenlenecekEtkinlik!.baslangicTarihi;
      _selectedTime = TimeOfDay.fromDateTime(widget.duzenlenecekEtkinlik!.baslangicTarihi);
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
      int todayIndex = DateTime.now().weekday - 1; 
      _selectedWeekDays[todayIndex] = true;
    }

    _titleController.addListener(() {
      setState(() {});
    });
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
    // DatePicker'ın da temaya uyması için
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: _selectedColorOption['color'], // Başlık rengi
          onPrimary: Colors.white, // Başlık yazı rengi
          surface: Theme.of(context).cardTheme.color ?? Colors.white, // Takvim arka planı
          onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, // Günlerin rengi
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
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).cardTheme.color, // Dialog rengi
              title: Text("İzin Gerekli", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              content: Text("Hatırlatıcıların çalışması için bildirim iznini ayarlardan açmanız gerekiyor.", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
                TextButton(
                  onPressed: () { Navigator.pop(ctx); openAppSettings(); },
                  child: const Text("Ayarlara Git", style: TextStyle(color: Color(0xFF0E0D46), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        setState(() => _isReminderOn = false);
      } else {
        setState(() => _isReminderOn = false);
      }
    } else {
      setState(() => _isReminderOn = false);
    }
  }

  void _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir başlık gir.')));
      return;
    }

    setState(() => _isSaving = true);

    if (_isRecurring && !_isEditing) {
      if (!_selectedWeekDays.contains(true)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen en az bir gün seçin.')));
        setState(() => _isSaving = false);
        return;
      }

      DateTime loopDate = _startDate;
      int createdCount = 0;

      while (loopDate.compareTo(_endDate) <= 0) {
        int weekDayIndex = loopDate.weekday - 1; 

        if (_selectedWeekDays[weekDayIndex]) {
          final fullDate = DateTime(
            loopDate.year, loopDate.month, loopDate.day,
            _selectedTime.hour, _selectedTime.minute
          );

          await _api.addEvent(
            widget.userId,
            _titleController.text,
            _descController.text,
            fullDate,
            _priority,
          );
          createdCount++;
        }
        loopDate = loopDate.add(const Duration(days: 1));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$createdCount adet plan oluşturuldu!')));
        Navigator.pop(context, true);
      }

    } else {
      final fullDate = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute
      );

      bool success;
      if (_isEditing) {
        success = await _api.updateEvent(
          widget.duzenlenecekEtkinlik!.id,
          _titleController.text,
          _descController.text,
          fullDate,
          _priority,
        );
      } else {
        success = await _api.addEvent(
          widget.userId,
          _titleController.text,
          _descController.text,
          fullDate,
          _priority, 
        );
      }

      if (success && mounted) {
        Navigator.pop(context, true); 
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem başarısız oldu.')));
      }
    }
    
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    // --- TEMA AYARLARI ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Renkleri temaya göre belirliyoruz
    final scaffoldColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey;
    final iconColor = isDark ? Colors.white70 : Colors.black87;
    final dividerColor = isDark ? Colors.grey[800] : Colors.grey[200];

    // Seçili renk (öncelik rengi)
    final Color mainColor = _selectedColorOption['color'];
    final Color lightColor = mainColor.withOpacity(0.2);

    return Scaffold(
      backgroundColor: scaffoldColor, // Dinamik Arka Plan
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
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
      body: _isSaving 
      ? Center(child: CircularProgressIndicator(color: mainColor))
      : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ÖNİZLEME KARTI (Değişmedi, zaten renkli)
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [mainColor.withOpacity(0.8), mainColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text("Öncelik: $_priority", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.auto_awesome, color: Colors.white.withOpacity(0.4), size: 40),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // 2. RENK SEÇİCİ
            Text("Öncelik Rengi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
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
                      border: isSelected ? Border.all(color: textColor, width: 3) : null, // Kenarlık rengi dinamik
                      boxShadow: isSelected ? [BoxShadow(color: (option['color'] as Color).withOpacity(0.4), blurRadius: 10, spreadRadius: 2)] : [],
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // 3. AYARLAR LİSTESİ
            Container(
              decoration: BoxDecoration(
                color: cardColor, // Dinamik Kart Rengi
                borderRadius: BorderRadius.circular(20), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextField(
                      controller: _titleController,
                      style: TextStyle(color: textColor), // Yazı rengi
                      decoration: InputDecoration(
                        hintText: "Plan Başlığı", 
                        hintStyle: TextStyle(color: hintColor),
                        prefixIcon: Icon(Icons.edit_outlined, color: hintColor), 
                        border: InputBorder.none, 
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 20, endIndent: 20, color: dividerColor),
                  
                  // --- TEKRAR SEÇENEĞİ ---
                  if (!_isEditing) ...[
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.repeat, color: mainColor, size: 20),
                      ),
                      title: Text("Tekrarlı Plan", style: TextStyle(color: textColor)),
                      subtitle: _isRecurring ? const Text("Birden fazla gün seçildi", style: TextStyle(fontSize: 12, color: Colors.grey)) : null,
                      trailing: Switch(
                        value: _isRecurring,
                        activeColor: mainColor,
                        onChanged: (val) => setState(() => _isRecurring = val),
                      ),
                    ),
                    
                    if (_isRecurring) ...[
                      Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),
                      // Tarih Aralığı
                      ListTile(
                        leading: const SizedBox(), 
                        title: const Text("Tarih Aralığı", style: TextStyle(fontSize: 14, color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)}",
                              style: TextStyle(color: mainColor, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                        onTap: _pickDateRange,
                      ),
                      // Gün Seçici
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            final isSelected = _selectedWeekDays[index];
                            return GestureDetector(
                              onTap: () => setState(() => _selectedWeekDays[index] = !isSelected),
                              child: Container(
                                width: 35, height: 35,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? mainColor : (isDark ? Colors.grey[800] : Colors.grey[100]), // Dinamik gri
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  _dayLabels[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                    
                    Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),
                  ],

                  // --- TEK TARİH SEÇİCİ ---
                  if (!_isRecurring) ...[
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.calendar_today, color: mainColor, size: 20),
                      ),
                      title: Text("Tarih", style: TextStyle(color: textColor)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
                            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                      onTap: _pickDate,
                    ),
                    Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),
                  ],

                  // Saat Seçimi
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.access_time, color: mainColor, size: 20),
                    ),
                    title: Text("Saat", style: TextStyle(color: textColor)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ],
                    ),
                    onTap: _pickTime,
                  ),
                  Divider(height: 1, indent: 60, endIndent: 20, color: dividerColor),

                  // Hatırlatıcı
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.notifications_none, color: mainColor, size: 20),
                    ),
                    title: Text("Hatırlatıcı", style: TextStyle(color: textColor)),
                    trailing: Switch(
                      value: _isReminderOn,
                      activeColor: mainColor,
                      onChanged: _toggleReminder,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 4. DETAYLAR
            Text("Detaylar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor, // Dinamik Renk
                borderRadius: BorderRadius.circular(20), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _descController,
                maxLines: 3,
                style: TextStyle(color: textColor), // Yazı rengi
                decoration: InputDecoration(
                  hintText: "Varsa notlarınızı buraya ekleyin...", 
                  hintStyle: TextStyle(color: hintColor),
                  border: InputBorder.none
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 5. KAYDET BUTONU
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E0D46),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: const Color(0xFF0E0D46).withOpacity(0.4),
                ),
                child: Text(
                  _isEditing ? "Değişiklikleri Kaydet" : (_isRecurring ? "Planları Oluştur" : "Planı Oluştur"),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}