import 'dart:ui'; // BackdropFilter için
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart'; 
import 'package:flutter/services.dart'; 
import '../../modeller/ajanda_modelleri.dart'; // GunlukNot modeli burada
import '../../servisler/api_servisi.dart';   // API servisi burada
import 'sayfa_not_ekle.dart'; 
import '../etkinlik_formu.dart'; 

class PagePlanlama extends StatefulWidget {
  final int userId; 
  final List<Etkinlik> events;
  final String filterType; 
  final Function(Etkinlik, bool) onToggleStatus;
  final Function(int) onDelete;
  final Function(Etkinlik) onEdit;
  final Function(Etkinlik) onAdd; 
  final VoidCallback onHeaderTap; 

  const PagePlanlama({
    super.key, 
    required this.userId, 
    required this.events, 
    required this.filterType,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onEdit,
    required this.onAdd, 
    required this.onHeaderTap, 
  });

  @override
  State<PagePlanlama> createState() => _PagePlanlamaState();
}

class _PagePlanlamaState extends State<PagePlanlama> {
  DateTime _selectedDate = DateTime.now(); 
  late ConfettiController _confettiController; 
  final ApiService _api = ApiService();

  // Tüm ayın modlarını tutan Map (Tarih -> Emoji Kodu)
  // key: "2023-12-11", value: 3 (Mutlu)
  final Map<String, int> _monthlyMoods = {};

  String _gunlukNot = ""; 
  int _selectedMood = 0; 
  bool _isLoadingNote = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _loadDailyData(); // Seçili günün verisini çek
  }

  @override
  void didUpdateWidget(covariant PagePlanlama oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterType != oldWidget.filterType) {
      if (widget.filterType == "Bugün" || widget.filterType == "Hafta") {
        setState(() {
          _selectedDate = DateTime.now();
        });
        _loadDailyData(); 
      }
    }
  }

  // --- VERİTABANI İŞLEMLERİ ---

  Future<void> _loadDailyData() async {
    if (!mounted) return;
    setState(() => _isLoadingNote = true);
    
    final noteData = await _api.getDailyNote(widget.userId, _selectedDate);

    if (mounted) {
      setState(() {
        if (noteData != null) {
          _gunlukNot = noteData.notIcerik;
          _selectedMood = noteData.duyguDurumu;
          // Hafızadaki haritayı da güncelle
          String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
          _monthlyMoods[dateKey] = noteData.duyguDurumu;
        } else {
          _gunlukNot = "";
          _selectedMood = 0;
        }
        _isLoadingNote = false;
      });
    }
  }

  Future<void> _saveNote(String note) async {
    setState(() {
      _gunlukNot = note;
    });
    
    final gunlukNot = GunlukNot(
      userId: widget.userId,
      tarih: _selectedDate,
      notIcerik: note,
      duyguDurumu: _selectedMood,
    );
    await _api.saveDailyNote(gunlukNot);
  }

  Future<void> _saveMood(int moodIndex) async {
    int newMood = (_selectedMood == moodIndex) ? 0 : moodIndex;
    
    setState(() {
      _selectedMood = newMood;
      // Takvim görünümü için haritayı güncelle
      String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _monthlyMoods[dateKey] = newMood;
    });

    final gunlukNot = GunlukNot(
      userId: widget.userId,
      tarih: _selectedDate,
      notIcerik: _gunlukNot,
      duyguDurumu: newMood,
    );

    await _api.saveDailyNote(gunlukNot);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _celebrate() {
    _confettiController.play();
  }
  
  void _openFullNotePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SayfaNotEkle(mevcutNot: _gunlukNot),
      ),
    );

    if (result != null) {
      await _saveNote(result);
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset, 1);
    });
    // Ay değişince veriyi sıfırla veya yeni ayı yükle
    _loadDailyData();
  }

  // --- GÜN DETAYI BOTTOM SHEET ---
  void _showDayDetails(BuildContext context, DateTime date, List<Etkinlik> eventsForDay) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Seçilen günün mood'unu al
    String dateKey = DateFormat('yyyy-MM-dd').format(date);
    int currentMoodForDay = _monthlyMoods[dateKey] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      isScrollControlled: true, 
      builder: (context) {
        // BURASI ÇOK ÖNEMLİ: StatefulBuilder ile içerdeki durumu yönetiyoruz
        return StatefulBuilder( 
          builder: (BuildContext context, StateSetter setModalState) {
            
            // Bottom Sheet içindeyken listeyi güncel tutmak için filtreliyoruz
            // Çünkü ana listede değişiklik yapınca burası otomatik render olmayabilir
            // O yüzden 'widget.events' üzerinden tekrar filtreleme yapıyoruz.
            final currentEvents = widget.events.where((e) => 
                e.baslangicTarihi.year == date.year && 
                e.baslangicTarihi.month == date.month && 
                e.baslangicTarihi.day == date.day
            ).toList();

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65, 
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.95), 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5)),
                  ],
                ),
                child: Column(
                  children: [
                    Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(top: 10), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(5)))),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(DateFormat('d MMMM yyyy', 'tr_TR').format(date), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)), Text(DateFormat('EEEE', 'tr_TR').format(date), style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500))]),
                          IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context), color: Colors.grey)
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    
                    // --- MOOD SEÇİCİ (MODAL İÇİNDE) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMoodIconForModal(1, "😔", Colors.red, currentMoodForDay, (val) {
                             setModalState(() => currentMoodForDay = val); // Modal'ı güncelle
                             _saveMood(val); // Ana state'i ve DB'yi güncelle
                          }),
                          _buildMoodIconForModal(2, "😐", Colors.amber, currentMoodForDay, (val) {
                             setModalState(() => currentMoodForDay = val);
                             _saveMood(val);
                          }),
                          _buildMoodIconForModal(3, "😍", Colors.green, currentMoodForDay, (val) {
                             setModalState(() => currentMoodForDay = val);
                             _saveMood(val);
                          }),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    Expanded(
                      child: currentEvents.isEmpty
                          ? _buildEmptyState("Bugün için planın yok.\nDinlenme zamanı! ☕")
                          : ListView.builder(
                              padding: const EdgeInsets.all(16), 
                              itemCount: currentEvents.length, 
                              itemBuilder: (context, index) {
                                // Burada _buildSwipeableCardForModal kullanıyoruz
                                // Bu yeni widget, hem ana listeyi hem de modal'ı günceller
                                return _buildSwipeableCardForModal(
                                  currentEvents[index], 
                                  isDark, 
                                  setModalState // Modal'ın setState'ini gönderiyoruz
                                );
                              }
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final yeniEtkinlik = await Navigator.push<Etkinlik>(
                              context,
                              MaterialPageRoute(builder: (context) => EtkinlikFormu(userId: widget.userId, initialDate: date)),
                            );
                            if (yeniEtkinlik != null) widget.onAdd(yeniEtkinlik);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Bu Güne Ekle"),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0055FF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... Build methodu aynı ...
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    String headerText = "Bugün";
    if (widget.filterType == "Bugün") {
      final now = DateTime.now();
      if (_selectedDate.day == now.day && _selectedDate.month == now.month && _selectedDate.year == now.year) {
        headerText = "Bugün";
      } else {
        headerText = DateFormat('d MMMM', 'tr_TR').format(_selectedDate);
      }
    } else if (widget.filterType == "Hafta") {
      headerText = "Bu Hafta";
    } else {
      headerText = DateFormat('MMMM yyyy', 'tr_TR').format(_selectedDate);
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.filterType == "Ay") IconButton(icon: Icon(Icons.arrow_back_ios, size: 18, color: textColor), onPressed: () => _changeMonth(-1)),
                  InkWell(
                    onTap: () { HapticFeedback.selectionClick(); widget.onHeaderTap(); }, 
                    borderRadius: BorderRadius.circular(12),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Text(headerText, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)), const SizedBox(width: 8), Icon(Icons.swap_vert_circle_outlined, color: Colors.grey.withOpacity(0.5), size: 20)]),
                  ),
                  if (widget.filterType == "Ay") IconButton(icon: Icon(Icons.arrow_forward_ios, size: 18, color: textColor), onPressed: () => _changeMonth(1)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.filterType == "Ay"
                  ? _buildMonthGridView(isDark, cardColor, borderColor, textColor)
                  : _buildDayWeekView(isDark, cardColor, borderColor, textColor),
            ),
          ],
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive, 
          shouldLoop: false, 
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple], 
        ),
      ],
    );
  }

  // --- AY GÖRÜNÜMÜ ---
  Widget _buildMonthGridView(bool isDark, Color cardColor, Color borderColor, Color textColor) {
    final now = _selectedDate;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; 
    final offset = firstWeekday - 1; 

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ["PZT", "SAL", "ÇAR", "PER", "CUM", "CMT", "PAZ"].map((day) => Text(day, style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 12))).toList()),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.8, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: daysInMonth + offset,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox();
              
              final day = index - offset + 1;
              final date = DateTime(now.year, now.month, day);
              final eventsForDay = widget.events.where((e) => e.baslangicTarihi.year == date.year && e.baslangicTarihi.month == date.month && e.baslangicTarihi.day == date.day).toList();
              final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;

              // Mood kontrolü
              String dateKey = DateFormat('yyyy-MM-dd').format(date);
              int mood = _monthlyMoods[dateKey] ?? 0;
              String? moodEmoji;
              if (mood == 1) moodEmoji = "😔";
              else if (mood == 2) moodEmoji = "😐";
              else if (mood == 3) moodEmoji = "😍";

              return GestureDetector(
                onTap: () {
                   setState(() { _selectedDate = date; });
                   _loadDailyData(); 
                   HapticFeedback.selectionClick();
                   _showDayDetails(context, date, eventsForDay);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday ? Border.all(color: const Color(0xFF0055FF), width: 2) : Border.all(color: Colors.transparent),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 6, offset: const Offset(2, 3))],
                  ),
                  child: Stack(
                    children: [
                      // Gün Numarası (Sağ Üst)
                      Positioned(
                        top: 3, right: 6,
                        child: Text("$day", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isToday ? const Color(0xFF0055FF) : textColor.withOpacity(0.8))),
                      ),
                      // Emoji (Sol Alt) veya Görevler
                      Positioned(
                        bottom: 2, left: 4,
                        child: moodEmoji != null 
                          ? Text(moodEmoji, style: const TextStyle(fontSize: 16))
                          : (eventsForDay.isNotEmpty 
                              ? Wrap(spacing: 2, children: eventsForDay.take(3).map((e) => Container(width: 4, height: 4, decoration: BoxDecoration(color: _getPriorityColor(e.oncelik), shape: BoxShape.circle))).toList()) 
                              : const SizedBox()),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- HAFTA/GÜN GÖRÜNÜMÜ ---
  Widget _buildDayWeekView(bool isDark, Color cardColor, Color borderColor, Color textColor) {
    // ... (Eski kodun aynısı) ...
    final filteredAll = widget.events.where((e) {
      final eventDate = e.baslangicTarihi;
      if (widget.filterType == "Bugün") {
        return eventDate.year == _selectedDate.year && eventDate.month == _selectedDate.month && eventDate.day == _selectedDate.day;
      } else if (widget.filterType == "Hafta") {
        final weekDay = _selectedDate.weekday; 
        final startOfWeek = _selectedDate.subtract(Duration(days: weekDay - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final eDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
        final sDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final endDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
        return eDate.compareTo(sDate) >= 0 && eDate.compareTo(endDate) <= 0;
      } else {
        return false;
      }
    }).toList();

    final activeEvents = filteredAll.where((e) => !e.tamamlandiMi).toList();
    final completedEvents = filteredAll.where((e) => e.tamamlandiMi).toList();

    return Column(
      children: [
        _buildDateStrip(isDark),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Colors.grey), 
        Expanded(
          flex: 3, 
          child: activeEvents.isEmpty 
          ? _buildEmptyState("Yapılacak iş kalmadı! 🥳")
          : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), itemCount: activeEvents.length, itemBuilder: (context, index) => _buildSwipeableCard(activeEvents[index], isDark)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 240, 
          child: Container(
            decoration: BoxDecoration(color: cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))], border: Border(top: BorderSide(color: borderColor, width: 1))),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Bitmiş Görevler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                        const Divider(height: 16),
                        Expanded(
                          child: completedEvents.isEmpty
                          ? Center(child: Icon(Icons.check_circle_outline, color: Colors.grey.withOpacity(0.3), size: 40))
                          : ListView.builder(itemCount: completedEvents.length, itemBuilder: (context, index) {
                                final event = completedEvents[index];
                                return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(children: [
                                      GestureDetector(onTap: () { HapticFeedback.mediumImpact(); widget.onToggleStatus(event, false); }, child: const Icon(Icons.check_circle, color: Colors.green, size: 18)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(event.baslik, style: TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: isDark ? Colors.grey[500] : Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    ]));
                              }),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: double.infinity, margin: const EdgeInsets.symmetric(vertical: 20), color: borderColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Güne Not", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0055FF))),
                        const SizedBox(height: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () { HapticFeedback.selectionClick(); _openFullNotePage(); }, 
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.all(12),
                              child: _isLoadingNote 
                                ? const Center(child: CircularProgressIndicator()) 
                                : (_gunlukNot.isEmpty ? const Text("Bugün nasıl geçti?\n(Dokun ve yaz...)", style: TextStyle(fontSize: 11, color: Colors.grey)) : SingleChildScrollView(child: Text(_gunlukNot, style: TextStyle(fontSize: 12, color: textColor)))),
                            ),
                          ),
                        ),
                        const Divider(height: 16),
                        const Text("Gün Değerlendirmesi", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildMoodIcon(1, "😔", Colors.red), _buildMoodIcon(2, "😐", Colors.amber), _buildMoodIcon(3, "😍", Colors.green)])
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widget for Main Screen Mood
  Widget _buildMoodIcon(int index, String emoji, Color color) {
    final isSelected = _selectedMood == index;
    return GestureDetector(onTap: () { HapticFeedback.selectionClick(); _saveMood(index); }, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.2) : Colors.transparent, shape: BoxShape.circle, border: isSelected ? Border.all(color: color, width: 2) : null), child: Text(emoji, style: const TextStyle(fontSize: 22))));
  }

  // Helper Widget for Modal Mood
  Widget _buildMoodIconForModal(int index, String emoji, Color color, int currentMood, Function(int) onSelect) {
    final isSelected = currentMood == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelect(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: color, width: 2) : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Text(emoji, style: TextStyle(fontSize: 28, color: isSelected ? null : Colors.grey.withOpacity(0.5))),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.task_alt, size: 60, color: Colors.grey[300]), const SizedBox(height: 10), Text(message, style: const TextStyle(color: Colors.grey))]));
  }

  Widget _buildSwipeableCard(Etkinlik event, bool isDark) {
    return Dismissible(
      key: Key(event.id.toString()), 
      background: Container(margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Icon(Icons.check_circle, color: Colors.white, size: 32)),
      secondaryBackground: Container(margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white, size: 32)),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact(); bool yeniDurum = !event.tamamlandiMi; widget.onToggleStatus(event, yeniDurum); if(yeniDurum) _celebrate(); return false; 
        } else {
          HapticFeedback.mediumImpact(); widget.onDelete(event.id); return false; 
        }
      },
      child: _buildEventCard(event, isDark),
    );
  }

  // YENİ WIDGET: Modal içinde Swipeable Card (Anlık Güncelleme İçin)
  Widget _buildSwipeableCardForModal(Etkinlik event, bool isDark, StateSetter setModalState) {
    return Dismissible(
      key: Key(event.id.toString()), 
      background: Container(margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Icon(Icons.check_circle, color: Colors.white, size: 32)),
      secondaryBackground: Container(margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white, size: 32)),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact(); 
          bool yeniDurum = !event.tamamlandiMi;
          
          // 1. Veritabanını güncelle
          await widget.onToggleStatus(event, yeniDurum);
          
          // 2. Kutlamayı yap
          if(yeniDurum) _celebrate(); 

          // 3. MODAL STATE'İ GÜNCELLE (Bu satır anlık değişimi sağlar)
          setModalState(() {
             // Event referansı zaten listede olduğu için, durumu değişince listede de değişmiş olur
             // Sadece UI'ı yeniden çizmek (rebuild) yeterli.
          });
          
          return false; // Dismissible'ın kendisi kaybolmasın, biz yönetiyoruz
        } else {
          HapticFeedback.mediumImpact(); 
          await widget.onDelete(event.id);
          setModalState(() {}); // Silince listeden gitmesi için
          return false; 
        }
      },
      child: _buildEventCardForModal(event, isDark, setModalState),
    );
  }

  // YENİ WIDGET: Modal içinde Event Card
  Widget _buildEventCardForModal(Etkinlik event, bool isDark, StateSetter setModalState) {
    Color priorityColor = _getPriorityColor(event.oncelik);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    String dateText = DateFormat('HH:mm', 'tr_TR').format(event.baslangicTarihi);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () { 
            HapticFeedback.lightImpact(); 
            widget.onEdit(event); 
            // Edit dönüşünde de güncelleme gerekebilir ama şimdilik toggle odaklıyız
          }, 
          child: Padding(
            padding: const EdgeInsets.all(16.0), 
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async { 
                    HapticFeedback.mediumImpact(); 
                    bool yeniDurum = !event.tamamlandiMi; 
                    await widget.onToggleStatus(event, yeniDurum); 
                    if(yeniDurum) _celebrate();
                    // State'i güncelle
                    setModalState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), 
                    width: 24, height: 24, 
                    decoration: BoxDecoration(
                      color: event.tamamlandiMi ? priorityColor : Colors.transparent, 
                      borderRadius: BorderRadius.circular(8), 
                      border: Border.all(color: event.tamamlandiMi ? priorityColor : Colors.grey.shade300, width: 2)
                    ), 
                    child: event.tamamlandiMi ? const Icon(Icons.check, color: Colors.white, size: 16) : null
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text(
                        event.baslik, 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600, 
                          color: event.tamamlandiMi ? Colors.grey.shade400 : titleColor, 
                          decoration: event.tamamlandiMi ? TextDecoration.lineThrough : null, 
                          decorationColor: priorityColor
                        )
                      ), 
                      const SizedBox(height: 8), 
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400), 
                          const SizedBox(width: 4), 
                          Text(dateText, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)), 
                          const SizedBox(width: 12), 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                            decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), 
                            child: Text(event.oncelik, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold))
                          )
                        ]
                      )
                    ]
                  )
                ),
                // ... (Popup Menu aynı kalabilir) ...
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateStrip(bool isDark) {
    final now = _selectedDate;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[700];
    DateTime startDate = now.subtract(Duration(days: now.weekday - 1));
    return SizedBox(height: 70, child: ListView.builder(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: 7, padding: const EdgeInsets.symmetric(horizontal: 16), itemBuilder: (context, index) {
          final date = startDate.add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
          return GestureDetector(onTap: () { HapticFeedback.selectionClick(); setState(() { _selectedDate = date; }); _loadDailyData(); }, child: Container(width: 48, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: isSelected ? const Color(0xFF0055FF).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(DateFormat('E', 'tr_TR').format(date).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500])), const SizedBox(height: 6), Text("${date.day}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? (isDark ? Colors.white : Colors.black) : secondaryTextColor)), const SizedBox(height: 6), if (isSelected) Container(width: 16, height: 3, decoration: BoxDecoration(color: const Color(0xFF0055FF), borderRadius: BorderRadius.circular(2))) else const SizedBox(height: 3)])));
    }));
  }

  Widget _buildEventCard(Etkinlik event, bool isDark) {
    // ... (Eski kart tasarımı, Bugün/Hafta görünümü için) ...
    Color priorityColor = _getPriorityColor(event.oncelik);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    String dateText = widget.filterType == "Bugün" ? DateFormat('HH:mm', 'tr_TR').format(event.baslangicTarihi) : DateFormat('d MMM, HH:mm', 'tr_TR').format(event.baslangicTarihi);

    return Hero(tag: 'event-${event.id}', child: Container(margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]), child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(20), onTap: () { HapticFeedback.lightImpact(); widget.onEdit(event); }, child: Padding(padding: const EdgeInsets.all(16.0), child: Row(children: [GestureDetector(onTap: () { HapticFeedback.mediumImpact(); bool yeniDurum = !event.tamamlandiMi; widget.onToggleStatus(event, yeniDurum); if(yeniDurum) _celebrate(); }, child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 24, height: 24, decoration: BoxDecoration(color: event.tamamlandiMi ? priorityColor : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: event.tamamlandiMi ? priorityColor : Colors.grey.shade300, width: 2)), child: event.tamamlandiMi ? const Icon(Icons.check, color: Colors.white, size: 16) : null)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event.baslik, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: event.tamamlandiMi ? Colors.grey.shade400 : titleColor, decoration: event.tamamlandiMi ? TextDecoration.lineThrough : null, decorationColor: priorityColor)), const SizedBox(height: 8), Row(children: [Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400), const SizedBox(width: 4), Text(dateText, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(width: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(event.oncelik, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold)))])])), PopupMenuButton<String>(icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 3, color: cardColor, onSelected: (val) { HapticFeedback.selectionClick(); if (val == 'edit') widget.onEdit(event); if (val == 'delete') widget.onDelete(event.id); }, itemBuilder: (context) => [PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20, color: titleColor), const SizedBox(width: 12), Text("Düzenle", style: TextStyle(fontSize: 14, color: titleColor))])), PopupMenuItem(value: 'delete', child: Row(children: const [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 12), Text("Sil", style: TextStyle(color: Colors.red, fontSize: 14))]))])]))))));
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Yüksek': return Colors.red;
      case 'Orta': return Colors.orange;
      case 'Düşük': return Colors.green;
      default: return Colors.blue;
    }
  }
}