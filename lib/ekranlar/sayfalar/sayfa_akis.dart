import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../modeller/ajanda_modelleri.dart';

class PageAkis extends StatelessWidget {
  final List<Etkinlik> events;
  const PageAkis({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    // Sadece tarihi geçmemişleri al ve sırala
    final upcomingEvents = events.where((e) => e.baslangicTarihi.isAfter(DateTime.now())).toList()
      ..sort((a, b) => a.baslangicTarihi.compareTo(b.baslangicTarihi));

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text("Zaman Tüneli", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: upcomingEvents.isEmpty
            ? Center(child: Text("Yakın zamanda etkinlik görünmüyor.", style: TextStyle(color: Colors.grey[500])))
            : ListView.builder(
                itemCount: upcomingEvents.length,
                itemBuilder: (context, index) {
                  final event = upcomingEvents[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Text(DateFormat('dd', 'tr_TR').format(event.baslangicTarihi), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text(DateFormat('MMM', 'tr_TR').format(event.baslangicTarihi), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Container(width: 2, height: 40, color: const Color(0xFF0055FF).withOpacity(0.3)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.baslik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(event.aciklama ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        )
                      ],
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