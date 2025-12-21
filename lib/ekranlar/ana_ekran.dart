import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servisler/api_servisi.dart';
import '../modeller/ajanda_modelleri.dart';
import '../main.dart'; 
import '../servisler/bildirim_servisi.dart'; // Bildirim servisi eklendi
import 'etkinlik_formu.dart';

import 'sayfalar/sayfa_planlama.dart';
import 'sayfalar/sayfa_akis.dart';
import 'sayfalar/sayfa_istatistik.dart';
import 'sayfalar/sayfa_profil.dart'; 

class HomeScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String userRole; // <-- EKLENDİ

  const HomeScreen({
    super.key, 
    required this.userId, 
    required this.userName,
    required this.userRole, // <-- EKLENDİ
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _api = ApiService();
  List<Etkinlik> _allEvents = []; 
  bool _isLoading = true;
  
  int _selectedIndex = 0; 
  String _planFilterType = "Bugün"; 

  late AnimationController _sheetController;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), 
    );

    // --- BİLDİRİM SERVİSİNİ BAŞLAT ---
    // Artık widget.userRole hatası vermeyecek
    BildirimServisi().init().then((_) {
      if (widget.userRole != 'admin') {
         BildirimServisi().baslat(widget.userId);
      }
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final events = await _api.getEvents(widget.userId);
    if (mounted) {
      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    }
  }

  void _addNewEvent(Etkinlik etkinlik) {
    setState(() {
      _allEvents.add(etkinlik);
    });
  }

  void _openEventForm({Etkinlik? etkinlik}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EtkinlikFormu(
          userId: widget.userId,
          duzenlenecekEtkinlik: etkinlik,
        ),
      ),
    ).then((value) {
      if (value == true || value is Etkinlik) {
        _loadEvents(); 
      }
    });
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Silinsin mi?"),
        content: const Text("Bu planı silmek istiyor musun?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç")),
          TextButton(onPressed: () async {
            Navigator.pop(ctx);
            await _api.deleteEvent(id);
            _loadEvents();
          }, child: const Text("Sil", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    BildirimServisi().durdur(); // Çıkışta durdur
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showProfileSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      transitionAnimationController: _sheetController,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65, 
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))]
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                // ProfilSayfasi'na userId eklendiğini varsayıyorum, önceki adımlarda eklemiştik
                child: ProfilSayfasi(
                  userName: widget.userName, 
                  userId: widget.userId, // Eğer ProfilSayfasi'nda yoksa bunu silin
                  onLogout: _logout
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _cycleFilterMode() {
    setState(() {
      if (_planFilterType == "Bugün") {
        _planFilterType = "Hafta";
      } else if (_planFilterType == "Hafta") {
        _planFilterType = "Ay";
      } else {
        _planFilterType = "Bugün";
      }
    });
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Görünüm: $_planFilterType"), 
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    switch (_selectedIndex) {
      case 0:
        return PagePlanlama(
          userId: widget.userId, 
          events: _allEvents,
          filterType: _planFilterType, 
          onToggleStatus: _toggleStatus, 
          onDelete: _confirmDelete,
          onEdit: (e) => _openEventForm(etkinlik: e),
          onAdd: _addNewEvent, 
          onHeaderTap: _cycleFilterMode, 
        );
      case 1:
        return PageAkis(events: _allEvents); 
      case 2:
        return PageIstatistik(events: _allEvents, userName: widget.userName);
      default:
        return PagePlanlama(
          userId: widget.userId, 
          events: _allEvents,
          filterType: _planFilterType,
          onToggleStatus: _toggleStatus,
          onDelete: _confirmDelete,
          onEdit: (e) => _openEventForm(etkinlik: e),
          onAdd: _addNewEvent, 
          onHeaderTap: _cycleFilterMode,
        );
    }
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      _showProfileSheet(); 
      return; 
    }

    if (index == 0 && _selectedIndex == 0) {
      _cycleFilterMode();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _toggleStatus(Etkinlik event, bool val) async {
    setState(() {
      event.tamamlandiMi = val;
    });
    await _api.toggleEventStatus(event.id, val);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final barColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldColor, 
      body: SafeArea(child: _buildBody()),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEventForm(),
        backgroundColor: const Color(0xFF0055FF), 
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, 

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: barColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: const Color(0xFF0055FF),
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: const Color(0xFF0055FF).withOpacity(0.1),
              color: Colors.grey[500],
              tabs: [
                GButton(
                  icon: Icons.calendar_today_outlined,
                  text: _planFilterType, 
                ),
                const GButton(
                  icon: Icons.timeline,
                  text: '',
                ),
                const GButton(
                  icon: Icons.pie_chart_outline,
                  text: '',
                ),
                const GButton(
                  icon: Icons.person_outline,
                  text: '',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}