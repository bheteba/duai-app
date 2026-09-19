import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';

const String supabaseUrl = 'https://ddyrfoqiqzavhpwpgtqz.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_9NeSHNI82SlQgrdtGDI1tA_lm_ho7zV';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final result =
        await InternetAddress.lookup('ddyrfoqiqzavhpwpgtqz.supabase.co');

    debugPrint('SUPABASE DNS RESULT: $result');
  } catch (e) {
    debugPrint('SUPABASE DNS ERROR: $e');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
  );

  runApp(const DuaiApp());
}

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF159447),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  final pages = const [
    HomeTab(),
    SearchTab(),
    AddMedicineTab(),
    RequestsTab(),
    AccountTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: pages[currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'البحث',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'إضافة',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'طلباتي',
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

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 15),
            const Text(
              'مرحبًا بك في دوائي 💚',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'ساعد غيرك واستفد من الأدوية المتاحة بطريقة منظمة.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 25),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.medication_outlined,
                      size: 55,
                      color: Color(0xFF159447),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'ابحث عن دواء',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ابحث عن الأدوية المتاحة بالقرب منك.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.search),
                      label: const Text('ابدأ البحث'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.volunteer_activism_outlined,
                      size: 50,
                      color: Color(0xFF159447),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'لديك دواء زائد؟',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'يمكنك تسجيل الدواء ليظهر للأشخاص الذين يبحثون عنه.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة دواء'),
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

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController controller = TextEditingController();

  final List<String> medicines = [
    'باراسيتامول',
    'بانادول',
    'كونجستال',
    'أوجمنتين',
    'فنتولين',
    'كتافلام',
  ];

  List<String> filteredMedicines = [];

  @override
  void initState() {
    super.initState();
    filteredMedicines = medicines;
  }

  void search(String value) {
    setState(() {
      filteredMedicines = medicines
          .where(
            (medicine) => medicine.contains(value.trim()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'البحث عن دواء',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              onChanged: search,
              decoration: InputDecoration(
                hintText: 'اكتب اسم الدواء',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredMedicines.isEmpty
                  ? const Center(
                      child: Text('لا توجد نتائج'),
                    )
                  : ListView.builder(
                      itemCount: filteredMedicines.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
