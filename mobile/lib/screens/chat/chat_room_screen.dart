import 'package:flutter/material.dart';

import '../../models/chat.dart';
import '../../state/chat_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_feedback.dart';
import '../../utils/time_format.dart';
import '../../widgets/avatar.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/pressable.dart';
import '../profile/profile_detail_screen.dart';
import 'typing_indicator.dart';

/// Ruang chat satu match.
/// [ListView.reverse] = pesan terbaru di bawah, seperti WhatsApp.
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  static const _icebreakers = [
    'Hai! Senang bisa match sama kamu 😊',
    'Kopi atau teh? ☕🍵',
    'Rencana akhir pekan ini apa?',
    'Tempat makan favoritmu di mana?',
  ];

  final _input = TextEditingController();
  final _focus = FocusNode();
  late final ChatStore _store;
  bool _loadingMessages = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _store = ChatScope.read(context);
    _store.setActive(widget.conversation.id);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _store.loadMessages(widget.conversation);
        await _store.markRead(widget.conversation);
      } catch (error) {
        if (mounted) showApiError(context, error);
      } finally {
        if (mounted) setState(() => _loadingMessages = false);
      }
    });
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _store.setActive(null);
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// [preset] diisi icebreaker; kalau null, ambil teks dari composer.
  /// Jangan clear input sebelum API sukses, supaya gagal jaringan tidak kehilangan teks.
  Future<void> _send([String? preset]) async {
    if (_loadingMessages || _sending) return;
    final value = preset ?? _input.text;
    if (value.trim().isEmpty) return;
    setState(() => _sending = true);
    if (preset == null) _input.clear();
    try {
      await _store.send(widget.conversation, value);
    } catch (error) {
      if (preset == null) _input.text = value;
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    _focus.requestFocus();
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature segera hadir 🚀')));
  }

  @override
  Widget build(BuildContext context) {
    final store = ChatScope.of(context);
    final c = widget.conversation;
    final typing = store.isTyping(c.id);
    final messages = c.messages.reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.blush,
      body: Column(
        children: [
          _Header(
            conversation: c,
            typing: typing,
            onCall: () => _comingSoon('Panggilan suara'),
            onVideo: () => _comingSoon('Video call'),
          ),
          Expanded(
            child: _loadingMessages
                ? const Center(child: CircularProgressIndicator())
                : c.messages.isEmpty
                ? _Icebreakers(conversation: c, lines: _icebreakers, onPick: _send)
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: messages.length + 1 + (typing ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (typing && i == 0) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(padding: EdgeInsets.only(top: 6), child: TypingIndicator()),
                        );
                      }
                      final index = typing ? i - 1 : i;
                      if (index == messages.length) return const _DayChip(label: 'Hari ini');

                      final m = messages[index];
                      final newer = index > 0 ? messages[index - 1] : null;
                      final isLastInGroup = newer == null || newer.isMe != m.isMe;
                      return _Bubble(message: m, showTail: isLastInGroup);
                    },
                  ),
          ),
          _Composer(
            controller: _input,
            focusNode: _focus,
            enabled: !_loadingMessages && !_sending,
            onSend: _send,
            onAttach: () => _comingSoon('Kirim foto'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.conversation, required this.typing, required this.onCall, required this.onVideo});

  final Conversation conversation;
  final bool typing;
  final VoidCallback onCall;
  final VoidCallback onVideo;

  @override
  Widget build(BuildContext context) {
    final user = conversation.user;
    final status = typing ? 'sedang mengetik...' : (user.isOnline ? 'Online' : 'Terakhir aktif baru saja');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: AppColors.softShadow(0.08),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
              Expanded(
                child: Pressable(
                  scale: 0.98,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: user, showActions: false)),
                  ),
                  child: Row(
                    children: [
                      Avatar(url: user.avatar, size: 46, online: user.isOnline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(user.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                                ),
                                if (user.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, color: Color(0xFF5AB8FF), size: 16),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                status,
                                key: ValueKey(status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: typing || user.isOnline ? AppColors.primary : AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CircleIconButton(icon: Icons.call_rounded, size: 42, color: AppColors.primary, onTap: onCall),
              const SizedBox(width: 8),
              CircleIconButton(icon: Icons.videocam_rounded, size: 42, color: AppColors.primary, onTap: onVideo),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: AppColors.blushDeep, borderRadius: BorderRadius.circular(14)),
        child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDeep)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.showTail});

  final ChatMessage message;
  final bool showTail;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.74;
    const r = Radius.circular(22);
    const tail = Radius.circular(6);

    final radius = BorderRadius.only(
      topLeft: r,
      topRight: r,
      bottomLeft: !isMe && showTail ? tail : r,
      bottomRight: isMe && showTail ? tail : r,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: EdgeInsets.only(top: 3, bottom: showTail ? 10 : 3),
          padding: const EdgeInsets.fromLTRB(16, 11, 12, 8),
          decoration: BoxDecoration(
            gradient: isMe ? AppColors.primaryGradient : null,
            color: isMe ? null : Colors.white,
            borderRadius: radius,
            boxShadow: isMe ? AppColors.softShadow(0.22) : AppColors.softShadow(0.06),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppColors.ink,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatClock(message.sentAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white.withValues(alpha: 0.8) : AppColors.inkSoft,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 15,
                      color: Colors.white.withValues(alpha: message.isRead ? 1 : 0.75),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Icebreakers extends StatelessWidget {
  const _Icebreakers({required this.conversation, required this.lines, required this.onPick});

  final Conversation conversation;
  final List<String> lines;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final user = conversation.user;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        Center(child: Avatar(url: user.avatar, size: 110, ring: true)),
        const SizedBox(height: 18),
        Text('Kamu match dengan ${user.name} 💕',
            textAlign: TextAlign.center, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Mulai obrolan dengan sapaan yang hangat. Pilih salah satu atau tulis sendiri.',
            textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: AppColors.inkSoft)),
        const SizedBox(height: 24),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Pressable(
              scale: 0.97,
              onTap: () => onPick(line),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(line, style: const TextStyle(fontWeight: FontWeight.w600))),
                    const Icon(Icons.send_rounded, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool enabled;

  static const _emojis = ['😊', '😂', '😍', '🥰', '🙈', '👍', '🔥', '❤️'];

  void _insertEmoji(String emoji) {
    final sel = controller.selection;
    final text = controller.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, emoji),
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _emojis)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _insertEmoji(e);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(e, style: const TextStyle(fontSize: 30)),
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
    final canSend = enabled && controller.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppColors.softShadow(0.1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Emoji',
                      onPressed: () => _showEmojiPicker(context),
                      icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.inkSoft),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: enabled,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: enabled ? (_) => onSend() : null,
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan...',
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onAttach,
                      icon: const Icon(Icons.image_outlined, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Pressable(
              onTap: canSend ? onSend : null,
              scale: 0.85,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: canSend ? AppColors.primaryGradient : null,
                  color: canSend ? null : AppColors.primarySoft,
                  boxShadow: canSend ? AppColors.softShadow(0.4) : null,
                ),
                child: AnimatedRotation(
                  turns: canSend ? 0 : -0.1,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
