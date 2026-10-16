import 'package:flutter/material.dart';

import '../../api/dating_api.dart';
import '../../state/chat_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/time_format.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pressable.dart';
import '../../widgets/soft_background.dart';
import '../chat/chat_room_screen.dart';

/// Daftar notifikasi dari database. Bukan dummy — kosong jika belum ada event.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = DatingApi();
  List<AppNotification> _items = [];
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
      final rows = await _api.notifications();
      if (!mounted) return;
      setState(() {
        _items = rows;
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

  IconData _iconFor(String type) {
    return switch (type) {
      'match' => Icons.favorite_rounded,
      'message' => Icons.chat_bubble_rounded,
      'like' || 'super_like' => Icons.favorite_outline_rounded,
      'premium' || 'promo' => Icons.workspace_premium_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Future<void> _open(AppNotification item) async {
    if (!item.isRead) {
      try {
        await _api.markNotificationRead(item.id);
        if (mounted) {
          setState(() {
            _items = [
              for (final row in _items)
                if (row.id == item.id)
                  AppNotification(
                    id: row.id,
                    type: row.type,
                    title: row.title,
                    body: row.body,
                    createdAt: row.createdAt,
                    isRead: true,
                    matchId: row.matchId,
                  )
                else
                  row,
            ];
          });
        }
      } catch (_) {}
    }

    final matchId = item.matchId;
    if (matchId == null || !mounted) return;
    final conversation = ChatScope.read(context).byMatchId(matchId);
    if (conversation == null) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatRoomScreen(conversation: conversation)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
                child: Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      size: 44,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text('Notifikasi', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? EmptyState(
                            icon: Icons.wifi_off_rounded,
                            title: 'Notifikasi gagal dimuat',
                            subtitle: 'Coba lagi untuk mengambil pemberitahuan dari database.',
                            actionLabel: 'Coba lagi',
                            onAction: _load,
                          )
                        : _items.isEmpty
                            ? EmptyState(
                                icon: Icons.notifications_none_rounded,
                                title: 'Belum ada notifikasi',
                                subtitle: 'Match, pesan, dan like baru akan muncul di sini begitu ada data di akunmu.',
                                actionLabel: 'Muat ulang',
                                onAction: _load,
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _items.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final n = _items[i];
                                  return Pressable(
                                    onTap: () => _open(n),
                                    scale: 0.98,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: n.isRead ? Colors.white.withValues(alpha: 0.72) : Colors.white,
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: AppColors.softShadow(n.isRead ? 0.04 : 0.1),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: const BoxDecoration(
                                              gradient: AppColors.primaryGradient,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(_iconFor(n.type), color: Colors.white, size: 22),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  n.body.isEmpty ? 'Ada kabar baru untukmu.' : n.body,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: AppColors.inkSoft, height: 1.35),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            formatChatTime(n.createdAt),
                                            style: const TextStyle(
                                              color: AppColors.inkSoft,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
