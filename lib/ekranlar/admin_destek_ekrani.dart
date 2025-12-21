import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../servisler/api_servisi.dart';
import '../modeller/ajanda_modelleri.dart';

// --- 1. EKRAN: TÜM TALEPLER LİSTESİ (ADMIN) ---
class AdminDestekEkrani extends StatefulWidget {
  const AdminDestekEkrani({super.key});

  @override
  State<AdminDestekEkrani> createState() => _AdminDestekEkraniState();
}

class _AdminDestekEkraniState extends State<AdminDestekEkrani> {
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
    final tickets = await _api.getAllTickets();
    if (mounted) {
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gelen Destek Talepleri"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _tickets.isEmpty 
          ? const Center(child: Text("Henüz destek talebi yok."))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                // Bekleyen mesajlar daha dikkat çekici olsun
                final isWaiting = ticket.durum == 'Bekliyor';
                
                return Card(
                  color: isWaiting ? Colors.orange.shade50 : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isWaiting ? Colors.orange : Colors.grey,
                      child: Text(ticket.kullaniciAdi?[0].toUpperCase() ?? "?", style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(ticket.kullaniciAdi ?? "Bilinmeyen Kullanıcı", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ticket.konu, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          "${DateFormat('dd MMM HH:mm').format(ticket.guncellenmeTarihi)} • ${ticket.durum}",
                          style: TextStyle(fontSize: 12, color: isWaiting ? Colors.red : Colors.grey),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Admin Sohbet Ekranına Git
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => AdminSohbetEkrani(ticket: ticket))
                      ).then((_) => _fetchTickets()); // Dönünce listeyi yenile
                    },
                  ),
                );
              },
            ),
    );
  }
}

// --- 2. EKRAN: ADMİN SOHBET EKRANI ---
class AdminSohbetEkrani extends StatefulWidget {
  final Talep ticket;
  const AdminSohbetEkrani({super.key, required this.ticket});

  @override
  State<AdminSohbetEkrani> createState() => _AdminSohbetEkraniState();
}

class _AdminSohbetEkraniState extends State<AdminSohbetEkrani> {
  final ApiService _api = ApiService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<TalepMesaji> _messages = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Canlı sohbet için 3 saniyede bir yenile
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
    _msgController.clear();

    // Ekrana geçici ekle
    setState(() {
      _messages.add(TalepMesaji(
        id: 0, 
        talepId: widget.ticket.id, 
        gonderenTipi: 'admin', // GÖNDEREN ADMİN
        mesaj: text, 
        tarih: DateTime.now()
      ));
    });
    _scrollToBottom();

    // Sunucuya 'admin' olarak gönder
    final success = await _api.sendMessage(widget.ticket.id, text, gonderenTipi: 'admin');
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mesaj gönderilemedi!")));
    } else {
      _loadMessages(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ticket.kullaniciAdi ?? "Kullanıcı", style: const TextStyle(fontSize: 16)),
            Text(widget.ticket.konu, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    // Admin için: 'admin' biziz (sağ taraf), 'user' karşı taraf (sol taraf)
                    final isMe = msg.gonderenTipi == 'admin';
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal.shade100 : Colors.white,
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
                            Text(msg.mesaj, style: const TextStyle(fontSize: 16)),
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
          // Mesaj Yazma Alanı
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: "Cevap yaz...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
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