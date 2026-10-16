import 'package:flutter/material.dart';

import '../../models/chat.dart';
import '../../models/user_profile.dart';
import '../../state/chat_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/time_format.dart';
import '../../widgets/avatar.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pressable.dart';
import 'chat_room_screen.dart';

/// Daftar percakapan. [CustomScrollView] + sliver biar header, search,
/// match baru, dan list bisa di-scroll sebagai satu kesatuan.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _query = '';

  void _open(BuildContext context, Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatRoomScreen(conversation: conversation)),
    );
  }

  void _compose(BuildContext context, ChatStore store) {
    final people = [
      ...store.newMatches,
      ...store.conversations.map((c) => c.user),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
              Text('Pesan baru', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (people.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.softShadow(0.2),
                        ),
                        child: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 16),
                      const Text('Belum ada match', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text(
                        'Swipe kanan dulu. Kalau kalian cocok, percakapan bisa dimulai dari sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.inkSoft, height: 1.45),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    itemCount: people.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.line),
                    itemBuilder: (context, i) {
                      final user = people[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Avatar(url: user.avatar, size: 46, online: user.isOnline),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(user.city, style: const TextStyle(color: AppColors.inkSoft)),
                        onTap: () {
                          Navigator.of(sheet).pop();
                          _open(context, store.openWith(user));
                        },
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

  @override
  Widget build(BuildContext context) {
    final store = ChatScope.of(context);
    final text = Theme.of(context).textTheme;
    final q = _query.toLowerCase();
    final conversations =
        store.conversations.where((c) => c.user.name.toLowerCase().contains(q)).toList();

    final empty = store.conversations.isEmpty && store.newMatches.isEmpty && q.isEmpty;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: store.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Text('Pesan', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    if (store.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${store.unreadCount} baru',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    const Spacer(),
                    CircleIconButton(icon: Icons.edit_note_rounded, onTap: () => _compose(context, store)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Cari match kamu...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.inkSoft),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            if (store.loading && empty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (store.error != null && empty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Pesan gagal dimuat',
                  subtitle: 'Match dan percakapan diambil dari database. Coba lagi jika koneksi sempat putus.',
                  actionLabel: 'Coba lagi',
                  onAction: store.load,
                ),
              )
            else if (empty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Belum ada percakapan',
                  subtitle: 'Kalau kamu match dengan seseorang, obrolan dan match baru akan tampil di halaman ini.',
                ),
              )
            else ...[
              if (store.newMatches.isNotEmpty && q.isEmpty) ...[
                SliverToBoxAdapter(child: _SectionHeader(title: 'Match baru', count: store.newMatches.length)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: store.newMatches.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 16),
                      itemBuilder: (context, i) {
                        final user = store.newMatches[i];
                        return _NewMatchItem(
                          user: user,
                          onTap: () => _open(context, store.openWith(user)),
                        );
                      },
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(child: _SectionHeader(title: 'Percakapan', count: conversations.length)),
              if (conversations.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Tidak ada percakapan yang cocok',
                      subtitle: 'Coba kata kunci lain, atau mulai obrolan dari match baru.',
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final c = conversations[i];
                    return _ConversationTile(
                      conversation: c,
                      typing: store.isTyping(c.id),
                      onTap: () => _open(context, c),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          Text('($count)', style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _NewMatchItem extends StatelessWidget {
  const _NewMatchItem({required this.user, required this.onTap});

  final UserProfile user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Column(
        children: [
          Avatar(url: user.avatar, size: 64, ring: true, online: user.isOnline),
          const SizedBox(height: 8),
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.typing, required this.onTap});

  final Conversation conversation;
  final bool typing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final last = c.lastMessage;
    final unread = c.unread > 0;

    final preview = typing
        ? const Text('sedang mengetik...',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic))
        : Row(
            children: [
              if (last != null && last.isMe) ...[
                Icon(
                  Icons.done_all_rounded,
                  size: 16,
                  color: last.isRead ? AppColors.primary : AppColors.inkSoft,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  last?.text ?? 'Kalian baru saja match! Sapa duluan 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unread ? AppColors.ink : AppColors.inkSoft,
                    fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          );

    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unread ? Colors.white : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          boxShadow: unread ? AppColors.softShadow(0.1) : null,
        ),
        child: Row(
          children: [
            Avatar(url: c.user.avatar, size: 56, online: c.user.isOnline),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(c.user.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      if (c.user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: Color(0xFF5AB8FF), size: 16),
                      ],
                      const Spacer(),
                      if (last != null)
                        Text(
                          formatChatTime(last.sentAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: unread ? AppColors.primary : AppColors.inkSoft,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: preview),
                      if (unread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text('${c.unread}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
