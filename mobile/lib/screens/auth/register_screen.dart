import 'package:flutter/material.dart';

import '../../state/session_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_feedback.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/soft_background.dart';
import '../home_shell.dart';
import 'auth_widgets.dart';

/// Form daftar. Field banyak → satu [GlobalKey<FormState>] memvalidasi semua sekaligus.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _birthLabel = TextEditingController();

  DateTime? _birthDate;
  String _gender = 'male';
  String _interestedIn = 'female';
  bool _loading = false;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _birthLabel.dispose();
    super.dispose();
  }

  int _age(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) age--;
    return age;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 22, now.month, now.day),
      firstDate: DateTime(now.year - 80),
      lastDate: now,
      helpText: 'Tanggal lahir',
    );
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
      _birthLabel.text = '${picked.day} ${_months[picked.month - 1]} ${picked.year}';
    });
  }

  String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await SessionScope.read(context).register(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
        birthDate: _isoDate(_birthDate!),
        gender: _gender,
        interestedIn: _interestedIn,
      );
      if (!mounted) return;
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
                const SizedBox(height: 20),
                Text('Buat akun baru ✨',
                    style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Hanya butuh satu menit untuk mulai bertemu orang baru.',
                    style: text.bodyMedium?.copyWith(color: AppColors.inkSoft)),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'Nama lengkap',
                  hint: 'Nama yang ingin ditampilkan',
                  icon: Icons.person_rounded,
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  hint: 'nama@email.com',
                  icon: Icons.alternate_email_rounded,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  hint: 'Minimal 8 karakter',
                  icon: Icons.lock_rounded,
                  controller: _password,
                  obscure: true,
                  validator: (v) => (v == null || v.length < 8) ? 'Password minimal 8 karakter' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Tanggal lahir',
                  hint: 'Pilih tanggal',
                  icon: Icons.cake_rounded,
                  controller: _birthLabel,
                  readOnly: true,
                  onTap: _pickBirthDate,
                  validator: (_) {
                    if (_birthDate == null) return 'Tanggal lahir wajib diisi';
                    if (_age(_birthDate!) < 18) return 'Usia minimal 18 tahun';
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                _label(context, 'Saya seorang'),
                Wrap(
                  spacing: 10,
                  children: [
                    SelectChip(
                      label: 'Pria',
                      icon: Icons.male_rounded,
                      selected: _gender == 'male',
                      onTap: () => setState(() => _gender = 'male'),
                    ),
                    SelectChip(
                      label: 'Wanita',
                      icon: Icons.female_rounded,
                      selected: _gender == 'female',
                      onTap: () => setState(() => _gender = 'female'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _label(context, 'Tertarik dengan'),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final (value, label) in const [('male', 'Pria'), ('female', 'Wanita'), ('all', 'Semua')])
                      SelectChip(
                        label: label,
                        selected: _interestedIn == value,
                        onTap: () => setState(() => _interestedIn = value),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                GradientButton(label: 'Daftar sekarang', loading: _loading, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
      );
}
