import 'package:flutter/material.dart';

import '../../api/dating_api.dart';
import '../../models/user_profile.dart';
import '../../state/chat_store.dart';
import '../../state/session_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_feedback.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/pressable.dart';
import '../chat/chat_room_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_detail_screen.dart';
import 'match_dialog.dart';
import 'swipe_deck.dart';

/// Tab utama: tumpukan kartu + tombol like/pass.
/// State [_queue] adalah antrian profil dari GET /discover.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _deckKey = GlobalKey<SwipeDeckState>();
  final _api = DatingApi();
  List<UserProfile> _queue = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _api.discover();
      if (!mounted) return;
      setState(() {
        _queue = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  /// Kartu sudah terbang di UI. Kita kirim aksi ke API.
  /// Kalau gagal, kartu dikembalikan ke depan antrian.
  Future<void> _onSwiped(UserProfile profile, SwipeDirection direction) async {
    setState(() => _queue = _queue.sublist(1));
    final action = switch (direction) {
      SwipeDirection.left => 'pass',
      SwipeDirection.up => 'super_like',
      SwipeDirection.right => 'like',
    };
    try {
      final result = await _api.swipe(targetId: profile.id, action: action);
      if (!mounted || !result.matched || result.matchId == null) return;

      final store = ChatScope.read(context);
      store.addMatch(profile, matchId: result.matchId!);
      final sendMessage = await showMatchDialog(
        context,
        me: SessionScope.read(context).profile,
        other: profile,
      );
      if (!mounted) return;

      if (sendMessage == true) {
        final conversation = store.openWith(profile);
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatRoomScreen(conversation: conversation)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _queue = [profile, ..._queue]);
      showApiError(context, error);
    }
  }

  void _openDetail(UserProfile profile) async {
    final direction = await Navigator.of(context).push<SwipeDirection>(
      MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: profile)),
    );
    if (direction != null) _deckKey.currentState?.swipe(direction);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                const BrandLogo(size: 24),
                const Spacer(),
                CircleIconButton(icon: Icons.tune_rounded, onTap: () => _showFilter(context)),
                const SizedBox(width: 10),
                CircleIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? EmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'Tidak bisa memuat profil',
                          subtitle: 'Periksa koneksi, lalu coba muat ulang daftar dari database.',
                          actionLabel: 'Coba lagi',
                          onAction: _load,
                        )
                      : SwipeDeck(
                          key: _deckKey,
                          profiles: _queue,
                          onSwiped: _onSwiped,
                          onInfo: _openDetail,
                          empty: EmptyState(
                            icon: Icons.travel_explore_rounded,
                            title: 'Belum ada orang di sekitar',
                            subtitle:
                                'Database belum punya kandidat yang cocok. Longgarkan filter usia dan jarak, atau undang teman untuk daftar.',
                            actionLabel: 'Muat ulang',
                            onAction: _load,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 18),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _queue.isEmpty || _loading ? 0.3 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  size: 60,
                  icon: Icons.close_rounded,
                  iconColor: const Color(0xFFFF6B6B),
                  onTap: () => _deckKey.currentState?.swipe(SwipeDirection.left),
                ),
                const SizedBox(width: 18),
                _ActionButton(
                  size: 50,
                  icon: Icons.star_rounded,
                  iconColor: AppColors.superLike,
                  onTap: () => _deckKey.currentState?.swipe(SwipeDirection.up),
                ),
                const SizedBox(width: 18),
                _ActionButton(
                  size: 72,
                  icon: Icons.favorite_rounded,
                  gradient: true,
                  onTap: () => _deckKey.currentState?.swipe(SwipeDirection.right),
                ),
                const SizedBox(width: 18),
                _ActionButton(
                  size: 50,
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.gold,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Boost tersedia untuk pengguna Klik Plus ✨')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  Future<void> _showFilter(BuildContext context) async {
    final pref = SessionScope.read(context).account?.preference;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        minAge: pref?.minAge ?? 18,
        maxAge: pref?.maxAge ?? 40,
        distanceKm: (pref?.maxDistanceKm ?? 50).toDouble(),
      ),
    );
    if (applied == true && mounted) await _load();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.size,
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
    this.gradient = false,
  });

  final double size;
  final IconData icon;
  final Color iconColor;
  final bool gradient;
  final VoidCallback onTap;

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
          boxShadow: AppColors.softShadow(gradient ? 0.4 : 0.15),
        ),
        child: Icon(icon, color: iconColor, size: size * 0.48),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.minAge,
    required this.maxAge,
    required this.distanceKm,
  });

  final int minAge;
  final int maxAge;
  final double distanceKm;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late RangeValues _age;
  late double _distance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final start = widget.minAge.clamp(18, 60).toDouble();
    final end = widget.maxAge.clamp(18, 60).toDouble();
    _age = RangeValues(start, end < start ? start : end);
    _distance = widget.distanceKm.clamp(1, 100);
  }

  Future<void> _apply() async {
    setState(() => _saving = true);
    try {
      await SessionScope.read(context).updatePreferences(
        minAge: _age.start.round(),
        maxAge: _age.end.round(),
        maxDistanceKm: _distance.round(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
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
          const SizedBox(height: 20),
          Text('Filter pencarian', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Rentang usia', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${_age.start.round()} - ${_age.end.round()} th',
                  style: text.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          RangeSlider(
            values: _age,
            min: 18,
            max: 60,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.blushDeep,
            onChanged: (v) => setState(() => _age = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Jarak maksimal', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${_distance.round()} km',
                  style: text.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
            value: _distance,
            min: 1,
            max: 100,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.blushDeep,
            onChanged: (v) => setState(() => _distance = v),
          ),
          const SizedBox(height: 20),
          GradientButton(label: 'Terapkan', loading: _saving, onPressed: _apply),
        ],
      ),
    );
  }
}
