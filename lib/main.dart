import 'package:flutter/material.dart';
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

final SupabaseClient? supabase =
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
            borderSide: const BorderSide(
              color: Color(0xFFE2ECE8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: green,
              width: 1.5,
            ),
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
  Medicine(
    name: 'Augmentin',
    strength: '625 mg',
    qty: '2 شرائط',
    expiry: '08/2027',
    area: 'مدينة نصر - القاهرة',
  ),
  Medicine(
    name: 'Panadol',
    strength: '500 mg',
    qty: '1 شريط',
    expiry: '06/2028',
    area: 'مصر الجديدة - القاهرة',
    free: true,
  ),
  Medicine(
    name: 'Vitamin C',
    strength: '1000 mg',
    qty: '3 شرائط',
    expiry: '11/2027',
    area: 'المعادي - القاهرة',
  ),
];

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
        final session = supabase!.auth.currentSession;

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    '💊',
                    style: TextStyle(fontSize: 70),
                  ),
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
              'تم إنشاء الحساب. إذا كان تأكيد البريد مفعّلًا، افتح رسالة البريد ثم سجّل الدخول.';
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                labelText: 'رقم الهاتف المصري',
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

  final List<String> requests = [
    'طلب تبادل Augmentin',
  ];

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
      RequestsPage(
        requests: requests,
        open: open,
      ),
      const AccountPage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: pages[tab],
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
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SafeArea(
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
            onTap: onSearch,
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
                  onTap: onAdd,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionCard(
                  icon: Icons.search,
                  title: 'البحث',
                  subtitle: 'ابحث عن دواء',
                  onTap: onSearch,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ActionCard(
            icon: Icons.receipt_long_outlined,
            title: 'طلبات التبادل',
            subtitle: 'تابع طلباتك',
            onTap: onRequests,
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
          ...medicines.map(
            (medicine) => MedicineCard(
              medicine: medicine,
              onTap: () {
                open(
                  MedicineDetailsPage(
                    medicine: medicine,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE5F5EF),
          child: Icon(
            Icons.medication_outlined,
            color: green,
          ),
        ),
        title: Text(
          '${medicine.name} ${medicine.strength}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${medicine.qty} • تنتهي ${medicine.expiry}\n${medicine.area}',
        ),
        isThreeLine: true,
        trailing: medicine.free
            ? const Chip(
                label: Text('مجاني'),
              )
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

  const SearchPage({
    super.key,
    required this.open,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();

    final results = medicines.where((medicine) {
      if (query.isEmpty) return true;

      return medicine.name.toLowerCase().contains(query) ||
          medicine.strength.toLowerCase().contains(query) ||
          medicine.area.toLowerCase().contains(query);
    }).toList();

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
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'اكتب اسم الدواء',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 18),
          if (results.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'لا توجد أدوية مطابقة للبحث',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ...results.map(
            (medicine) => MedicineCard(
              medicine: medicine,
              onTap: () {
                widget.open(
                  MedicineDetailsPage(
                    medicine: medicine,
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

// ============================================================
// MEDICINE DETAILS
// ============================================================

class MedicineDetailsPage extends StatelessWidget {
  final Medicine medicine;

  const MedicineDetailsPage({
    super.key,
    required this.medicine,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الدواء'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Icon(
            Icons.medication,
            size: 90,
            color: green,
          ),
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
          Info(
            title: 'الكمية',
            value: medicine.qty,
          ),
          Info(
            title: 'تاريخ الانتهاء',
            value: medicine.expiry,
          ),
          Info(
            title: 'الموقع',
            value: medicine.area,
          ),
          Info(
            title: 'طريقة التبادل',
            value: medicine.free ? 'مجاني' : 'تبادل',
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExchangeRequestPage(
                      medicine: medicine,
                    ),
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

  const Info({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.grey),
        ),
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

  const AddMedicinePage({
    super.key,
    required this.onPublished,
  });

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final name = TextEditingController();
  final strength = TextEditingController();
  final quantity = TextEditingController();
  final expiry = TextEditingController();
  final area = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    strength.dispose();
    quantity.dispose();
    expiry.dispose();
    area.dispose();
    super.dispose();
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
          AppField(
            controller: name,
            label: 'اسم الدواء',
          ),
          const SizedBox(height: 10),
          AppField(
            controller: strength,
            label: 'التركيز',
          ),
          const SizedBox(height: 10),
          AppField(
            controller: quantity,
            label: 'الكمية',
          ),
          const SizedBox(height: 10),
          AppField(
            controller: expiry,
            label: 'تاريخ الانتهاء',
          ),
          const SizedBox(height: 10),
          AppField(
            controller: area,
            label: 'المنطقة',
          ),
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

class
