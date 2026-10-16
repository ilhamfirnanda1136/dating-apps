import 'package:flutter/material.dart';

import '../../state/session_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_feedback.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/soft_background.dart';
import '../home_shell.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';

/// Form masuk. [TextEditingController] menyimpan teks input sampai [dispose].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'budi@mail.com');
  final _password = TextEditingController(text: 'password123');
  bool _loading = false;

  /// Controller HARUS di-dispose, kalau tidak teks listener tetap hidup.
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await SessionScope.read(context).login(email: _email.text, password: _password.text);
      if (!mounted) return;
      // Hapus stack auth: tombol back HP tidak kembali ke login.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                const Align(alignment: Alignment.centerLeft, child: AuthBackButton()),
                const SizedBox(height: 24),
                Text('Selamat datang\nkembali 👋',
                    style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 10),
                Text('Masuk untuk melihat siapa yang sudah menunggumu.',
                    style: text.bodyMedium?.copyWith(color: AppColors.inkSoft)),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Email',
                  hint: 'nama@email.com',
                  icon: Icons.alternate_email_rounded,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Password',
                  hint: 'Minimal 8 karakter',
                  icon: Icons.lock_rounded,
                  controller: _password,
                  obscure: true,
                  validator: (v) => (v == null || v.length < 8) ? 'Password minimal 8 karakter' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Lupa password?',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
                GradientButton(label: 'Masuk', loading: _loading, onPressed: _submit),
                const SizedBox(height: 28),
                const OrDivider(label: 'atau masuk dengan'),
                const SizedBox(height: 20),
                const SocialButtons(),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Belum punya akun?', style: text.bodyMedium?.copyWith(color: AppColors.inkSoft)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text('Daftar',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
