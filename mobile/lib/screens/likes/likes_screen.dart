import 'package:flutter/material.dart';

import '../../api/dating_api.dart';
import '../../models/user_profile.dart';
import '../../state/chat_store.dart';
import '../../state/session_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_feedback.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/net_image.dart';
import '../../widgets/pressable.dart';
import '../chat/chat_room_screen.dart';
import '../discover/match_dialog.dart';
import '../discover/swipe_deck.dart';
import '../profile/premium_card.dart';
import '../profile/profile_detail_screen.dart';

/// Tab Suka: grid orang yang like kita + pilihan teratas dari discover.
/// [RefreshIndicator] = tarik ke bawah untuk muat ulang (butuh scrollable).
class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  final _api = DatingApi();
  int _tab = 0;
  bool _loading = true;
  String? _error;
  List<UserProfile> _likedYou = [];
  List<UserProfile> _topPicks = [];

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
      final likes = await _api.likes();
      final picks = await _api.discover();
      if (!mounted) return;
      setState(() {
        _likedYou = likes;
        _topPicks = picks;
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

  Future<void> _swipeLike(UserProfile profile, String action) async {
    setState(() {
      _likedYou = _likedYou.where((u) => u.id != profile.id).toList();
      _topPicks = _topPicks.where((u) => u.id != profile.id).toList();
    });

    try {
      final result = await _api.swipe(targetId: profile.id, action: action);
      if (!mounted) return;

      if (result.matched && result.matchId != null) {
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
      }
    } catch (error) {
      if (!mounted) return;
      _load();
      showApiError(context, error);
    }
  }

  Future<void> _openDetail(UserProfile profile) async {
    final direction = await Navigator.of(context).push<SwipeDirection>(
      MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(profile: profile, showActions: true),
      ),
    );
    if (!mounted || direction == null) return;
    final action = switch (direction) {
      SwipeDirection.left => 'pass',
      SwipeDirection.up => 'super_like',
      SwipeDirection.right => 'like',
    };
    await _swipeLike(profile, action);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final items = _tab == 0 ? _likedYou : _topPicks;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Suka', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      _likedYou.isEmpty
                          ? 'Belum ada yang menyukaimu. Lengkapi profil agar lebih mudah ditemukan.'
                          : '${_likedYou.length} orang tertarik denganmu',
                      style: text.bodyMedium?.copyWith(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 18),
                    _Segmented(
                      labels: const ['Suka kamu', 'Pilihan teratas'],
                      index: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                    if (_tab == 0) ...[
                      const SizedBox(height: 18),
                      PremiumCard(compact: true, isPro: SessionScope.of(context).account?.isPro ?? false),
                    ],
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Gagal memuat suka',
                  subtitle: 'Data like diambil dari database. Coba muat ulang jika koneksi sempat terputus.',
                  actionLabel: 'Coba lagi',
                  onAction: _load,
                ),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: _tab == 0 ? Icons.favorite_border_rounded : Icons.auto_awesome_rounded,
                  title: _tab == 0 ? 'Belum ada yang like kamu' : 'Belum ada pilihan teratas',
                  subtitle: _tab == 0
                      ? 'Kalau ada yang swipe kanan ke profilmu, namanya akan muncul di sini.'
                      : 'Tambah foto dan sesuaikan filter agar sistem bisa menampilkan kandidat dari database.',
                  actionLabel: 'Muat ulang',
                  onAction: _load,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _LikeCard(
                    profile: items[i],
                    featured: _tab == 1,
                    onTap: () => _openDetail(items[i]),
                    onLike: () => _swipeLike(items[i], 'like'),
                    onPass: () => _swipeLike(items[i], 'pass'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.softShadow(0.25),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                              fontWeight: FontWeight.w700,
                              color: i == index ? Colors.white : AppColors.inkSoft,
                            ),
                            child: Text(labels[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LikeCard extends StatelessWidget {
  const _LikeCard({
    required this.profile,
    required this.featured,
    required this.onTap,
    this.onLike,
    this.onPass,
  });

  final UserProfile profile;
  final bool featured;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.97,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.softShadow(0.14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetImage(profile.avatar),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.4, 1],
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${profile.name}, ${profile.age}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.distanceKm > 0
                                ? '${profile.distanceKm} km dari kamu'
                                : (profile.city.isEmpty ? 'Lokasi belum diisi' : profile.city),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (onLike != null) ...[
                      const SizedBox(width: 8),
                      Pressable(
                        onTap: onLike!,
                        scale: 0.86,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: AppColors.softShadow(0.4),
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onPass != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Pressable(
                    onTap: onPass!,
                    scale: 0.86,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              if (featured)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Top pick',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
