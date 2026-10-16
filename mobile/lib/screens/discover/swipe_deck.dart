import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import 'profile_card.dart';

/// Arah usap: kiri = pass, kanan = like, atas = super like.
enum SwipeDirection { left, right, up }

/// Tumpukan 2–3 kartu. State-nya publik ([SwipeDeckState]) supaya tombol
/// di luar deck bisa memanggil [swipe] lewat [GlobalKey].
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.profiles,
    required this.onSwiped,
    required this.empty,
    this.onInfo,
  });

  final List<UserProfile> profiles;
  final void Function(UserProfile profile, SwipeDirection direction) onSwiped;
  final Widget empty;
  final void Function(UserProfile profile)? onInfo;

  @override
  State<SwipeDeck> createState() => SwipeDeckState();
}

class SwipeDeckState extends State<SwipeDeck> with SingleTickerProviderStateMixin {
  static const _threshold = 110.0;

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

  Offset _drag = Offset.zero;
  bool _animating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Dipanggil dari tombol hati/silang di Discover, bukan hanya gesture.
  void swipe(SwipeDirection direction) {
    if (widget.profiles.isEmpty || _animating) return;
    _flyOut(direction);
  }

  /// Animasikan posisi kartu dari [_drag] ke [target], lalu jalankan [onDone].
  void _animateTo(Offset target, Curve curve, VoidCallback onDone) {
    _animating = true;
    final tween = Tween(begin: _drag, end: target).animate(CurvedAnimation(parent: _controller, curve: curve));
    void tick() => setState(() => _drag = tween.value);
    _controller.addListener(tick);
    _controller.forward(from: 0).whenComplete(() {
      _controller.removeListener(tick);
      _animating = false;
      onDone();
    });
  }

  void _flyOut(SwipeDirection direction) {
    final size = context.size ?? const Size(400, 600);
    final target = switch (direction) {
      SwipeDirection.left => Offset(-size.width * 1.6, _drag.dy + 60),
      SwipeDirection.right => Offset(size.width * 1.6, _drag.dy + 60),
      SwipeDirection.up => Offset(_drag.dx, -size.height * 1.4),
    };
    final profile = widget.profiles.first;
    _animateTo(target, Curves.easeIn, () {
      widget.onSwiped(profile, direction);
      if (mounted) setState(() => _drag = Offset.zero);
    });
  }

  /// Lepas jari: kalau geseran / kecepatan melewati ambang, kartu terbang.
  /// Kalau tidak, kembali ke tengah ([Curves.easeOutBack] = sedikit overshoot).
  void _onPanEnd(DragEndDetails details) {
    if (_animating) return;
    final v = details.velocity.pixelsPerSecond;
    if (_drag.dx > _threshold || v.dx > 900) {
      _flyOut(SwipeDirection.right);
    } else if (_drag.dx < -_threshold || v.dx < -900) {
      _flyOut(SwipeDirection.left);
    } else if (_drag.dy < -_threshold * 1.2 && _drag.dx.abs() < 90) {
      _flyOut(SwipeDirection.up);
    } else {
      _animateTo(Offset.zero, Curves.easeOutBack, () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = widget.profiles;
    if (profiles.isEmpty) return widget.empty;

    return LayoutBuilder(
      builder: (context, c) {
        final progress = (_drag.distance / (c.maxWidth * 0.5)).clamp(0.0, 1.0);
        final like = (_drag.dx / _threshold).clamp(0.0, 1.0);
        final nope = (-_drag.dx / _threshold).clamp(0.0, 1.0);
        final superLike = _drag.dx.abs() < 90 ? (-_drag.dy / (_threshold * 1.2)).clamp(0.0, 1.0) : 0.0;
        final top = profiles.first;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (profiles.length > 2)
              Positioned.fill(
                child: Transform.translate(
                  offset: const Offset(0, 24),
                  child: Transform.scale(scale: 0.9, child: ProfileCard(profile: profiles[2])),
                ),
              ),
            if (profiles.length > 1)
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - progress)),
                  child: Transform.scale(
                    scale: 0.95 + 0.05 * progress,
                    child: ProfileCard(key: ValueKey('next-${profiles[1].id}'), profile: profiles[1]),
                  ),
                ),
              ),
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: _animating ? null : (d) => setState(() => _drag += d.delta),
                onPanEnd: _onPanEnd,
                child: Transform.translate(
                  offset: _drag,
                  child: Transform.rotate(
                    angle: _drag.dx / c.maxWidth * 0.4,
                    child: ProfileCard(
                      key: ValueKey('top-${top.id}'),
                      profile: top,
                      likeOpacity: like,
                      nopeOpacity: nope,
                      superOpacity: superLike,
                      onInfo: widget.onInfo == null ? null : () => widget.onInfo!(top),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
