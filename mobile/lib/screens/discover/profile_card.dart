import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../widgets/net_image.dart';

/// Satu kartu profil: foto, nama, bio. Opacity like/nope dikontrol induk saat di-drag.
class ProfileCard extends StatefulWidget {
  const ProfileCard({
    super.key,
    required this.profile,
    this.likeOpacity = 0,
    this.nopeOpacity = 0,
    this.superOpacity = 0,
    this.onInfo,
  });

  final UserProfile profile;
  final double likeOpacity;
  final double nopeOpacity;
  final double superOpacity;
  final VoidCallback? onInfo;

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  int _photo = 0;

  void _onTapUp(TapUpDetails details, double width) {
    final photos = widget.profile.photos.length;
    if (photos < 2) return;
    setState(() {
      if (details.localPosition.dx > width / 2) {
        _photo = (_photo + 1).clamp(0, photos - 1);
      } else {
        _photo = (_photo - 1).clamp(0, photos - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final text = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, c) => GestureDetector(
        onTapUp: (d) => _onTapUp(d, c.maxWidth),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: AppColors.softShadow(0.22),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: NetImage(p.photos[_photo], key: ValueKey(_photo)),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.18, 0.5, 1],
                      colors: [Color(0x55000000), Colors.transparent, Colors.transparent, Color(0xD9000000)],
                    ),
                  ),
                ),
                if (p.photos.length > 1)
                  Positioned(
                    top: 12,
                    left: 14,
                    right: 14,
                    child: Row(
                      children: [
                        for (var i = 0; i < p.photos.length; i++)
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i == _photo ? Colors.white : Colors.white38,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (p.isOnline)
                  Positioned(
                    top: 28,
                    left: 18,
                    child: _GlassPill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.online, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text('Online',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${p.name}, ${p.age}',
                              overflow: TextOverflow.ellipsis,
                              style: text.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (p.isVerified) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.verified_rounded, color: Color(0xFF5AB8FF), size: 26),
                          ],
                          const Spacer(),
                          if (widget.onInfo != null)
                            GestureDetector(
                              onTap: widget.onInfo,
                              child: const _GlassPill(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.work_outline_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(p.job ?? '-', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 14),
                          const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${p.city} • ${p.distanceKm} km',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final interest in p.interests)
                            _GlassPill(
                              child: Text(interest,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                _Stamp(label: 'SUKA', color: AppColors.primary, opacity: widget.likeOpacity, left: true),
                _Stamp(label: 'LEWATI', color: Colors.white, opacity: widget.nopeOpacity, left: false),
                Positioned(
                  bottom: 200,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: widget.superOpacity,
                      child: const _StampBox(label: 'SUPER LIKE', color: AppColors.superLike, angle: 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.color, required this.opacity, required this.left});

  final String label;
  final Color color;
  final double opacity;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 56,
      left: left ? 24 : null,
      right: left ? null : 24,
      child: Opacity(
        opacity: opacity,
        child: _StampBox(label: label, color: color, angle: left ? -0.3 : 0.3),
      ),
    );
  }
}

class _StampBox extends StatelessWidget {
  const _StampBox({required this.label, required this.color, required this.angle});

  final String label;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 4),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.08),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      ),
    );
  }
}
