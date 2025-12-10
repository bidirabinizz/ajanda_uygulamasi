import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'servisler/api_servisi.dart';       
import 'ekranlar/ana_ekran.dart'; 
import 'ekranlar/splash_screen.dart';
import 'ekranlar/tanitim_ekrani.dart';
import 'servisler/tema_yoneticisi.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  final temaYoneticisi = TemaYoneticisi();
  await temaYoneticisi.temayiYukle();

  try {
    await initializeDateFormatting('tr_TR', null); 
  } catch (e) {
    debugPrint('UYARI: Tarih formatı yüklenemedi: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TemaYoneticisi(),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Özel Ajandam',
          
          // --- AÇIK TEMA (Light Mode) ---
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0055FF),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.grey[50], 
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black87),
              titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),

          // --- KOYU TEMA (Dark Mode) ---
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0055FF),
              brightness: Brightness.dark, 
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212), 
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFF1E1E1E), 
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
            // DÜZELTME: cardTheme satırını kaldırdık, Material 3 otomatik halledecek.
            bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Color(0xFF1E1E1E)),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
          ),

          themeMode: TemaYoneticisi().themeMode, 
          
          home: const SplashScreen(),
        );
      },
    );
  }
}

class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({super.key});
  @override
  State<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final userName = prefs.getString('userName');
      final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

      if (userId != null && mounted) {
        if (seenOnboarding) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(userId: userId, userName: userName ?? 'Kullanıcı')),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OnboardingScreen(userId: userId, userName: userName ?? 'Kullanıcı')),
          );
        }
      } else {
        throw Exception("Kullanıcı yok");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// --- GİRİŞ EKRANI ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _api = ApiService();
  
  bool _isLoading = false;
  bool _isObscure = true; 
  bool _rememberMe = false;

  void _login() async {
    setState(() => _isLoading = true);
    final result = await _api.login(_emailController.text, _passController.text);
    setState(() => _isLoading = false);

    if (result != null) {
      final user = result['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', user['id']);
      await prefs.setString('userName', user['ad_soyad']);
      
      if (_rememberMe) {
        await prefs.setBool('rememberMe', true);
      }

      final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

      if (mounted) {
        if (seenOnboarding) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(userId: user['id'], userName: user['ad_soyad'])),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OnboardingScreen(userId: user['id'], userName: user['ad_soyad'])),
          );
        }
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giriş başarısız!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.calendar_month, size: 40, color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(height: 40),
                const Text("Giriş Yap", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 30),
                const Text("Email Adresi", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Mailinizi Giriniz",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Şifre", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    hintText: "Şifrenizi giriniz",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                      onPressed: () { setState(() { _isObscure = !_isObscure; }); },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text("En az 8 harf, rakam ve sembolden oluşmalıdır.", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: const Color(0xFF0055FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) { setState(() => _rememberMe = val!); },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("Beni Hatırla"),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text("Şifremi Unuttum", style: TextStyle(color: Color(0xFF0055FF), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0055FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Giriş Yap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Hesabınız mı yok? ", style: TextStyle(color: Colors.grey[600])),
                      GestureDetector(
                        onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())); },
                        child: const Text("Kayıt olun.", style: TextStyle(color: Color(0xFF0055FF), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- KAYIT EKRANI ---
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _api = ApiService();

  bool _isLoading = false;
  bool _isObscure = true;
  bool _agreedToTerms = false;

  void _register() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen sözleşmeyi kabul ediniz.')));
      return;
    }
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty || _emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tüm alanları doldurunuz.')));
      return;
    }

    setState(() => _isLoading = true);
    String fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";

    final success = await _api.register(fullName, _emailController.text.trim(), _passController.text, "");
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt Başarılı! Giriş yapabilirsin.')));
      Navigator.pop(context); 
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt sırasında hata oluştu.')));
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                    child: Icon(Icons.close, size: 40, color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Kayıt Ol", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Ad", style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextField(controller: _firstNameController, decoration: _inputDecoration("Adınız")),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Soyad", style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextField(controller: _lastNameController, decoration: _inputDecoration("Soyadınız")),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Email", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(controller: _emailController, decoration: _inputDecoration("Mail adresiniz")),
                const SizedBox(height: 20),
                const Text("Password", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passController,
                  obscureText: _isObscure,
                  decoration: _inputDecoration("Şifrenizi giriniz").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        activeColor: const Color(0xFF0055FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) => setState(() => _agreedToTerms = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text("Gizlilik sözleşmesini ve kullanıcı sözleşmesini okudum, kabul ediyorum.", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0055FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Kayıt Ol", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: const TextSpan(
                        text: "Hesabınız var mı? ",
                        style: TextStyle(color: Colors.black54),
                        children: [
                          TextSpan(text: "Giriş yapın.", style: TextStyle(color: Color(0xFF0055FF), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}