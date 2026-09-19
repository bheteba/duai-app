import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool obscurePassword = true;
  bool loading = false;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String formatPhone(String phone) {
    phone = phone.trim();

    if (phone.startsWith('01')) {
      return '+20${phone.substring(1)}';
    }

    if (phone.startsWith('+20')) {
      return phone;
    }

    return phone;
  }

  Future<void> submit() async {
    final name = nameController.text.trim();
    final phone = formatPhone(phoneController.text);
    final password = passwordController.text;

    if (!isLogin && name.isEmpty) {
      showMessage('اكتب الاسم أولًا');
      return;
    }

    if (phone.isEmpty) {
      showMessage('اكتب رقم الهاتف');
      return;
    }

    if (password.isEmpty) {
      showMessage('اكتب كلمة المرور');
      return;
    }

    if (password.length < 6) {
      showMessage('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      if (isLogin) {
        await supabase.auth.signInWithPassword(
          phone: phone,
          password: password,
        );

        if (!mounted) return;

        showMessage('تم تسجيل الدخول بنجاح');

        Navigator.pop(context);
      } else {
        final response = await supabase.auth.signUp(
          phone: phone,
          password: password,
          data: {
            'name': name,
          },
        );

        if (!mounted) return;

        if (response.session != null) {
          showMessage('تم إنشاء الحساب بنجاح');
          Navigator.pop(context);
        } else {
          showMessage(
            'تم إنشاء الحساب. تحقق من رمز التحقق المرسل إلى هاتفك.',
          );
        }
      }
    } on AuthException catch (error) {
      if (!mounted) return;

      showMessage(error.message);
    } catch (error) {
      if (!mounted) return;

      showMessage('حدث خطأ، حاول مرة أخرى');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.medical_services_outlined,
                size: 80,
                color: Color(0xFF159447),
              ),

              const SizedBox(height: 20),

              Text(
                isLogin ? 'مرحبًا بك في دوائي' : 'إنشاء حساب جديد',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              if (!isLogin) ...[
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  hintText: '01xxxxxxxxx',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isLogin
                              ? 'تسجيل الدخول'
                              : 'إنشاء الحساب',
                          style: const TextStyle(
                            fontSize: 17,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: loading
                    ? null
                    : () {
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },
                child: Text(
                  isLogin
                      ? 'ليس لديك حساب؟ إنشاء حساب جديد'
                      : 'لديك حساب بالفعل؟ تسجيل الدخول',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
