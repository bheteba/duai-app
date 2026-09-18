import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

final supabase = SupabaseConfig.isConfigured ? Supabase.instance.client : null;

const green = Color(0xFF079B70);
const dark = Color(0xFF17352C);
const bg = Color(0xFFF4F8F6);

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
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2ECE8))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: green, width: 1.5)),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class Medicine {
  final String name, strength, qty, expiry, area;
  final bool free;
  Medicine(this.name, this.strength, this.qty, this.expiry, this.area, {this.free=false});
}

final medicines = <Medicine>[
  Medicine('Augmentin', '625 mg', '2 شرائط', '08/2027', 'مدينة نصر - القاهرة'),
  Medicine('Panadol', '500 mg', '1 شريط', '06/2028', 'مصر الجديدة - القاهرة', free: true),
  Medicine('Vitamin C', '1000 mg', '3 شرائط', '11/2027', 'المعادي - القاهرة'),
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
        if (session != null) return const AppShell();
        return const LoginPage();
      },
    );
  }
}

class BackendSetupPage extends StatelessWidget {
  const BackendSetupPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('دوائي', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: green)),
          SizedBox(height: 12),
          Text('النسخة متصلة بالكود الخلفي، لكن بيانات مشروع Supabase لم تُضف بعد.', textAlign: TextAlign.center, style: TextStyle(fontSize: 17)),
          SizedBox(height: 10),
          Text('شغّل التطبيق باستخدام SUPABASE_URL و SUPABASE_PUBLISHABLE_KEY كما هو موضح في README.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      )))),
    ),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;
  String? error;

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'اكتب البريد الإلكتروني وكلمة المرور'); return;
    }
    setState(() { loading = true; error = null; });
    try {
      await supabase!.auth.signInWithPassword(email: email.text.trim(), password: password.text);
    } on AuthException catch (e) {
      setState(() => error = e.message);
    } catch (_) {
      setState(() => error = 'حدث خطأ في الاتصال بالخادم');
    } finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      const Text('💊', style: TextStyle(fontSize: 70)),
      const Text('دوائي', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: green)),
      const SizedBox(height: 5),
      const Text('شارك الفائض، وابحث عما تحتاج', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 30),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined))),
      const SizedBox(height: 12),
      TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(Icons.visibility_outlined), onPressed: () => setState(() => obscure = !obscure)))),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : login, child: Text(loading ? 'جارٍ الدخول...' : 'تسجيل الدخول'))),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: loading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text('إنشاء حساب جديد'))),
    ]))),
  ));
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override State<RegisterPage> createState() => _RegisterPageState();
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
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.length < 6) {
      setState(() => message = 'أدخل الاسم والبريد وكلمة مرور من 6 أحرف على الأقل'); return;
    }
    setState(() { loading = true; message = null; });
    try {
      final res = await supabase!.auth.signUp(
        email: email.text.trim(), password: password.text,
        data: {'full_name': name.text.trim(), 'phone': phone.text.trim(), 'city': city.text.trim(), 'area': area.text.trim(), 'country': 'EG'},
      );
      if (!mounted) return;
      if (res.session == null) {
        setState(() => message = 'تم إنشاء الحساب. إذا كان تأكيد البريد مفعّلًا، افتح رسالة البريد ثم سجّل الدخول.');
      } else {
        Navigator.pop(context);
      }
    } on AuthException catch (e) { setState(() => message = e.message); }
    catch (_) { setState(() => message = 'حدث خطأ في إنشاء الحساب'); }
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('إنشاء حساب'), backgroundColor: bg),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
      const SizedBox(height: 10), TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
      const SizedBox(height: 10), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
      const SizedBox(height: 10), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف المصري', prefixText: '+20 ')),
      const SizedBox(height: 10), TextField(controller: city, decoration: const InputDecoration(labelText: 'المحافظة / المدينة')),
      const SizedBox(height: 10), TextField(controller: area, decoration: const InputDecoration(labelText: 'المنطقة')),
      if (message != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(message!, style: const TextStyle(color: green))),
      const SizedBox(height: 8), FilledButton(onPressed: loading ? null : register, child: Text(loading ? 'جارٍ إنشاء الحساب...' : 'إنشاء الحساب')),
    ]),
  ));
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  int tab = 0;
  bool logged = true;
  final requests = <String>['طلب تبادل Augmentin ⇄ Panadol'];

  void nav(int i) => setState(() => tab = i);
  void open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onSearch: ()=>nav(1), onAdd: ()=>nav(2), onRequests: ()=>nav(3), open: open),
      SearchPage(open: open),
      AddMedicinePage(onPublished: ()=>nav(0)),
      RequestsPage(requests: requests, open: open),
      const AccountPage(),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: pages[tab],
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: nav,
          backgroundColor: Colors.white,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.search), label: 'البحث'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'إضافة'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'الطلبات'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final VoidCallback onSearch, onAdd, onRequests;
  final void Function(Widget) open;
  const HomePage({super.key, required this.onSearch, required this.onAdd, required this.onRequests, required this.open});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(padding: const EdgeInsets.all(18), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('مرحبًا، محمد 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: dark)),
          SizedBox(height: 4), Text('شارك الفائض وابحث عما تحتاج', style: TextStyle(color: Colors.grey)),
        ]),
        IconButton(onPressed: ()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد إشعارات جديدة'))), icon: const Icon(Icons.notifications_none)),
      ]),
      const SizedBox(height: 16),
      GestureDetector(onTap: onSearch, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2ECE8))),
        child: const Row(children: [Icon(Icons.search, color: green), SizedBox(width: 10), Text('ما الدواء الذي تبحث عنه؟', style: TextStyle(color: Colors.grey))]),
      )),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: ActionCard(icon: Icons.search, title: 'أبحث عن دواء', onTap: onSearch)),
        const SizedBox(width: 10),
        Expanded(child: ActionCard(icon: Icons.add, title: 'لدي دواء زائد', onTap: onAdd)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: ActionCard(icon: Icons.swap_horiz, title: 'أريد التبادل', onTap: ()=>open(const MatchPage()))),
        const SizedBox(width: 10),
        Expanded(child: ActionCard(icon: Icons.receipt_long, title: 'طلباتي', onTap: onRequests)),
      ]),
      const SizedBox(height: 24),
      const Text('🎯 مطابقات لك', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      MedicineCard(medicine: medicines[0], onTap: ()=>open(MedicineDetailsPage(medicine: medicines[0]))),
      MedicineCard(medicine: medicines[1], onTap: ()=>open(MedicineDetailsPage(medicine: medicines[1]))),
    ]),
  );
}

class ActionCard extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap;
  const ActionCard({super.key, required this.icon, required this.title, required this.onTap});
  @override Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(17), onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE2ECE8))),
      child: Column(children: [Icon(icon, color: green, size: 30), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))]),
    ),
  );
}

class MedicineCard extends StatelessWidget {
  final Medicine medicine; final VoidCallback onTap;
  const MedicineCard({super.key, required this.medicine, required this.onTap});
  @override Widget build(BuildContext context) => Card(
    elevation: 0, margin: const EdgeInsets.only(bottom: 10),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Padding(padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(width: 70, height: 70, decoration: BoxDecoration(color: const Color(0xFFF0F5F3), borderRadius: BorderRadius.circular(14)), child: const Center(child: Text('💊', style: TextStyle(fontSize: 34)))),
        const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${medicine.name} ${medicine.strength}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('${medicine.qty} • الصلاحية ${medicine.expiry}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 5), Text(medicine.free ? '🎁 مجاني' : '🔄 تبادل', style: const TextStyle(color: green, fontWeight: FontWeight.w700)),
        ]))
      ]))),
  );
}

class SearchPage extends StatefulWidget {
  final void Function(Widget) open;
  const SearchPage({super.key, required this.open});
  @override State<SearchPage> createState()=>_SearchPageState();
}
class _SearchPageState extends State<SearchPage> {
  String q='';
  @override Widget build(BuildContext context) {
    final list = medicines.where((m)=>('${m.name} ${m.strength}').toLowerCase().contains(q.toLowerCase())).toList();
    return SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('البحث عن دواء', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
      const SizedBox(height: 15),
      TextField(onChanged:(v)=>setState(()=>q=v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'اسم الدواء أو المادة الفعالة')),
      const SizedBox(height: 10),
      const Wrap(spacing:6, children:[Chip(label:Text('الأقرب')),Chip(label:Text('مجاني')),Chip(label:Text('تبادل'))]),
      const SizedBox(height: 8),
      ...list.map((m)=>MedicineCard(medicine:m,onTap:()=>widget.open(MedicineDetailsPage(medicine:m)))),
    ]));
  }
}

class MedicineDetailsPage extends StatelessWidget {
  final Medicine medicine;
  const MedicineDetailsPage({super.key, required this.medicine});
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('تفاصيل الدواء'), backgroundColor:bg),
    body: ListView(padding: const EdgeInsets.all(18), children:[
      Card(elevation:0, child:Padding(padding:const EdgeInsets.all(22), child:Column(children:[
        const Text('💊',style:TextStyle(fontSize:75)), Text('${medicine.name} ${medicine.strength}',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)), const SizedBox(height:5), const Text('البيانات المعروضة من صاحب العرض',style:TextStyle(color:Colors.grey)),
      ]))),
      Card(elevation:0, child:Padding(padding:const EdgeInsets.all(16), child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Info('الكمية',medicine.qty), Info('الصلاحية',medicine.expiry), Info('حالة العبوة','أصلية'), Info('المنطقة',medicine.area),
      ]))),
      Card(elevation:0, child:const ListTile(leading:CircleAvatar(child:Icon(Icons.person)), title:Text('محمد أحمد'), subtitle:Text('⭐ 4.8 • مستخدم موثوق'))),
      FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ExchangeRequestPage(give:medicine.name, get:'Panadol'))), child:const Text('اقتراح تبادل')),
      OutlinedButton(onPressed:()=>Navigator.pop(context), child:const Text('رجوع')),
    ],
  )));
}
class Info extends StatelessWidget{final String a,b;const Info(this.a,this.b,{super.key});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(a,style:const TextStyle(color:Colors.grey)),Text(b,style:const TextStyle(fontWeight:FontWeight.w700))]));}

class AddMedicinePage extends StatefulWidget {
  final VoidCallback onPublished;
  const AddMedicinePage({super.key, required this.onPublished});
  @override State<AddMedicinePage> createState()=>_AddMedicinePageState();
}
class _AddMedicinePageState extends State<AddMedicinePage>{
  final name=TextEditingController(text:'Augmentin'), strength=TextEditingController(text:'625 mg'), qty=TextEditingController(text:'2 شرائط'), expiry=TextEditingController(text:'08/2027');
  XFile? photo;
  Future<void> pick(ImageSource s) async { final p=await ImagePicker().pickImage(source:s); if(p!=null)setState(()=>photo=p); }
  @override Widget build(BuildContext c)=>SafeArea(child:ListView(padding:const EdgeInsets.all(18),children:[
    const Text('أضف دواءك',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),
    const SizedBox(height:14),
    GestureDetector(onTap:()=>showModalBottomSheet(context:context,builder:(_)=>Wrap(children:[
      ListTile(leading:const Icon(Icons.camera_alt),title:const Text('الكاميرا'),onTap:(){Navigator.pop(context);pick(ImageSource.camera);}),
      ListTile(leading:const Icon(Icons.photo_library),title:const Text('المعرض'),onTap:(){Navigator.pop(context);pick(ImageSource.gallery);}),
    ])), child:Container(height:170,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFE2ECE8))),child:photo==null?const Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.camera_alt_outlined,size:45,color:green),SizedBox(height:8),Text('صوّر العبوة أو اختر صورة')])):Image.file(File(photo!.path),fit:BoxFit.cover))),
    const SizedBox(height:14),
    field('اسم الدواء',name), field('التركيز',strength), field('الكمية',qty), field('تاريخ الانتهاء',expiry),
    const SizedBox(height:8),
    FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>VerifyPage(name:name.text,strength:strength.text,qty:qty.text,expiry:expiry.text,onDone:onPublished))),child:const Text('التالي')),
  ]));
  Widget field(String l,TextEditingController x)=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:x,decoration:InputDecoration(labelText:l)));
}

class VerifyPage extends StatelessWidget{
  final String name,strength,qty,expiry; final VoidCallback onDone;
  const VerifyPage({super.key,required this.name,required this.strength,required this.qty,required this.expiry,required this.onDone});
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('التحقق من الدواء'),backgroundColor:bg),body:ListView(padding:const EdgeInsets.all(18),children:[
    Card(elevation:0,child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[const Text('💊',style:TextStyle(fontSize:65)),Text('$name $strength',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800)),Text('$qty • $expiry',style:const TextStyle(color:Colors.grey))]))),
    Card(elevation:0,child:const Padding(padding:EdgeInsets.all(16),child:Column(children:[ListTile(leading:Icon(Icons.check_circle,color:green),title:Text('اسم الدواء واضح')),ListTile(leading:Icon(Icons.check_circle,color:green),title:Text('تاريخ الصلاحية واضح')),ListTile(leading:Icon(Icons.check_circle,color:green),title:Text('الكمية واضحة'))]))),
    FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PublishPage(name:name,strength:strength,qty:qty,expiry:expiry,onPublished:onDone))),child:const Text('البيانات صحيحة')),
  ]));
}

class PublishPage extends StatefulWidget{
 final String name,strength,qty,expiry; final VoidCallback onPublished;
 const PublishPage({super.key,required this.name,required this.strength,required this.qty,required this.expiry,required this.onPublished});
 @override State<PublishPage> createState()=>_PublishPageState();
}
class _PublishPageState extends State<PublishPage>{bool exchange=true;
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('نوع العرض'),backgroundColor:bg),body:ListView(padding:const EdgeInsets.all(18),children:[
  ChoiceCard(icon:Icons.swap_horiz,title:'تبادل',selected:exchange,onTap:()=>setState(()=>exchange=true)),
  ChoiceCard(icon:Icons.card_giftcard,title:'إعطاء مجاني',selected:!exchange,onTap:()=>setState(()=>exchange=false)),
  if(exchange)...[const SizedBox(height:8),const Text('ما الدواء الذي تبحث عنه؟',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:8),const TextField(decoration:InputDecoration(hintText:'مثال: Panadol 500 mg'))],
  const SizedBox(height:18),
  Card(elevation:0,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('معاينة العرض',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:10),Text('${widget.name} ${widget.strength}'),Text('${widget.qty} • ${widget.expiry}'),Text(exchange?'🔄 تبادل':'🎁 مجاني',style:const TextStyle(color:green,fontWeight:FontWeight.w700))]))),
  FilledButton(onPressed:(){widget.onPublished();Navigator.popUntil(context,(r)=>r.isFirst);ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('تم نشر العرض بنجاح')));},child:const Text('نشر العرض')),
 ]));
}
class ChoiceCard extends StatelessWidget{final IconData icon;final String title;final bool selected;final VoidCallback onTap;const ChoiceCard({super.key,required this.icon,required this.title,required this.selected,required this.onTap});@override Widget build(BuildContext c)=>Card(color:selected?const Color(0xFFE0F6EE):Colors.white,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17),side:BorderSide(color:selected?green:const Color(0xFFE2ECE8),width:selected?1.7:1)),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(17),child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[Icon(icon,color:green,size:30),const SizedBox(width:12),Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800))]))));}

class MatchPage extends StatelessWidget{const MatchPage({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('المطابقة الذكية'),backgroundColor:bg),body:ListView(padding:const EdgeInsets.all(18),children:[
 const SizedBox(height:20),const Center(child:Text('🎯',style:TextStyle(fontSize:75))),const Center(child:Text('وجدنا تطابقًا!',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900))),const SizedBox(height:18),
 Card(elevation:0,child:Padding(padding:const EdgeInsets.all(20),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[const Column(children:[Text('💊',style:TextStyle(fontSize:40)),Text('Augmentin'),Text('أنت لديك')]),const Text('⇄',style:TextStyle(fontSize:30,color:green)),const Column(children:[Text('💊',style:TextStyle(fontSize:40)),Text('Panadol'),Text('الطرف الآخر')])]))),
 FilledButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const ExchangeRequestPage(give:'Augmentin',get:'Panadol'))),child:const Text('اقتراح التبادل')),
 ]));}

class ExchangeRequestPage extends StatelessWidget{final String give,get;const ExchangeRequestPage({super.key,required this.give,required this.get});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('طلب تبادل'),backgroundColor:bg),body:ListView(padding:const EdgeInsets.all(18),children:[
 Card(elevation:0,child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[const Text('ستعطي',style:TextStyle(color:Colors.grey)),Text('💊 $give',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const Divider(height:28),const Text('وستحصل على',style:TextStyle(color:Colors.grey)),Text('💊 $get',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800))]))),
 const TextField(maxLines:3,decoration:InputDecoration(hintText:'اكتب رسالة للطرف الآخر...')),
 const SizedBox(height:14),FilledButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const AcceptPage())),child:const Text('إرسال طلب التبادل')),
 ]));}

class RequestsPage extends StatelessWidget{final List<String> requests;final void Function(Widget) open;const RequestsPage({super.key,required this.requests,required this.open});@override Widget build(BuildContext c)=>SafeArea(child:ListView(padding:const EdgeInsets.all(18),children:[
 const Text('الطلبات',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),const SizedBox(height:12),
 Card(elevation:0,child:ListTile(leading:const CircleAvatar(child:Text('💊')),title:const Text('أحمد محمود'),subtitle:const Text('Augmentin ⇄ Panadol'),trailing:const Chip(label:Text('جديد')),onTap:()=>open(const AcceptPage()))),
 Card(elevation:0,child:ListTile(leading:const CircleAvatar(child:Text('💊')),title:const Text('سارة علي'),subtitle:const Text('Vitamin C ⇄ Augmentin'),trailing:const Chip(label:Text('مقبول')))),
 ]));}

class AcceptPage extends StatelessWidget{const AcceptPage({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('قبول التبادل'),backgroundColor:bg),body:ListView(padding:const EdgeInsets.all(18),children:[
 Card(elevation:0,child:const Padding(padding:EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('أحمد محمود',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),Text('⭐ 4.8'),SizedBox(height:12),Text('يعرض: 💊 Panadol 500 mg'),Text('يطلب: 💊 Augmentin 625 mg')])),
 Card(elevation:0,child:const ListTile(leading:Icon(Icons.warning_amber_rounded,color:Colors.orange),title:Text('تأكد من بيانات الدواء وصلاحيته قبل الاستلام.'))),
 FilledButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const PickupPage())),child:const Text('قبول التبادل')),
 ]));}

class PickupPage extends StatelessWidget{const PickupPage({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('تحديد موعد الاستلام'),backgroundColor:bg),body:ListView(padding:const EdgeInsets.all(18),children:[
 Container(height:190,decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:const LinearGradient(colors:[Color(0xFFDCEBE5),Color(0xFFF8FBFA)])),child:const Center(child:Text('📍',style:TextStyle(fontSize:55)))),
 const SizedBox(height:12),const Row(children:[Expanded(child:ChoiceCardStatic(icon:Icons.location_on,title:'نقطة عامة')),SizedBox(width:8),Expanded(child:ChoiceCardStatic(icon:Icons.local_pharmacy,title:'صيدلية مشاركة'))]),
 const SizedBox(height:14),const TextField(decoration:InputDecoration(labelText:'التاريخ',hintText:'26/09/2026')),const SizedBox(height:8),const TextField(decoration:InputDecoration(labelText:'الوقت',hintText:'04:00 م')),
 const SizedBox(height:16),FilledButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const OngoingPage())),child:const Text('تأكيد الموعد')),
 ]));}
class ChoiceCardStatic extends StatelessWidget{final IconData icon;final String title;const ChoiceCardStatic({super.key,required this.icon,required this.title});@override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFFE2ECE8))),child:Column(children:[Icon(icon,color:green),const SizedBox(height:5),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w700))]));}

class OngoingPage extends StatelessWidget{const OngoingPage({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('التبادل جارٍ'),backgroundColor:bg),body:ListView(padding:const EdgeInsets.all(18),children:[
 ...['✓ الطرف الآخر وافق','✓ أنت وافقت','✓ نقطة الاستلام محددة'].map((x)=>Card(elevation:0,child:ListTile(leading:const Icon(Icons.check_circle,color:green),title:Text(x)))),
 Card(elevation:0,child:Padding(padding:const EdgeInsets.all(22),child:Column(children:[const Text('رمز الاستلام',style:TextStyle(color:Colors.grey)),const SizedBox(height:10),const Text('482731',style:TextStyle(fontSize:34,fontWeight:FontWeight.w900,letterSpacing:6)),const Text('يتم إتمام التبادل بعد تأكيد الرمز.',style:TextStyle(color:Colors.grey))]))),
 FilledButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const CompletePage())),child:const Text('تم الاستلام')),
 ]));}

class CompletePage extends StatelessWidget{const CompletePage({super.key});@override Widget build(BuildContext c)=>Scaffold(body:SafeArea(child:ListView(padding:const EdgeInsets.all(22),children:[
 const SizedBox(height:50),const Center(child:Text('🤝',style:TextStyle(fontSize:80))),const Center(child:Text('تمت العملية بنجاح',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900))),const Center(child:Text('شكرًا لك على مشاركة الدواء.',style:TextStyle(color:Colors.grey))),const SizedBox(height:25),
 Card(elevation:0,child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[const Text('كيف كانت تجربتك؟',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:10),const Text('★★★★★',style:TextStyle(fontSize:34,letterSpacing:4,color:green)),const SizedBox(height:10),const Text('هل كانت بيانات الدواء مطابقة للعرض؟'),const SizedBox(height:8),const Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[ChoiceCardStatic(icon:Icons.thumb_up_alt_outlined,title:'نعم'),ChoiceCardStatic(icon:Icons.thumb_down_alt_outlined,title:'لا')])]))),
 FilledButton(onPressed:()=>Navigator.popUntil(c,(r)=>r.isFirst),child:const Text('إنهاء')),
 ]));}

class AccountPage extends StatelessWidget{const AccountPage({super.key});@override Widget build(BuildContext c){final u=supabase?.auth.currentUser;final m=u?.userMetadata??{};final name=(m['full_name']??'مستخدم دوائي').toString();final city=(m['city']??'').toString();final area=(m['area']??'').toString();return SafeArea(child:ListView(padding:const EdgeInsets.all(18),children:[
 const CircleAvatar(radius:42,child:Icon(Icons.person,size:45)),const SizedBox(height:10),Center(child:Text(name,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900))),Center(child:Text([city,area].where((x)=>x.isNotEmpty).join(' • '),style:const TextStyle(color:Colors.grey))),const SizedBox(height:20),
 Card(elevation:0,child:Column(children:[const ListTile(leading:Icon(Icons.verified_user_outlined,color:green),title:Text('الحساب المسجل عبر Supabase')),const ListTile(leading:Icon(Icons.star_outline),title:Text('التقييم 4.8')),const ListTile(leading:Icon(Icons.notifications_none),title:Text('الإشعارات')),const ListTile(leading:Icon(Icons.help_outline),title:Text('المساعدة'))])),
 const SizedBox(height:12),OutlinedButton.icon(onPressed:()async{await supabase?.auth.signOut();},icon:const Icon(Icons.logout),label:const Text('تسجيل الخروج')),
 ]));}}
