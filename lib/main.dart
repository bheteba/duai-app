import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  runApp(const DuaiApp());
}

final supabase =
    SupabaseConfig.isConfigured ? Supabase.instance.client : null;

const Color green = Color(0xFF079B70);
const Color dark = Color(0xFF17352C);
const Color bg = Color(0xFFF4F8F6);

class DuaiApp extends StatelessWidget {
  const DuaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دوائي',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: bg,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2ECE8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: green, width: 1.5),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class Medicine {
  final String name;
  final String strength;
  final String qty;
  final String expiry;
  final String area;
  final bool free;

  const Medicine({
    required this.name,
    required this.strength,
    required this.qty,
    required this.expiry,
    required this.area,
    this.free = false,
  });
}

final List<Medicine> medicines = [
  const Medicine(
    name: 'Augmentin',
    strength: '625 mg',
    qty: '2 شرائط',
    expiry: '08/2027',
    area: 'مدينة نصر - القاهرة',
  ),
  const Medicine(
    name: 'Panadol',
    strength: '500 mg',
    qty: '1 شريط',
    expiry: '06/2028',
    area: 'مصر الجديدة - القاهرة',
    free: true,
  ),
  const Medicine(
    name: 'Vitamin C',
    strength: '1000 mg',
    qty: '3 شرائط',
    expiry: '11/2027',
    area: 'المعادي - القاهرة',
  ),
];

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured || supabase == null) {
      return const BackendSetupPage();
    }

    return StreamBuilder<AuthState>(
      stream: supabase!.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase!.auth.currentSession;

        if (session != null) {
          return const AppShell();
        }

        return const LoginPage();
      },
    );
  }
}

class BackendSetupPage extends StatelessWidget {
  const BackendSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '💊',
                    style: TextStyle(fontSize: 65),
                  ),
                  const Text(
                    'دوائي',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'شارك الفائض، وابحث عما تحتاج',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'بيانات Supabase لم تتم إضافتها بعد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  bool obscure = true;
  String? error;

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() {
        error = 'اكتب البريد الإلكتروني وكلمة المرور';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await supabase!.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
    } on AuthException catch (e) {
      setState(() {
        error = e.message;
      });
    } catch (_) {
      setState(() {
        error = 'حدث خطأ في الاتصال بالخادم';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    '💊',
                    style: TextStyle(fontSize: 75),
                  ),
                  const Text(
                    'دوائي',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'شارك الفائض، وابحث عما تحتاج',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            obscure = !obscure;
                          });
                        },
                      ),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading ? null : login,
                      child: Text(
                        loading ? 'جارٍ الدخول...' : 'تسجيل الدخول',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: loading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                      child: const Text('إنشاء حساب جديد'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController();
  final city = TextEditingController(text: 'القاهرة');
  final area = TextEditingController();

  bool loading = false;
  String? message;

  Future<void> register() async {
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.length < 6) {
      setState(() {
        message = 'أدخل الاسم والبريد وكلمة مرور من 6 أحرف على الأقل';
      });
      return;
    }

    setState(() {
      loading = true;
      message = null;
    });

    try {
      final result = await supabase!.auth.signUp(
        email: email.text.trim(),
        password: password.text
