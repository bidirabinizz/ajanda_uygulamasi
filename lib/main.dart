import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'servisler/api_servisi.dart';       
import 'ekranlar/ana_ekran.dart'; 
import 'ekranlar/splash_screen.dart';
import 'ekranlar/tanitim_ekrani.dart';
import 'ekranlar/admin_paneli.dart'; 
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
      final userRole = prefs.getString('userRole'); 
      final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

      if (userId != null && mounted) {
        if (seenOnboarding) {
           if (userRole == 'admin') {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminPaneli(adminName: userName ?? 'Admin')));
           } else {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(
               userId: userId, 
               userName: userName ?? 'Kullanıcı',
               userRole: userRole ?? 'user',
             )));
           }
        } else {
          // --- DÜZELTİLEN KISIM ---
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OnboardingScreen(
              userId: userId, 
              userName: userName ?? 'Kullanıcı',
              userRole: userRole ?? 'user', // EKLENDİ
            )),
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiService();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);

    final result = await _api.login(_emailController.text, _passwordController.text);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      String unvan = 'user';
      int userId = 0;
      String userName = 'Kullanıcı';

      if (result.containsKey('user') && result['user'] is Map) {
        final userObj = result['user'];
        unvan = userObj['unvan'] ?? userObj['role'] ?? 'user';
        userId = userObj['id'];
        userName = userObj['ad_soyad'];
      } else {
        unvan = result['role'] ?? result['unvan'] ?? 'user';
        userId = result['userId'];
        userName = result['userName'];
      }
      
      unvan = unvan.toString().toLowerCase().trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', userId);
      await prefs.setString('userName', userName);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRole', unvan); 

      if (mounted) {
        if (unvan == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminPaneli(adminName: userName)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(
              userId: userId, 
              userName: userName,
              userRole: unvan,
            )),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Giriş başarısız.')),
        );
      }
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.calendar_month_rounded, size: 80, color: const Color(0xFF0055FF)),
              const SizedBox(height: 16),
              Text(
                "Tekrar Hoşgeldiniz!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                "Planlarınıza erişmek için giriş yapın.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "E-posta",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0055FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    shadowColor: const Color(0xFF0055FF).withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Giriş Yap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Hesabınız yok mu?", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: _goToRegister,
                    child: const Text("Hemen Kayıt Olun", style: TextStyle(color: Color(0xFF0055FF), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiService();
  bool _isLoading = false;

  void _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tüm alanları doldurun.')));
      return;
    }

    setState(() => _isLoading = true);

    final success = await _api.register(
      _nameController.text, 
      _emailController.text, 
      _passwordController.text, 
      "user" 
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt başarılı! Giriş yapabilirsiniz.')));
        Navigator.pop(context); 
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt başarısız. E-posta kullanımda olabilir.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Aramıza Katılın 🚀", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Planlı bir hayata ilk adımınızı atın.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              
              TextField(controller: _nameController, decoration: InputDecoration(labelText: "Ad Soyad", prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
              const SizedBox(height: 16),
              TextField(controller: _emailController, decoration: InputDecoration(labelText: "E-posta", prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: "Şifre", prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
              const SizedBox(height: 24),
              
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0055FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Kayıt Ol", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      children: [TextSpan(text: "Giriş yapın.", style: TextStyle(color: Color(0xFF0055FF), fontWeight: FontWeight.bold))],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}