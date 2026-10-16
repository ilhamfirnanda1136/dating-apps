import 'package:flutter/material.dart';

import '../state/chat_store.dart';
import '../theme/app_colors.dart';
import '../widgets/pressable.dart';
import '../widgets/soft_background.dart';
import 'chat/chat_list_screen.dart';
import 'discover/discover_screen.dart';
import 'likes/likes_screen.dart';
import 'profile/profile_screen.dart';

/// Kerangka utama setelah login: 4 tab.
/// [IndexedStack] menyimpan SEMUA tab tetap hidup (state Discover tidak hilang
/// saat pindah ke Chat). Hanya tab [_index] yang terlihat.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatScope.read(context).load();
    });
  }

  /// Ganti tab. [setState] = "data berubah, tolong gambar ulang".
  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final unread = ChatScope.of(context).unreadCount;

    return Scaffold(
      extendBody: true,
      body: SoftBackground(
        child: IndexedStack(
          index: _index,
          children: [
            const DiscoverScreen(),
            const LikesScreen(),
            const ChatListScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onChanged: _goTo,
        chatBadge: unread,
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onChanged, required this.chatBadge});

  final int index;
  final ValueChanged<int> onChanged;
  final int chatBadge;

  static const _items = [
    _NavItem(Icons.style_outlined, Icons.style_rounded, 'Jelajah'),
    _NavItem(Icons.favorite_border_rounded, Icons.favorite_rounded, 'Suka'),
    _NavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.softShadow(0.18),
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                flex: i == index ? 3 : 2,
                child: Pressable(
                  onTap: () => onChanged(i),
                  child: _NavButton(
                    item: _items[i],
                    selected: i == index,
                    badge: i == 2 ? chatBadge : 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.badge});

  final _NavItem item;
  final bool selected;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          selected ? item.activeIcon : item.icon,
          color: selected ? Colors.white : AppColors.inkSoft,
          size: 24,
        ),
        if (badge > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? AppColors.primary : Colors.white, width: 1.5),
              ),
              child: Text(
                '$badge',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.primary : Colors.white,
                ),
              ),
            ),
          ),
      ],
    );

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 0),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected ? AppColors.softShadow(0.3) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (selected) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
