import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Status bar rengini değiştirmek için
import 'dart:async';
import '../main.dart'; // CheckAuthScreen'e erişmek için

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Status bar'ı şeffaf yapalım ki tasarım tam ekran gözüksün
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Animasyon Kontrolcüsü (2.5 saniye sürsün)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Görünürlük Efekti (0'dan 1'e)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    // Kayma Efekti (Hafif aşağıdan yukarıya)
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );

    _controller.forward();

    // Süre bitince ana kontrol ekranına git
    Timer(const Duration(milliseconds: 3000), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const CheckAuthScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Çıkarken status bar'ı eski haline (koyu ikonlar) getirelim
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arkaplan Gradyanı
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E0D46), // Koyu Lacivert (Formdaki renk)
              Color(0xFF0055FF), // Uygulamanın ana mavisi
            ],
          ),
        ),
        child: Stack(
          children: [
            // MERKEZDEKİ LOGO VE YAZI
            Center(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Kutusu (Glassmorphism benzeri yapı)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1), // Şeffaf beyaz
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded, // Daha kurumsal ikon
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Başlık
                      const Text(
                        "Ajanda App",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          fontFamily: 'Roboto', // Varsa özel font eklenebilir
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Alt Başlık
                      Text(
                        "Planla. Yönet. Başar.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          letterSpacing: 3.0, // Harf aralığını açmak modern gösterir
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ALTTAKİ YÜKLENİYOR ÇUBUĞU VE VERSİYON
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // İnce Progress Bar
                    SizedBox(
                      width: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Versiyon Bilgisi
                    Text(
                      "v1.0.0",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}