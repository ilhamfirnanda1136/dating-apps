import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/chat.dart';
import '../../state/chat_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_feedback.dart';
import '../../utils/time_format.dart';
import '../../widgets/avatar.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/net_image.dart';
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

  // Fitur Reply
  ChatMessage? _replyingTo;

  // Fitur Upload Image
  Uint8List? _attachedBytes;
  String? _uploadedUrl;
  bool _uploadingImage = false;

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
    _input.addListener(() {
      setState(() {});
      _store.sendTyping(widget.conversation.id, _input.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _store.sendTyping(widget.conversation.id, false);
    _store.setActive(null);
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _attachedBytes = bytes;
        _uploadingImage = true;
      });

      final url = await _store.uploadImage(
        bytes: bytes,
        filename: picked.name,
        mimeType: picked.mimeType ?? 'image/jpeg',
      );
      if (mounted) {
        setState(() {
          _uploadedUrl = url;
          _uploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _attachedBytes = null;
          _uploadedUrl = null;
          _uploadingImage = false;
        });
        showApiError(context, e);
      }
    }
  }

  void _showAttachOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Galeri Foto', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Pilih foto dari galeri perangkat'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.blushDeep,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryDeep),
                ),
                title: const Text('Kamera', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Ambil foto langsung dengan kamera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  void _clearAttachment() {
    setState(() {
      _attachedBytes = null;
      _uploadedUrl = null;
      _uploadingImage = false;
    });
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.reply_rounded, color: AppColors.primary),
                ),
                title: const Text('Balas Pesan', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  message.text.isNotEmpty
                      ? message.text
                      : (message.mediaUrl != null ? '[Foto]' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _replyingTo = message);
                  _focus.requestFocus();
                },
              ),
              if (message.text.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.blush,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.copy_rounded, color: AppColors.ink),
                  ),
                  title: const Text('Salin Teks', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pesan disalin ke clipboard')),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        barrierDismissible: true,
        pageBuilder: (ctx, anim1, anim2) => Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.5,
              child: NetImage(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  /// [preset] diisi icebreaker; kalau null, ambil teks dari composer.
  Future<void> _send([String? preset]) async {
    if (_loadingMessages || _sending || _uploadingImage) return;
    final value = preset ?? _input.text;
    final hasText = value.trim().isNotEmpty;
    final hasImage = _uploadedUrl != null && _uploadedUrl!.isNotEmpty;
    if (!hasText && !hasImage) return;

    setState(() => _sending = true);
    final textToSend = value;
    final mediaToSend = _uploadedUrl;
    final replyIdToSend = _replyingTo?.id;

    if (preset == null) _input.clear();
    _clearAttachment();
    _cancelReply();

    try {
      await _store.send(
        widget.conversation,
        textToSend,
        mediaUrl: mediaToSend,
        replyToId: replyIdToSend,
      );
    } catch (error) {
      if (preset == null) _input.text = textToSend;
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
                      return _Bubble(
                        message: m,
                        showTail: isLastInGroup,
                        conversation: c,
                        onReply: () {
                          setState(() => _replyingTo = m);
                          _focus.requestFocus();
                        },
                        onLongPress: () => _showMessageOptions(m),
                        onImageTap: (url) => _showFullscreenImage(context, url),
                      );
                    },
                  ),
          ),
          _Composer(
            controller: _input,
            focusNode: _focus,
            enabled: !_loadingMessages && !_sending,
            onSend: _send,
            onAttach: _showAttachOptions,
            replyingTo: _replyingTo,
            partnerName: c.user.name,
            onCancelReply: _cancelReply,
            attachedBytes: _attachedBytes,
            uploadingImage: _uploadingImage,
            onClearAttachment: _clearAttachment,
            hasUploadedImage: _uploadedUrl != null,
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
  const _Bubble({
    required this.message,
    required this.showTail,
    required this.conversation,
    required this.onReply,
    required this.onLongPress,
    required this.onImageTap,
  });

  final ChatMessage message;
  final bool showTail;
  final Conversation conversation;
  final VoidCallback onReply;
  final VoidCallback onLongPress;
  final ValueChanged<String> onImageTap;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.76;
    const r = Radius.circular(22);
    const tail = Radius.circular(6);

    final radius = BorderRadius.only(
      topLeft: r,
      topRight: r,
      bottomLeft: !isMe && showTail ? tail : r,
      bottomRight: isMe && showTail ? tail : r,
    );

    final reply = message.replyTo;
    final hasMedia = message.mediaUrl != null && message.mediaUrl!.isNotEmpty;
    final hasText = message.text.trim().isNotEmpty;

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
        child: GestureDetector(
          onLongPress: onLongPress,
          onDoubleTap: onReply,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            margin: EdgeInsets.only(top: 3, bottom: showTail ? 10 : 3),
            padding: EdgeInsets.fromLTRB(
              hasMedia && !hasText && reply == null ? 4 : 12,
              hasMedia && !hasText && reply == null ? 4 : 10,
              hasMedia && !hasText && reply == null ? 4 : 12,
              8,
            ),
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
                // Kuotasi Pesan yang dibalas (Reply Quote Box)
                if (reply != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.black.withValues(alpha: 0.15)
                          : AppColors.blush.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: isMe ? Colors.white : AppColors.primary,
                          width: 3.5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reply.senderId != null && !isMe
                              ? 'Pesan Dibalas'
                              : 'Membalas',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isMe ? Colors.white : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (reply.mediaUrl != null) ...[
                              Icon(
                                Icons.image_rounded,
                                size: 14,
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : AppColors.inkSoft,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                reply.content.isNotEmpty
                                    ? reply.content
                                    : (reply.mediaUrl != null ? 'Foto' : ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMe
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Gambar Lampiran Chat
                if (hasMedia) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GestureDetector(
                      onTap: () => onImageTap(message.mediaUrl!),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            constraints: const BoxConstraints(
                              maxHeight: 260,
                              minHeight: 140,
                              minWidth: 160,
                            ),
                            width: double.infinity,
                            color: Colors.black12,
                            child: NetImage(
                              message.mediaUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasText) const SizedBox(height: 6),
                ],

                // Teks Pesan
                if (hasText) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: hasMedia ? 4 : 2,
                        vertical: hasMedia ? 2 : 0,
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : AppColors.ink,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 4),

                // Jam & Indikator Centang
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatClock(message.sentAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppColors.inkSoft,
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
                ),
              ],
            ),
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
    this.replyingTo,
    required this.partnerName,
    required this.onCancelReply,
    this.attachedBytes,
    this.uploadingImage = false,
    required this.onClearAttachment,
    this.hasUploadedImage = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool enabled;

  final ChatMessage? replyingTo;
  final String partnerName;
  final VoidCallback onCancelReply;

  final Uint8List? attachedBytes;
  final bool uploadingImage;
  final VoidCallback onClearAttachment;
  final bool hasUploadedImage;

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
    final hasText = controller.text.trim().isNotEmpty;
    final canSend = enabled && !uploadingImage && (hasText || hasUploadedImage);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner Reply Preview jika sedang membalas pesan
          if (replyingTo != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.softShadow(0.08),
                border: const Border(
                  left: BorderSide(color: AppColors.primary, width: 4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Membalas ${replyingTo!.isMe ? 'diri Anda' : partnerName}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          replyingTo!.text.isNotEmpty
                              ? replyingTo!.text
                              : (replyingTo!.mediaUrl != null ? '[Foto]' : ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.inkSoft),
                    onPressed: onCancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ],

          // Banner Image Attachment Preview jika ada foto yang dipilih/diunggah
          if (attachedBytes != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.softShadow(0.08),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.memory(
                          attachedBytes!,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                        if (uploadingImage)
                          Container(
                            width: 54,
                            height: 54,
                            color: Colors.black45,
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          uploadingImage ? 'Mengunggah foto...' : 'Foto terlampir',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          uploadingImage ? 'Mohon tunggu sebentar' : 'Siap dikirim',
                          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.inkSoft),
                    onPressed: onClearAttachment,
                  ),
                ],
              ),
            ),
          ],

          // Input Bar Utama
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
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
                            onSubmitted: canSend ? (_) => onSend() : null,
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
                          tooltip: 'Kirim Foto',
                          onPressed: enabled ? onAttach : null,
                          icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
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
        ],
      ),
    );
  }
}
