import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatı için
import '../servisler/api_servisi.dart';
import '../modeller/ajanda_modelleri.dart';

// --- 1. EKRAN: TALEPLERİM LİSTESİ ---
class DestekTalepleriEkrani extends StatefulWidget {
  final int userId;
  const DestekTalepleriEkrani({super.key, required this.userId});

  @override
  State<DestekTalepleriEkrani> createState() => _DestekTalepleriEkraniState();
}

class _DestekTalepleriEkraniState extends State<DestekTalepleriEkrani> {
  final ApiService _api = ApiService();
  List<Talep> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    final tickets = await _api.getUserTickets(widget.userId);
    if (mounted) {
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    }
  }

  // Yeni Konuşma Başlatma Penceresi
  void _showCreateTicketDialog() {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yeni Destek Talebi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subjectController, decoration: const InputDecoration(labelText: "Konu", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: messageController, decoration: const InputDecoration(labelText: "İlk Mesajınız", border: OutlineInputBorder()), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (subjectController.text.isNotEmpty && messageController.text.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await _api.createTicket(widget.userId, subjectController.text, messageController.text);
                if (success) {
                  _fetchTickets();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Talep oluşturuldu!"), backgroundColor: Colors.green));
                }
              }
            },
            child: const Text("Gönder"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Destek Taleplerim")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTicketDialog,
        child: const Icon(Icons.add_comment),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _tickets.isEmpty 
          ? const Center(child: Text("Henüz bir destek talebiniz yok."))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                final isAnswered = ticket.durum == 'Cevaplandı';
                
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAnswered ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      child: Icon(isAnswered ? Icons.mark_chat_unread : Icons.chat, color: isAnswered ? Colors.green : Colors.grey),
                    ),
                    title: Text(ticket.konu, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "${DateFormat('dd MMM HH:mm').format(ticket.guncellenmeTarihi)} • ${ticket.durum}",
                      style: TextStyle(color: isAnswered ? Colors.green : Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Sohbet Ekranına Git
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => TalepSohbetEkrani(ticket: ticket))
                      ).then((_) => _fetchTickets()); // Geri dönünce listeyi yenile
                    },
                  ),
                );
              },
            ),
    );
  }
}

// --- 2. EKRAN: SOHBET (CHAT) EKRANI ---
class TalepSohbetEkrani extends StatefulWidget {
  final Talep ticket;
  const TalepSohbetEkrani({super.key, required this.ticket});

  @override
  State<TalepSohbetEkrani> createState() => _TalepSohbetEkraniState();
}

class _TalepSohbetEkraniState extends State<TalepSohbetEkrani> {
  final ApiService _api = ApiService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<TalepMesaji> _messages = [];
  bool _isLoading = true;
  Timer? _timer; // Otomatik yenileme için

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // 3 saniyede bir mesajları arka planda yenile (Canlı sohbet hissi)
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final msgs = await _api.getTicketMessages(widget.ticket.id);
    if (mounted) {
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      // İlk yüklemede veya yeni mesaj geldiğinde en aşağı kaydır
      if (!silent && _messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;
    
    final text = _msgController.text;
    _msgController.clear(); // Hemen temizle

    // Ekrana geçici (fake) olarak ekle ki hızlı görünsün
    setState(() {
      _messages.add(TalepMesaji(
        id: 0, 
        talepId: widget.ticket.id, 
        gonderenTipi: 'user', 
        mesaj: text, 
        tarih: DateTime.now()
      ));
    });
    _scrollToBottom();

    // Sunucuya gönder
    final success = await _api.sendMessage(widget.ticket.id, text);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mesaj gönderilemedi!")));
    } else {
      _loadMessages(silent: true); // Gerçek veriyi çek
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ticket.konu, style: const TextStyle(fontSize: 16)),
            const Text("Destek Sohbeti", style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          // MESAJ LİSTESİ
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg.gonderenTipi == 'user';
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFDCF8C6) : Colors.white, // WhatsApp renkleri
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              msg.mesaj,
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(msg.tarih),
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          
          // MESAJ YAZMA ALANI
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: "Mesaj yazın...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF0055FF),
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}