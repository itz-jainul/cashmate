import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/chat_message_model.dart';
import '../providers/exchange_provider.dart';

class MeetupChatWidget extends ConsumerStatefulWidget {
  final String chatId;
  final String currentUserId;
  final String currentUserName;
  final bool isReadOnly;
  final String? location;

  const MeetupChatWidget({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.currentUserName,
    this.isReadOnly = false,
    this.location,
  });

  @override
  ConsumerState<MeetupChatWidget> createState() => _MeetupChatWidgetState();
}

class _MeetupChatWidgetState extends ConsumerState<MeetupChatWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  final List<String> _quickPings = [
    '📍 Reached the meetup spot',
    '⏳ On my way! (2-3 mins away)',
    '🚪 Waiting near the entrance',
    '👕 Wearing dark hoodie/jacket',
    '👋 Looking for you right now',
    '🥤 Sitting at table/counter',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text, {bool isQuickPing = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final service = ref.read(exchangeServiceProvider);
      await service.sendChatMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        text: trimmed,
        isQuickPing: isQuickPing,
      );

      if (!isQuickPing) {
        _textController.clear();
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        final isPermission = e.toString().toLowerCase().contains('permission-denied');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusCancelled,
            content: Text(
              isPermission
                  ? 'Permission Denied: Publish updated firestore.rules in Firebase Console to enable chat.'
                  : 'Failed to send: ${e.toString()}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meetup Coordination Chat',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Coordinate arrival safely • Zero phone number sharing',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isReadOnly
                        ? AppColors.surfaceVariant
                        : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: widget.isReadOnly
                            ? AppColors.textMuted
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        widget.isReadOnly ? 'Closed' : 'Live Pings',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.isReadOnly
                              ? AppColors.textMuted
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Messages Container
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: messagesAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (err, _) {
                  final isPermission =
                      err.toString().toLowerCase().contains('permission-denied');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPermission
                                ? Icons.security_rounded
                                : Icons.error_outline_rounded,
                            color: AppColors.statusCancelled,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isPermission
                                ? 'Missing Firestore Permissions'
                                : 'Unable to load chat',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusCancelled,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPermission
                                ? 'Please publish the updated firestore.rules in Firebase Console.'
                                : err.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () =>
                                ref.invalidate(chatMessagesProvider(widget.chatId)),
                            icon: const Icon(Icons.refresh_rounded, size: 14),
                            label: const Text('Retry', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.near_me_outlined,
                              size: 32,
                              color: AppColors.textMuted.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No coordination pings yet',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.isReadOnly
                                  ? 'Exchange has ended.'
                                  : 'Tap a quick ping below to notify your meetup partner!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Auto scroll when messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == widget.currentUserId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  );
                },
              ),
            ),

            if (!widget.isReadOnly) ...[
              const SizedBox(height: 12),
              // Quick Ping Header
              const Text(
                '⚡ Quick Status Pings (Tap to send instantly):',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              // Quick Ping Chips List
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickPings.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final ping = _quickPings[index];
                    return ActionChip(
                      label: Text(
                        ping,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      backgroundColor: AppColors.surfaceVariant,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      onPressed: _isSending ? null : () => _sendMessage(ping, isQuickPing: true),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Custom Message Input
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _textController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a custom note...',
                          hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 6),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onSubmitted: (val) => _sendMessage(val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _isSending ? null : () => _sendMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMe ? 'You' : msg.senderName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isMe ? AppColors.primary : AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTime(msg.createdAt),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
                if (msg.isQuickPing) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.bolt, size: 10, color: AppColors.statusSearching),
                ],
              ],
            ),
          ),
          // Bubble
          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isMe ? 12 : 2),
                bottomRight: Radius.circular(isMe ? 2 : 12),
              ),
              border: isMe ? null : Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: msg.isQuickPing ? FontWeight.w600 : FontWeight.w400,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
