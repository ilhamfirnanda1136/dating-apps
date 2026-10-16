import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/net_image.dart';
import '../../widgets/pressable.dart';
import '../discover/swipe_deck.dart';

/// Halaman detail profil (bukan milik kita).
/// [Navigator.pop] bisa mengembalikan [SwipeDirection] ke Discover.
class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key, required this.profile, this.showActions = true});

  final UserProfile profile;
  final bool showActions;

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final text = Theme.of(context).textTheme;
    final height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.blush,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: height * 0.58,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: p.photos.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (_, i) => NetImage(p.photos[i]),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Row(
                              children: [
                                CircleIconButton(
                                  icon: Icons.arrow_back_ios_new_rounded,
                                  size: 42,
                                  onTap: () => Navigator.of(context).pop(),
                                ),
                                const Spacer(),
                                CircleIconButton(icon: Icons.more_horiz_rounded, size: 42, onTap: () {}),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < p.photos.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: i == _page ? 22 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: i == _page ? Colors.white : Colors.white54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 140),
                    decoration: const BoxDecoration(
                      color: AppColors.blush,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('${p.name}, ${p.age}',
                                style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                            if (p.isVerified) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified_rounded, color: Color(0xFF5AB8FF), size: 26),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(icon: Icons.work_outline_rounded, label: p.job ?? '-'),
                        const SizedBox(height: 6),
                        _InfoRow(icon: Icons.location_on_outlined, label: '${p.city} • ${p.distanceKm} km dari kamu'),
                        const SizedBox(height: 26),
                        _SectionTitle('Tentang aku'),
                        const SizedBox(height: 10),
                        Text(p.bio.isEmpty ? 'Belum menulis bio.' : p.bio,
                            style: text.bodyLarge?.copyWith(color: AppColors.ink.withValues(alpha: 0.8), height: 1.6)),
                        const SizedBox(height: 26),
                        _SectionTitle('Minat'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final i in p.interests)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Text(i, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.flag_outlined, color: AppColors.inkSoft, size: 18),
                            label: Text('Laporkan ${p.name}',
                                style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.showActions)
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundAction(
                    icon: Icons.close_rounded,
                    color: const Color(0xFFFF6B6B),
                    onTap: () => Navigator.of(context).pop(SwipeDirection.left),
                  ),
                  const SizedBox(width: 20),
                  _RoundAction(
                    icon: Icons.star_rounded,
                    color: AppColors.superLike,
                    size: 52,
                    onTap: () => Navigator.of(context).pop(SwipeDirection.up),
                  ),
                  const SizedBox(width: 20),
                  _RoundAction(
                    icon: Icons.favorite_rounded,
                    gradient: true,
                    size: 70,
                    onTap: () => Navigator.of(context).pop(SwipeDirection.right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800));
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.gradient = false,
    this.size = 60,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool gradient;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.88,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gradient ? null : Colors.white,
          gradient: gradient ? AppColors.primaryGradient : null,
          boxShadow: AppColors.softShadow(gradient ? 0.4 : 0.18),
        ),
        child: Icon(icon, color: gradient ? Colors.white : color, size: size * 0.48),
      ),
    );
  }
}
