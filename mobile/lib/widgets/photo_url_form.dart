import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_text_field.dart';
import 'gradient_button.dart';

/// Form tambah foto lewat URL (belum ada upload file).
/// [GlobalKey<FormState>] dipakai untuk menjalankan [validator] saat submit.
class PhotoUrlForm extends StatefulWidget {
  const PhotoUrlForm({super.key, required this.onSubmit, this.loading = false});

  final Future<void> Function(String url) onSubmit;
  final bool loading;

  @override
  State<PhotoUrlForm> createState() => _PhotoUrlFormState();
}

class _PhotoUrlFormState extends State<PhotoUrlForm> {
  final _url = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_url.text.trim());
      _url.clear();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || widget.loading;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'URL foto',
            hint: 'https://...',
            icon: Icons.link_rounded,
            controller: _url,
            keyboardType: TextInputType.url,
            validator: (value) {
              final url = value?.trim() ?? '';
              if (url.isEmpty) return 'URL foto wajib diisi';
              if (!(url.startsWith('http://') || url.startsWith('https://'))) {
                return 'Masukkan tautan yang diawali http';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Tambah foto',
            icon: Icons.add_photo_alternate_rounded,
            loading: busy,
            height: 50,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          Text(
            'Untuk sekarang unggah lewat tautan gambar (misalnya URL dari penyimpanan foto).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
