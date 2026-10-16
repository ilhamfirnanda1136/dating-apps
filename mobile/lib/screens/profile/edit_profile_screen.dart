import 'package:flutter/material.dart';

import '../../state/session_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_feedback.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/net_image.dart';
import '../../widgets/photo_url_form.dart';
import '../../widgets/pressable.dart';
import '../../widgets/soft_background.dart';
import '../auth/auth_widgets.dart';

/// Edit nama/bio/kota + tambah foto URL. [late final] controller diisi di [initState]
/// dari data session yang sudah ada.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _job;
  late final TextEditingController _city;
  late final TextEditingController _bio;
  late final Set<String> _interests;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final me = SessionScope.read(context).profile;
    _name = TextEditingController(text: me.name);
    _job = TextEditingController(text: me.job ?? '');
    _city = TextEditingController(text: me.city);
    _bio = TextEditingController(text: me.bio);
    _interests = {...me.interests};
  }

  static const _catalog = [
    'Kopi', 'Hiking', 'Film', 'Fotografi', 'Musik', 'Traveling', 'Kuliner',
    'Yoga', 'Gaming', 'Buku', 'Olahraga', 'Seni',
  ];

  @override
  void dispose() {
    _name.dispose();
    _job.dispose();
    _city.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(String url) async {
    try {
      await SessionScope.read(context).addPhoto(url);
    } catch (error) {
      if (mounted) showApiError(context, error);
      rethrow;
    }
  }

  void _showPhotoForm() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.viewInsetsOf(sheet).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 18),
            Text('Tambah foto', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            PhotoUrlForm(
              onSubmit: (url) async {
                await _addPhoto(url);
                if (sheet.mounted) Navigator.of(sheet).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SessionScope.read(context).updateProfile(
        fullName: _name.text.trim(),
        bio: _bio.text.trim(),
        city: _city.text.trim(),
        job: _job.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil tersimpan')));
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final me = SessionScope.of(context).profile;

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    size: 44,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Text('Edit profil', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 24),
              if (me.photos.isEmpty)
                EmptyState(
                  icon: Icons.add_a_photo_rounded,
                  title: 'Belum ada foto',
                  subtitle: 'Profil tanpa foto sulit mendapatkan match. Tempel tautan gambar dari penyimpananmu.',
                  child: PhotoUrlForm(onSubmit: _addPhoto),
                )
              else
                SizedBox(
                  height: 118,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: me.photos.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      if (i == me.photos.length) {
                        return Pressable(
                          onTap: _showPhotoForm,
                          child: Container(
                            width: 96,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.line, style: BorderStyle.solid),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, color: AppColors.primary),
                                SizedBox(height: 6),
                                Text('Tambah', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: SizedBox(width: 96, child: NetImage(me.photos[i])),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              AppTextField(label: 'Nama', hint: 'Nama tampilan', icon: Icons.person_rounded, controller: _name),
              const SizedBox(height: 16),
              AppTextField(label: 'Pekerjaan', hint: 'Apa yang kamu lakukan', icon: Icons.work_outline_rounded, controller: _job),
              const SizedBox(height: 16),
              AppTextField(label: 'Kota', hint: 'Lokasi', icon: Icons.location_on_outlined, controller: _city),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Bio', style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
              TextFormField(
                controller: _bio,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(hintText: 'Ceritakan dirimu dalam beberapa kalimat'),
              ),
              const SizedBox(height: 22),
              Text('Minat', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final item in _catalog)
                    SelectChip(
                      label: item,
                      selected: _interests.contains(item),
                      onTap: () => setState(() {
                        if (_interests.contains(item)) {
                          _interests.remove(item);
                        } else {
                          _interests.add(item);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: 'Simpan perubahan',
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
