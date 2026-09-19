import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

SupabaseClient? get supabase =>
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
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: dark,
          elevation: 0,
        ),
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

// ============================================================
// MODEL
// ============================================================

class Medicine {
  final String? id;
  final String name;
  final String strength;
  final String qty;
  final String expiry;
  final String area;
  final bool free;
  final String? imageUrl;

  const Medicine({
    this.id,
    required this.name,
    required this.strength,
    required this.qty,
    required this.expiry,
    required this.area,
    this.free = false,
    this.imageUrl,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      strength: json['strength'] ?? '',
      qty: json['qty'] ?? '',
      expiry: json['expiry'] ?? '',
      area: json['area'] ?? '',
      free: json['free'] ?? false,
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'strength': strength,
      'qty': qty,
      'expiry': expiry,
      'area': area,
      'free': free,
      'image_url': imageUrl,
    };
  }
}

// ============================================================
// AUTH GATE
// ============================================================

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
        final session = snapshot.data?.session ?? supabase!.auth.currentSession;

        if (session != null) {
          return const AppShell();
        }

        return const LoginPage();
      },
    );
  }
}

// ============================================================
// BACKEND SETUP
// ============================================================

class BackendSetupPage extends StatelessWidget {
  const BackendSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('💊', style: TextStyle(fontSize: 70)),
                SizedBox(height: 8),
                Text(
                  'دوائي',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: green,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'شارك الفائض، وابحث عما تحتاج',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                Text(
                  'يرجى إضافة بيانات Supabase داخل ملف supabase_config.dart',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

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

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

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
      if (!mounted) return;
      setState(() {
        error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('💊', style: TextStyle(fontSize: 75)),
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
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: Text(
                      loading ? 'جارٍ الدخول...' : 'تسجيل الدخول',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
    );
  }
}

// ============================================================
// REGISTER
// ============================================================

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
  bool success = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    phone.dispose();
    city.dispose();
    area.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.length < 6) {
      setState(() {
        message = 'أدخل الاسم والبريد وكلمة مرور من 6 أحرف على الأقل';
        success = false;
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
        password: password.text,
        data: {
          'full_name': name.text.trim(),
          'phone': phone.text.trim(),
          'city': city.text.trim(),
          'area': area.text.trim(),
          'country': 'EG',
        },
      );

      if (!mounted) return;

      if (result.session == null) {
        setState(() {
          message =
              'تم إنشاء الحساب. افتح رسالة التفعيل بالبريد ثم سجّل الدخول.';
          success = true;
        });
      } else {
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        message = e.message;
        success = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        message = 'حدث خطأ في إنشاء الحساب';
        success = false;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'الاسم الكامل',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: city,
            decoration: const InputDecoration(
              labelText: 'المحافظة / المدينة',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: area,
            decoration: const InputDecoration(
              labelText: 'المنطقة',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: success ? green : Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: loading ? null : register,
              child: Text(
                loading ? 'جارٍ إنشاء الحساب...' : 'إنشاء الحساب',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// APP SHELL
// ============================================================

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;

  void open(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onSearch: () => setState(() => tab = 1),
        onAdd: () => setState(() => tab = 2),
        onRequests: () => setState(() => tab = 3),
        open: open,
      ),
      SearchPage(open: open),
      AddMedicinePage(
        onPublished: () => setState(() => tab = 0),
      ),
      RequestsPage(open: open),
      const AccountPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) {
          setState(() {
            tab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'البحث',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'إضافة',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'الطلبات',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatefulWidget {
  final VoidCallback onSearch;
  final VoidCallback onAdd;
  final VoidCallback onRequests;
  final void Function(Widget) open;

  const HomePage({
    super.key,
    required this.onSearch,
    required this.onAdd,
    required this.onRequests,
    required this.open,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Medicine> _medicines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
  }

  Future<void> _fetchMedicines() async {
    setState(() => _loading = true);
    try {
      final response = await supabase
          ?.from('medicines')
          .select()
          .order('created_at', ascending: false);
      if (response != null && mounted) {
        setState(() {
          _medicines =
              (response as List).map((e) => Medicine.fromJson(e)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchMedicines,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحبًا 👋',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: dark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'شارك الفائض وابحث عما تحتاج',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لا توجد إشعارات جديدة'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: widget.onSearch,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2ECE8),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: green),
                    SizedBox(width: 10),
                    Text(
                      'ابحث عن دواء...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ActionCard(
                    icon: Icons.add_box_outlined,
                    title: 'إضافة دواء',
                    subtitle: 'شارك دواء زائد',
                    onTap: widget.onAdd,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionCard(
                    icon: Icons.search,
                    title: 'البحث',
                    subtitle: 'ابحث عن دواء',
                    onTap: widget.onSearch,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ActionCard(
              icon: Icons.receipt_long_outlined,
              title: 'طلبات التبادل',
              subtitle: 'تابع طلباتك',
              onTap: widget.onRequests,
            ),
            const SizedBox(height: 24),
            const Text(
              'أدوية متاحة الآن',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: dark,
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_medicines.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'لا توجد أدوية مضافة حالياً',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._medicines.map(
                (medicine) => MedicineCard(
                  medicine: medicine,
                  onTap: () {
                    widget.open(MedicineDetailsPage(medicine: medicine));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ACTION CARD
// ============================================================

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2ECE8),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: green.withOpacity(.10),
              child: Icon(icon, color: green),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MEDICINE CARD
// ============================================================

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty
              ? Image.network(
                  medicine.imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const CircleAvatar(
                    backgroundColor: Color(0xFFE5F5EF),
                    child: Icon(Icons.medication_outlined, color: green),
                  ),
                )
              : const CircleAvatar(
                  backgroundColor: Color(0xFFE5F5EF),
                  child: Icon(Icons.medication_outlined, color: green),
                ),
        ),
        title: Text(
          '${medicine.name} ${medicine.strength}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${medicine.qty} • تنتهي ${medicine.expiry}\n${medicine.area}',
        ),
        isThreeLine: true,
        trailing: medicine.free
            ? const Chip(label: Text('مجاني'))
            : const Icon(Icons.chevron_left),
      ),
    );
  }
}

// ============================================================
// SEARCH
// ============================================================

class SearchPage extends StatefulWidget {
  final void Function(Widget) open;

  const SearchPage({super.key, required this.open});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final search = TextEditingController();
  List<Medicine> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _loading = true);

    try {
      final builder = supabase?.from('medicines').select();
      final response = query.trim().isEmpty
          ? await builder
          : await builder?.ilike('name', '%${query.trim()}%');

      if (response != null && mounted) {
        setState(() {
          _results =
              (response as List).map((e) => Medicine.fromJson(e)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'البحث عن دواء',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: dark,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: search,
            onChanged: _performSearch,
            decoration: const InputDecoration(
              hintText: 'اكتب اسم الدواء',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_results.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'لا توجد أدوية مطابقة للبحث',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._results.map(
              (medicine) => MedicineCard(
                medicine: medicine,
                onTap: () {
                  widget.open(MedicineDetailsPage(medicine: medicine));
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// MEDICINE DETAILS
// ============================================================

class MedicineDetailsPage extends StatelessWidget {
  final Medicine medicine;

  const MedicineDetailsPage({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الدواء')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                medicine.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.medication, size: 90, color: green),
              ),
            )
          else
            const Icon(Icons.medication, size: 90, color: green),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${medicine.name} ${medicine.strength}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: dark,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Info(title: 'الكمية', value: medicine.qty),
          Info(title: 'تاريخ الانتهاء', value: medicine.expiry),
          Info(title: 'الموقع', value: medicine.area),
          Info(title: 'طريقة التبادل', value: medicine.free ? 'مجاني' : 'تبادل'),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExchangeRequestPage(medicine: medicine),
                  ),
                );
              },
              child: const Text('إرسال طلب'),
            ),
          ),
        ],
      ),
    );
  }
}

class Info extends StatelessWidget {
  final String title;
  final String value;

  const Info({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.grey)),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ADD MEDICINE
// ============================================================

class AddMedicinePage extends StatefulWidget {
  final VoidCallback onPublished;

  const AddMedicinePage({super.key, required this.onPublished});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final name = TextEditingController();
  final strength = TextEditingController();
  final quantity = TextEditingController();
  final expiry = TextEditingController();
  final area = TextEditingController();

  XFile? _pickedXFile;

  @override
  void dispose() {
    name.dispose();
    strength.dispose();
    quantity.dispose();
    expiry.dispose();
    area.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _pickedXFile = picked;
      });
    }
  }

  Widget _buildImagePreview() {
    if (_pickedXFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_a_photo_outlined, color: green, size: 36),
          SizedBox(height: 8),
          Text('اضغط لإضافة صورة الدواء', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(_pickedXFile!.path,
            fit: BoxFit.cover, width: double.infinity),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(File(_pickedXFile!.path),
            fit: BoxFit.cover, width: double.infinity),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'إضافة دواء',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: dark,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2ECE8)),
              ),
              child: _buildImagePreview(),
            ),
          ),
          const SizedBox(height: 14),
          AppField(controller: name, label: 'اسم الدواء'),
          const SizedBox(height: 10),
          AppField(controller: strength, label: 'التركيز'),
          const SizedBox(height: 10),
          AppField(controller: quantity, label: 'الكمية'),
          const SizedBox(height: 10),
          AppField(controller: expiry, label: 'تاريخ الانتهاء'),
          const SizedBox(height: 10),
          AppField(controller: area, label: 'المنطقة'),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty ||
                    strength.text.trim().isEmpty ||
                    quantity.text.trim().isEmpty ||
                    expiry.text.trim().isEmpty ||
                    area.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('من فضلك أكمل جميع البيانات'),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VerifyPage(
                      name: name.text.trim(),
                      strength: strength.text.trim(),
                      quantity: quantity.text.trim(),
                      expiry: expiry.text.trim(),
                      area: area.text.trim(),
                      pickedXFile: _pickedXFile,
                      onPublished: widget.onPublished,
                    ),
                  ),
                );
              },
              child: const Text('متابعة'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WIDGETS & REMAINING PAGES
// ============================================================

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class VerifyPage extends StatefulWidget {
  final String name;
  final String strength;
  final String quantity;
  final String expiry;
  final String area;
  final XFile? pickedXFile;
  final VoidCallback onPublished;

  const VerifyPage({
    super.key,
    required this.name,
    required this.strength,
    required this.quantity,
    required this.expiry,
    required this.area,
    this.pickedXFile,
    required this.onPublished,
  });

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  bool loading = false;

  Future<void> publish() async {
    setState(() => loading = true);

    try {
      String? imageUrl;

      if (widget.pickedXFile != null && supabase != null) {
        final fileExt = widget.pickedXFile!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        if (kIsWeb) {
          final bytes = await widget.pickedXFile!.readAsBytes();
          await supabase!.storage
              .from('medicine_images')
              .uploadBinary(fileName, bytes);
        } else {
          await supabase!.storage
              .from('medicine_images')
              .upload(fileName, File(widget.pickedXFile!.path));
        }

        imageUrl = supabase!.storage
            .from('medicine_images')
            .getPublicUrl(fileName);
      }

      if (supabase != null) {
        await supabase!.from('medicines').insert({
          'name': widget.name,
          'strength': widget.strength,
          'qty': widget.quantity,
          'expiry': widget.expiry,
          'area': widget.area,
          'free': false,
          'image_url': imageUrl,
          'user_id': supabase!.auth.currentUser?.id,
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onPublished();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء النشر: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة وتأكيد البيانات')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (widget.pickedXFile != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(
                                widget.pickedXFile!.path,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(widget.pickedXFile!.path),
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Info(title: 'اسم الدواء', value: widget.name),
                    Info(title: 'التركيز', value: widget.strength),
                    Info(title: 'الكمية', value: widget.quantity),
                    Info(title: 'تاريخ الانتهاء', value: widget.expiry),
                    Info(title: 'المنطقة', value: widget.area),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: loading ? null : publish,
                child:
                    Text(loading ? 'جارٍ النشر والرفع...' : 'نشر الدواء الآن'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExchangeRequestPage extends StatefulWidget {
  final Medicine medicine;

  const ExchangeRequestPage({super.key, required this.medicine});

  @override
  State<ExchangeRequestPage> createState() => _ExchangeRequestPageState();
}

class _ExchangeRequestPageState extends State<ExchangeRequestPage> {
  final noteController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> sendRequest() async {
    setState(() => loading = true);

    try {
      if (supabase != null) {
        await supabase!.from('requests').insert({
          'medicine_id': widget.medicine.id,
          'medicine_name': widget.medicine.name,
          'note': noteController.text.trim(),
          'user_id': supabase!.auth.currentUser?.id,
          'status': 'قيد الانتظار',
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب التبادل بنجاح')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الإرسال: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إرسال طلب تبادل')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'طلب الحصول على: ${widget.medicine.name} ${widget.medicine.strength}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: dark,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'اكتب ملاحظة أو تفاصيل التواصل الخاصة بك...',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: loading ? null : sendRequest,
              child: Text(loading ? 'جارٍ الإرسال...' : 'تأكيد وإرسال'),
            ),
          ),
        ],
      ),
    );
  }
}

class RequestsPage extends StatefulWidget {
  final void Function(Widget) open;

  const RequestsPage({super.key, required this.open});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _loading = true);
    final userId = supabase?.auth.currentUser?.id;

    try {
      final response = await supabase
          ?.from('requests')
          .select()
          .eq('user_id', userId ?? '')
          .order('created_at', ascending: false);

      if (response != null && mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>::from(response);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'طلبات التبادل',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: dark,
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_requests.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'لا توجد طلبات حالية',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._requests.map((req) {
                return Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.swap_horiz, color: green),
                    title: Text(req['medicine_name'] ?? 'طلب دواء'),
                    subtitle: Text('الحالة: ${req['status'] ?? 'قيد الانتظار'}'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase?.auth.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'حسابي',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: dark,
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundColor: green.withOpacity(0.1),
            child: const Icon(Icons.person, size: 40, color: green),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user?.email ?? 'مستخدم دوائي',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Card(
            color: Colors.white,
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                if (supabase != null) {
                  await supabase!.auth.signOut();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
