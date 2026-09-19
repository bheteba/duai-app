import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool obscurePassword = true;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submit() {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    if (!isLogin && name.isEmpty) {
      showMessage('اكتب الاسم أولًا');
      return;
    }

    if (phone.isEmpty) {
      showMessage('اكتب رقم الجوال');
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

    showMessage(
      is
