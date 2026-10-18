import 'package:flutter/material.dart';

import '../../api/dating_api.dart';
import '../../state/chat_store.dart';
import '../../state/session_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_feedback.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/net_image.dart';
import '../../widgets/photo_url_form.dart';
import '../../widgets/pressable.dart';
import '../onboarding_screen.dart';
import 'edit_profile_screen.dart';
import 'premium_card.dart';
import 'premium_sheet.dart';
import 'profile_detail_screen.dart';
import 'settings_screen.dart';

/// Tab profil sendiri: kelengkapan, foto, statistik match, pengaturan.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;
  bool _showDistance = true;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    try {
      final likes = await DatingApi().likes();
      if (mounted) setState(() => _likesCount = likes.length);
    } catch (_) {}
  }

  Future<void> _logout() async {
    try {
      await SessionScope.read(context).logout();
    } catch (error) {
      if (mounted) showApiError(context, error);
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final isPro = session.account?.isPro ?? false;
    final me = session.profile;
    final chats = ChatScope.of(context);
    final matchCount = chats.conversations.length + chats.newMatches.length;
    final text = Theme.of(context).textTheme;
    final location = [
      if (me.job != null && me.job!.trim().isNotEmpty) me.job,
      if (me.city.trim().isNotEmpty) me.city,
    ].join(' • ');
    final completeness = [
      me.name.trim().isNotEmpty,
      me.bio.trim().isNotEmpty,
      me.city.trim().isNotEmpty,
      me.job != null && me.job!.trim().isNotEmpty,
      me.photos.isNotEmpty,
    ].where((item) => item).length /
        5;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Row(
            children: [
              Text('Profil', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              CircleIconButton(
                icon: Icons.settings_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: completeness,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      color: AppColors.primary,
                      backgroundColor: AppColors.blushDeep,
                    ),
                  ),
                  ClipOval(child: SizedBox.square(dimension: 118, child: NetImage(me.avatar))),
                  Positioned(
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text('${(completeness * 100).round()}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 8,
                    child: Pressable(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.softShadow(0.2),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '${me.name}, ${me.age}',
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (me.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: Color(0xFF5AB8FF), size: 22),
              ],
              if (isPro) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            location.isEmpty ? 'Lengkapi pekerjaan dan kota di edit profil' : location,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: AppColors.inkSoft),
          ),
          if (me.photos.isEmpty) ...[
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppColors.softShadow(0.1),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text('Belum ada foto', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'Tempel tautan gambar agar profilmu tampil di discover.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 14),
                  PhotoUrlForm(
                    onSubmit: (url) async {
                      try {
                        await SessionScope.read(context).addPhoto(url);
                      } catch (error) {
                        if (context.mounted) showApiError(context, error);
                        rethrow;
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              _QuickAction(
                icon: Icons.edit_note_rounded,
                label: 'Edit profil',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.visibility_rounded,
                label: 'Pratinjau',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: me, showActions: false)),
                ),
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.shield_moon_rounded,
                label: 'Verifikasi',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unggah KTP & selfie segera terhubung ke backend')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _Stat(value: '$matchCount', label: 'Match'),
              const SizedBox(width: 12),
              _Stat(value: '$_likesCount', label: 'Disukai'),
              const SizedBox(width: 12),
              _Stat(value: '${me.photos.length}', label: 'Foto'),
            ],
          ),
          const SizedBox(height: 22),
          PremiumCard(isPro: isPro),
          const SizedBox(height: 22),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.notifications_active_outlined,
                label: 'Notifikasi',
                trailing: Switch.adaptive(
                  value: _notifications,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
              ),
              _SettingsTile(
                icon: Icons.near_me_outlined,
                label: 'Tampilkan jarak',
                trailing: Switch.adaptive(
                  value: _showDistance,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _showDistance = v),
                ),
              ),
              _SettingsTile(
                icon: Icons.tune_rounded,
                label: 'Preferensi pencarian',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.workspace_premium_rounded,
                label: 'FindLove Plus',
                onTap: () => showPremiumSheet(context),
              ),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                label: 'Privasi & keamanan',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: 'Bantuan',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Keluar',
                color: AppColors.primaryDeep,
                onTap: _logout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.softShadow(0.08),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: AppColors.blushDeep, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (r) => AppColors.primaryGradient.createShader(r),
              child: Text(value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow(0.06),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 64, color: AppColors.line),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.color = AppColors.ink,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap ?? (trailing == null ? () {} : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color == AppColors.ink ? AppColors.primary : color, size: 20),
      ),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
    );
  }
}
