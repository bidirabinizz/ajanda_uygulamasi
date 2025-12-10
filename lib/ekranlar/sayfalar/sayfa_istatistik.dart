import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:intl/intl.dart'; 
import '../../modeller/ajanda_modelleri.dart';

class PageIstatistik extends StatefulWidget {
  final List<Etkinlik> events;
  final String userName;

  const PageIstatistik({super.key, required this.events, required this.userName});

  @override
  State<PageIstatistik> createState() => _PageIstatistikState();
}

class _PageIstatistikState extends State<PageIstatistik> {
  String _selectedFilter = 'Hafta';

  @override
  Widget build(BuildContext context) {
    // --- TEMA AYARLARI (Dedektif Kısmı) ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Renkleri duruma göre belirliyoruz
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white; // Kart rengi
    final textColor = isDark ? Colors.white : Colors.black87; // Yazı rengi
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[500]; // Alt yazı rengi
    final filterBgColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[100]; // Filtre kutusu arkası
    
    // Mesaj kutusu rengi (Açık mavinin koyu versiyonu)
    final messageBoxColor = isDark ? const Color(0xFF1A237E).withOpacity(0.4) : const Color(0xFFF0F4FF);

    // --- HESAPLAMALAR ---
    final total = widget.events.length;
    final completed = widget.events.where((e) => e.tamamlandiMi).length;
    final pending = total - completed;
    final double percent = total == 0 ? 0 : (completed / total);

    final highPriority = widget.events.where((e) => e.oncelik == 'Yüksek').length;
    final mediumPriority = widget.events.where((e) => e.oncelik == 'Orta').length;
    final lowPriority = widget.events.where((e) => e.oncelik == 'Düşük').length;

    // --- GRAFİK VERİSİ ---
    List<Map<String, dynamic>> chartData = [];
    final now = DateTime.now();

    if (_selectedFilter == 'Gün') {
      List<String> labels = ['Gece', 'Sabah', 'Öğle', 'Akşam'];
      chartData = List.generate(4, (index) {
        int startHour = index * 6;
        int endHour = (index + 1) * 6;
        final count = widget.events.where((e) => 
          e.tamamlandiMi &&
          e.baslangicTarihi.day == now.day &&
          e.baslangicTarihi.month == now.month &&
          e.baslangicTarihi.hour >= startHour && 
          e.baslangicTarihi.hour < endHour
        ).length;
        return {'label': labels[index], 'count': count, 'isActive': true};
      });
    } 
    else if (_selectedFilter == 'Hafta') {
      chartData = List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        final dayName = DateFormat('E', 'tr_TR').format(date);
        final count = widget.events.where((e) => 
          e.tamamlandiMi && 
          e.baslangicTarihi.year == date.year && 
          e.baslangicTarihi.month == date.month && 
          e.baslangicTarihi.day == date.day
        ).length;
        return {'label': dayName, 'count': count, 'isActive': index == 6};
      });
    } 
    else if (_selectedFilter == 'Ay') {
      chartData = List.generate(4, (index) {
        int startDay = (index * 7) + 1;
        int endDay = (index + 1) * 7;
        final count = widget.events.where((e) => 
          e.tamamlandiMi &&
          e.baslangicTarihi.month == now.month &&
          e.baslangicTarihi.day >= startDay && 
          e.baslangicTarihi.day <= endDay
        ).length;
        return {'label': "${index + 1}.Hf", 'count': count, 'isActive': true};
      });
    }

    int maxCount = 0;
    for (var item in chartData) {
      if (item['count'] > maxCount) maxCount = item['count'];
    }
    double maxY = (maxCount + 2).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text("Performans Özeti", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text("Bu ayki ilerlemen harika gidiyor!", style: TextStyle(fontSize: 14, color: subTextColor)),
          
          const SizedBox(height: 30),

          // 1. AKTİVİTE GRAFİĞİ KARTI
          Container(
            height: 300,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            decoration: BoxDecoration(
              color: cardColor, // Dinamik Renk
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Aktivite", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: filterBgColor, // Dinamik Filtre Arkası
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: ['Gün', 'Hafta', 'Ay'].map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedFilter = filter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                // Seçiliyse kart rengi (beyaz/koyu), değilse şeffaf
                                color: isSelected ? cardColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF0055FF) : subTextColor,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: false), 
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value.toInt() >= chartData.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  chartData[value.toInt()]['label'],
                                  style: TextStyle(
                                    color: chartData[value.toInt()]['isActive'] ? const Color(0xFF0055FF) : subTextColor,
                                    fontWeight: chartData[value.toInt()]['isActive'] ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false), 
                      borderData: FlBorderData(show: false), 
                      barGroups: chartData.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map data = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: (data['count'] as int).toDouble(),
                              color: data['isActive'] ? const Color(0xFF0055FF) : (isDark ? Colors.grey[800] : const Color(0xFFE0E0E0)),
                              width: _selectedFilter == 'Hafta' ? 16 : 24, 
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY, 
                                color: isDark ? Colors.grey[900] : const Color(0xFFF5F5F5), // Grafik arkası
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. BÜYÜK DAİRESEL GRAFİK KARTI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 160,
                  width: 160,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: 1, 
                        strokeWidth: 12, 
                        color: isDark ? Colors.grey[800] : Colors.grey[100]
                      ),
                      CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 12,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0055FF)),
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "%${(percent * 100).toInt()}",
                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            Text("Tamamlandı", style: TextStyle(fontSize: 12, color: subTextColor)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: messageBoxColor, // Dinamik mesaj kutusu
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    percent > 0.5 
                    ? "Süpersin ${widget.userName}! Hedeflerine çok yakınsın. 🚀" 
                    : "Hadi ${widget.userName}! Küçük adımlarla büyük işler başarabilirsin. 💪",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF0055FF), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. 4'LÜ İSTATİSTİK GRID
          Row(
            children: [
              Expanded(child: _buildInfoCard(title: "Toplam", value: "$total", icon: Icons.folder_open, color: Colors.blue, cardColor: cardColor, textColor: textColor)),
              const SizedBox(width: 16),
              Expanded(child: _buildInfoCard(title: "Biten", value: "$completed", icon: Icons.check_circle_outline, color: Colors.green, cardColor: cardColor, textColor: textColor)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInfoCard(title: "Bekleyen", value: "$pending", icon: Icons.hourglass_empty, color: Colors.orange, cardColor: cardColor, textColor: textColor)),
              const SizedBox(width: 16),
              Expanded(child: _buildInfoCard(
                title: "Başarı", 
                value: total == 0 ? "0.0" : (completed / total * 10.0).toStringAsFixed(1), 
                icon: Icons.star_outline, 
                color: const Color.fromARGB(255, 217, 0, 255),
                cardColor: cardColor,
                textColor: textColor,
                isRating: true
              )),
            ],
          ),

          const SizedBox(height: 30),

          // 4. ÖNCELİK ANALİZİ
          Text("Öncelik Dağılımı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                _buildPriorityBar("Yüksek Öncelik", highPriority, total, const Color(0xFFFF5252), textColor),
                const SizedBox(height: 16),
                _buildPriorityBar("Orta Öncelik", mediumPriority, total, const Color(0xFFFFAB40), textColor),
                const SizedBox(height: 16),
                _buildPriorityBar("Düşük Öncelik", lowPriority, total, const Color(0xFF448AFF), textColor),
              ],
            ),
          ),
          
          const SizedBox(height: 40), 
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value, required IconData icon, required Color color, required Color cardColor, required Color textColor, bool isRating = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
              ),
              if (isRating) 
                const Padding(
                  padding: EdgeInsets.only(bottom: 4, left: 2),
                  child: Text("/10", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
            ],
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPriorityBar(String label, int count, int total, Color color, Color textColor) {
    double percentage = total == 0 ? 0 : count / total;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.8))),
            Text("$count Görev", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}