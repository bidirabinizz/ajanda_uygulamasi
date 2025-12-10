import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ana_ekran.dart'; // Ana ekrana yönlendirmek için

class OnboardingScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const OnboardingScreen({super.key, required this.userId, required this.userName});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  // Tanıtım bittiğinde çalışacak fonksiyon
  void _onIntroEnd(context) async {
    // "Kullanıcı tanıtımı gördü" bilgisini hafızaya kaydediyoruz
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    // Ana ekrana git ve geri gelmeyi engelle
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(userId: widget.userId, userName: widget.userName)),
    );
  }

  // Sayfa Tasarımı Yardımcısı
  Widget _buildImage(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 100, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 16.0, color: Colors.grey);
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700, color: Color(0xFF0E0D46)),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
      imageFlex: 2, // Resmin kaplayacağı alan oranı
    );

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: Colors.white,
      allowImplicitScrolling: true,
      // --- SAYFALAR ---
      pages: [
        // 1. Sayfa: Planlama
        PageViewModel(
          title: "Gününü Planla",
          body: "Tüm etkinliklerini, toplantılarını ve özel günlerini kolayca takvime ekle. Karmaşadan kurtul.",
          image: _buildImage(Icons.calendar_month_rounded, const Color(0xFF0055FF)),
          decoration: pageDecoration,
        ),
        // 2. Sayfa: Akış
        PageViewModel(
          title: "Akışını Yönet",
          body: "Yaklaşan etkinliklerini zaman tüneli görünümüyle takip et. Hiçbir şeyi kaçırma.",
          image: _buildImage(Icons.timeline_rounded, const Color(0xFFFFAB40)),
          decoration: pageDecoration,
        ),
        // 3. Sayfa: İstatistik
        PageViewModel(
          title: "Başarılarını Gör",
          body: "Tamamladığın görevleri ve aylık performansını grafiklerle analiz et. Motive ol!",
          image: _buildImage(Icons.pie_chart_rounded, const Color(0xFF69F0AE)),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // "Geç" butonuna basınca da bitsin
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      
      // --- BUTON TASARIMLARI ---
      skip: const Text('Geç', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
      next: const Icon(Icons.arrow_forward, color: Color(0xFF0055FF)),
      done: const Text('Başla', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0055FF))),
      
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
        activeColor: Color(0xFF0055FF), // Aktif nokta rengi
      ),
    );
  }
}