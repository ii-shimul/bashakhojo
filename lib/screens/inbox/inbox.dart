import 'dart:async';

import 'package:bashakhojo/screens/inbox/chat_screen.dart';
import 'package:bashakhojo/services/chat_service.dart';
import 'package:bashakhojo/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() {
    return _InboxScreenState();
  }
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> _conversations = [];
  Map<String, Map<String, dynamic>?> _lastMessages = {};
  Map<String, int> _unreadCounts = {};
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = SupabaseService.client.auth.currentUser?.id;
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> conversations =
          await ChatService.getConversations();

      Map<String, Map<String, dynamic>?> lastMessages = {};
      Map<String, int> unreadCounts = {};

      for (int i = 0; i < conversations.length; i++) {
        Map<String, dynamic> conv = conversations[i];
        String convId = conv['id'] as String;

        Map<String, dynamic>? lastMessage = await ChatService.getLastMessage(
          convId,
        );
        int unreadCount = await ChatService.getUnreadCount(convId);

        lastMessages[convId] = lastMessage;
        unreadCounts[convId] = unreadCount;
      }

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _lastMessages = lastMessages;
          _unreadCounts = unreadCounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getOtherUser(Map<String, dynamic> conversation) {
    String? tenantId = conversation['tenant_id'];

    if (tenantId == _currentUserId) {
      Map<String, dynamic>? landlord = conversation['landlord'];
      if (landlord != null) {
        return landlord;
      }
      return {};
    }

    Map<String, dynamic>? tenant = conversation['tenant'];
    if (tenant != null) {
      return tenant;
    }
    return {};
  }

  void _openConversation(
    Map<String, dynamic> conversation,
    Map<String, dynamic> otherUser,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return ChatScreen(
            conversationId: conversation['id'],
            otherUserName: otherUser['full_name'] ?? 'Unknown',
            otherUserAvatar: otherUser['avatar_url'],
          );
        },
      ),
    );
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;
    double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topPadding + 16)),
            _buildHeader(textTheme, colorScheme),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            _buildBody(colorScheme, textTheme),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme, ColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Messages',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_conversations.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(colorScheme: colorScheme, textTheme: textTheme),
      );
    }

    return SliverList.separated(
      itemCount: _conversations.length,
      separatorBuilder: (BuildContext context, int index) {
        return Divider(
          height: 1,
          indent: 84,
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        );
      },
      itemBuilder: (BuildContext context, int index) {
        return _buildConversationItem(index, colorScheme, textTheme);
      },
    );
  }

  Widget _buildConversationItem(
    int index,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    Map<String, dynamic> conversation = _conversations[index];
    Map<String, dynamic> otherUser = _getOtherUser(conversation);

    String conversationId = conversation['id'];
    Map<String, dynamic>? lastMessage = _lastMessages[conversationId];
    int unreadCount = _unreadCounts[conversationId] ?? 0;

    String name = otherUser['full_name'] ?? 'Unknown';
    String? avatarUrl = otherUser['avatar_url'];

    String lastMessageText = 'No messages yet';
    if (lastMessage != null && lastMessage['content'] != null) {
      lastMessageText = lastMessage['content'];
    }

    DateTime? timestamp;
    if (lastMessage != null && lastMessage['created_at'] != null) {
      timestamp = DateTime.parse(lastMessage['created_at']);
    }

    return ConversationTile(
      colorScheme: colorScheme,
      textTheme: textTheme,
      name: name,
      avatarUrl: avatarUrl,
      lastMessage: lastMessageText,
      timestamp: timestamp,
      unreadCount: unreadCount,
      onTap: () {
        _openConversation(conversation, otherUser);
      },
    );
  }
}

class ConversationTile extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime? timestamp;
  final int unreadCount;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.colorScheme,
    required this.textTheme,
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    this.timestamp,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(child: _buildContent(hasUnread)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    Widget avatarChild;

    if (avatarUrl != null) {
      avatarChild = Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Icon(Icons.person, color: colorScheme.onSurfaceVariant);
        },
      );
    } else {
      avatarChild = Icon(Icons.person, color: colorScheme.onSurfaceVariant);
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipOval(child: avatarChild),
    );
  }

  Widget _buildContent(bool hasUnread) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNameAndTime(hasUnread),
        const SizedBox(height: 4),
        _buildMessageAndBadge(hasUnread),
      ],
    );
  }

  Widget _buildNameAndTime(bool hasUnread) {
    FontWeight nameWeight;
    if (hasUnread) {
      nameWeight = FontWeight.bold;
    } else {
      nameWeight = FontWeight.w600;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: nameWeight,
              color: colorScheme.onSurface,
              fontFamily: 'Noto Sans Bengali',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (timestamp != null) _buildTimestamp(hasUnread),
      ],
    );
  }

  Widget _buildTimestamp(bool hasUnread) {
    Color timeColor;
    FontWeight timeWeight;

    if (hasUnread) {
      timeColor = colorScheme.primary;
      timeWeight = FontWeight.w600;
    } else {
      timeColor = colorScheme.onSurfaceVariant;
      timeWeight = FontWeight.normal;
    }

    return Text(
      timeago.format(timestamp!, locale: 'en_short'),
      style: TextStyle(fontSize: 12, color: timeColor, fontWeight: timeWeight),
    );
  }

  Widget _buildMessageAndBadge(bool hasUnread) {
    Color messageColor;
    FontWeight messageWeight;

    if (hasUnread) {
      messageColor = colorScheme.onSurface;
      messageWeight = FontWeight.w500;
    } else {
      messageColor = colorScheme.onSurfaceVariant;
      messageWeight = FontWeight.normal;
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            lastMessage,
            style: TextStyle(
              fontSize: 14,
              color: messageColor,
              fontWeight: messageWeight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasUnread) _buildUnreadBadge(),
      ],
    );
  }

  Widget _buildUnreadBadge() {
    String badgeText;
    if (unreadCount > 99) {
      badgeText = '99+';
    } else {
      badgeText = unreadCount.toString();
    }

    return Row(
      children: [
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const EmptyState({
    super.key,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No Messages Yet",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start a conversation by contacting\na property owner",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
