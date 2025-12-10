import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart'; 
import 'package:flutter/services.dart'; 
import '../../modeller/ajanda_modelleri.dart';
import 'sayfa_not_ekle.dart'; 

class PagePlanlama extends StatefulWidget {
  final List<Etkinlik> events;
  final String filterType; 
  final Function(Etkinlik, bool) onToggleStatus;
  final Function(int) onDelete;
  final Function(Etkinlik) onEdit;
  final VoidCallback onHeaderTap; 

  const PagePlanlama({
    super.key, 
    required this.events, 
    required this.filterType,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onEdit,
    required this.onHeaderTap, 
  });

  @override
  State<PagePlanlama> createState() => _PagePlanlamaState();
}

class _PagePlanlamaState extends State<PagePlanlama> {
  DateTime _selectedDate = DateTime.now(); 
  late ConfettiController _confettiController; 
  
  int _selectedMood = 0; 
  String _gunlukNot = ""; 

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
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
      setState(() {
        _gunlukNot = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    final filteredAll = widget.events.where((e) {
      final eventDate = e.baslangicTarihi;
      if (widget.filterType == "Bugün") {
        return eventDate.year == _selectedDate.year && 
               eventDate.month == _selectedDate.month && 
               eventDate.day == _selectedDate.day;
      } else if (widget.filterType == "Hafta") {
        final weekDay = _selectedDate.weekday; 
        final startOfWeek = _selectedDate.subtract(Duration(days: weekDay - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final eDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
        final sDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final endDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
        return eDate.compareTo(sDate) >= 0 && eDate.compareTo(endDate) <= 0;
      } else {
        return eventDate.year == _selectedDate.year && eventDate.month == _selectedDate.month;
      }
    }).toList();

    final activeEvents = filteredAll.where((e) => !e.tamamlandiMi).toList();
    final completedEvents = filteredAll.where((e) => e.tamamlandiMi).toList();

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
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick(); 
                  widget.onHeaderTap();
                }, 
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    Text(
                      headerText,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.swap_vert_circle_outlined, color: Colors.grey.withOpacity(0.5), size: 24), 
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            _buildDateStrip(isDark),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Colors.grey), 
            
            Expanded(
              flex: 3, 
              child: activeEvents.isEmpty 
              ? _buildEmptyState("Yapılacak iş kalmadı! 🥳")
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  itemCount: activeEvents.length,
                  itemBuilder: (context, index) {
                    final event = activeEvents[index];
                    return _buildSwipeableCard(event, isDark);
                  },
                ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 240, 
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))],
                  border: Border(top: BorderSide(color: borderColor, width: 1)), 
                ),
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
                              : ListView.builder(
                                  itemCount: completedEvents.length,
                                  itemBuilder: (context, index) {
                                    final event = completedEvents[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              HapticFeedback.mediumImpact(); 
                                              widget.onToggleStatus(event, false);
                                            },
                                            child: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              event.baslik,
                                              style: TextStyle(
                                                fontSize: 12,
                                                decoration: TextDecoration.lineThrough,
                                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
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
                                onTap: () {
                                  HapticFeedback.selectionClick(); 
                                  _openFullNotePage();
                                }, 
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black26 : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: _gunlukNot.isEmpty 
                                    ? const Text(
                                        "Bugün nasıl geçti?\n(Dokun ve yaz...)", 
                                        style: TextStyle(fontSize: 11, color: Colors.grey)
                                      )
                                    : SingleChildScrollView( 
                                        child: Text(
                                          _gunlukNot,
                                          style: TextStyle(fontSize: 12, color: textColor),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            
                            const Divider(height: 16),
                            const Text("Gün Değerlendirmesi", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMoodIcon(1, "😔", Colors.red),
                                _buildMoodIcon(2, "😐", Colors.amber),
                                _buildMoodIcon(3, "😍", Colors.green),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildMoodIcon(int index, String emoji, Color color) {
    final isSelected = _selectedMood == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick(); 
        setState(() => _selectedMood = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSwipeableCard(Etkinlik event, bool isDark) {
    return Dismissible(
      key: Key(event.id.toString()), 
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact(); 
          bool yeniDurum = !event.tamamlandiMi;
          widget.onToggleStatus(event, yeniDurum);
          if (yeniDurum) {
            _celebrate(); 
          }
          return false; 
        } else {
          HapticFeedback.mediumImpact(); 
          widget.onDelete(event.id);
          return false; 
        }
      },
      child: _buildEventCard(event, isDark),
    );
  }

  Widget _buildDateStrip(bool isDark) {
    final now = _selectedDate;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[700];
    
    DateTime startDate;
    int dayCount;

    if (widget.filterType == "Ay") {
      startDate = DateTime(now.year, now.month, 1);
      dayCount = DateTime(now.year, now.month + 1, 0).day;
    } else {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      dayCount = 7;
    }

    return SizedBox(
      height: 70, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dayCount, 
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          DateTime date;
          if (widget.filterType == "Ay") {
             date = startDate.add(Duration(days: index));
          } else {
             date = startDate.add(Duration(days: index));
          }

          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
          
          String topText = DateFormat('E', 'tr_TR').format(date).toUpperCase();
          String bottomText = "${date.day}";

          if (widget.filterType == "Ay") {
             final monthIndex = index + 1;
             final isMonthSelected = monthIndex == _selectedDate.month;
             final tempDate = DateTime(_selectedDate.year, monthIndex, 1);
             final monthName = DateFormat('MMM', 'tr_TR').format(tempDate);
             
             return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick(); 
                  setState(() {
                    _selectedDate = DateTime(_selectedDate.year, monthIndex, 1);
                  });
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isMonthSelected ? const Color(0xFF0055FF).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isMonthSelected ? Border.all(color: const Color(0xFF0055FF), width: 1.5) : null,
                  ),
                  child: Center(
                    child: Text(
                      monthName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isMonthSelected ? const Color(0xFF0055FF) : secondaryTextColor,
                      ),
                    ),
                  ),
                ),
             );
          }

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick(); 
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 48, 
              margin: const EdgeInsets.only(right: 6), 
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0055FF).withOpacity(0.1) : Colors.transparent, 
                borderRadius: BorderRadius.circular(12), 
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    topText, 
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 6), 
                  Text(
                    bottomText,
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: isSelected ? (isDark ? Colors.white : Colors.black) : secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6), 
                  if (isSelected)
                    Container(
                      width: 16, height: 3,
                      decoration: BoxDecoration(color: const Color(0xFF0055FF), borderRadius: BorderRadius.circular(2)),
                    )
                  else
                    const SizedBox(height: 3),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(Etkinlik event, bool isDark) {
    Color priorityColor = _getPriorityColor(event.oncelik);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;

    String dateText;
    if (widget.filterType == "Bugün") {
      dateText = DateFormat('HH:mm', 'tr_TR').format(event.baslangicTarihi);
    } else {
      dateText = DateFormat('d MMM, HH:mm', 'tr_TR').format(event.baslangicTarihi);
    }

    // --- YENİ: HERO ANİMASYONU ---
    // Görev kartını Hero ile sardık. Etiket: 'event-ID'
    return Hero(
      tag: 'event-${event.id}', // Her kartın etiketi benzersiz olmalı
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03), 
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.lightImpact(); // Titreşim
              widget.onEdit(event); // Düzenleme sayfasını aç (Hero tetiklenir)
            }, 
            child: Padding(
              padding: const EdgeInsets.all(16.0), 
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact(); 
                      bool yeniDurum = !event.tamamlandiMi;
                      widget.onToggleStatus(event, yeniDurum);
                      if(yeniDurum) _celebrate(); 
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: event.tamamlandiMi ? priorityColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: event.tamamlandiMi ? priorityColor : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: event.tamamlandiMi ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
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
                            fontSize: 16, fontWeight: FontWeight.w600, 
                            color: event.tamamlandiMi ? Colors.grey.shade400 : titleColor,
                            decoration: event.tamamlandiMi ? TextDecoration.lineThrough : null,
                            decorationColor: priorityColor, 
                          ),
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
                              child: Text(event.oncelik, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade300), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    color: cardColor,
                    onSelected: (val) {
                      HapticFeedback.selectionClick(); 
                      if (val == 'edit') widget.onEdit(event);
                      if (val == 'delete') widget.onDelete(event.id);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20, color: titleColor), const SizedBox(width: 12), Text("Düzenle", style: TextStyle(fontSize: 14, color: titleColor))])),
                      PopupMenuItem(value: 'delete', child: Row(children: const [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 12), Text("Sil", style: TextStyle(color: Colors.red, fontSize: 14))])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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