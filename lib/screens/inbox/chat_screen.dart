import 'dart:async';

import 'package:bashakhojo/services/chat_service.dart';
import 'package:bashakhojo/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() {
    return _ChatScreenState();
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  String? _currentUserId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = SupabaseService.client.auth.currentUser?.id;
    _loadMessages();
    _subscribeToMessages();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    List<Map<String, dynamic>> messages = await ChatService.getMessages(
      widget.conversationId,
    );

    if (mounted) {
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    }
  }

  void _subscribeToMessages() {
    Stream<List<Map<String, dynamic>>> stream = ChatService.subscribeToMessages(
      widget.conversationId,
    );

    _subscription = stream.listen((List<Map<String, dynamic>> messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
        _markAsRead();
      }
    });
  }

  Future<void> _markAsRead() async {
    await ChatService.markMessagesAsRead(widget.conversationId);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    String content = _messageController.text.trim();

    if (content.isEmpty) {
      return;
    }
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    try {
      await ChatService.sendMessage(
        conversationId: widget.conversationId,
        content: content,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  bool _shouldShowDate(String prevDateString, String currentDateString) {
    DateTime prev = DateTime.parse(prevDateString);
    DateTime current = DateTime.parse(currentDateString);

    bool differentDay = prev.day != current.day;
    bool differentMonth = prev.month != current.month;
    bool differentYear = prev.year != current.year;

    return differentDay || differentMonth || differentYear;
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(colorScheme, textTheme),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList(colorScheme)),
          _buildMessageInput(colorScheme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _buildAppBarAvatar(colorScheme),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.otherUserName,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontFamily: 'Noto Sans Bengali',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildAppBarAvatar(ColorScheme colorScheme) {
    Widget avatarChild;

    if (widget.otherUserAvatar != null) {
      avatarChild = Image.network(
        widget.otherUserAvatar!,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Icon(
            Icons.person,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          );
        },
      );
    } else {
      avatarChild = Icon(
        Icons.person,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      );
    }

    return Container(
      width: 40,
      height: 40,
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

  Widget _buildMessagesList(ColorScheme colorScheme) {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet.\nSay hello! 👋',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (BuildContext context, int index) {
        return _buildMessageItem(index, colorScheme);
      },
    );
  }

  Widget _buildMessageItem(int index, ColorScheme colorScheme) {
    Map<String, dynamic> message = _messages[index];
    bool isMe = message['sender_id'] == _currentUserId;

    bool showDate = false;
    if (index == 0) {
      showDate = true;
    } else {
      String prevDate = _messages[index - 1]['created_at'];
      String currentDate = message['created_at'];
      showDate = _shouldShowDate(prevDate, currentDate);
    }

    DateTime messageTime = DateTime.parse(message['created_at']);
    String messageContent = message['content'];

    List<Widget> children = [];

    if (showDate) {
      children.add(
        DateSeparator(date: messageTime, colorScheme: colorScheme),
      );
    }

    children.add(
      MessageBubble(
        message: messageContent,
        time: messageTime,
        isMe: isMe,
        colorScheme: colorScheme,
      ),
    );

    return Column(children: children);
  }

  Widget _buildMessageInput(ColorScheme colorScheme) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTextField(colorScheme)),
          const SizedBox(width: 8),
          _buildSendButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildTextField(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: _messageController,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 4,
        minLines: 1,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Type a message...',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onSubmitted: (String value) {
          _sendMessage();
        },
      ),
    );
  }

  Widget _buildSendButton(ColorScheme colorScheme) {
    Widget buttonIcon;

    if (_isSending) {
      buttonIcon = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.onPrimary,
        ),
      );
    } else {
      buttonIcon = Icon(Icons.send, color: colorScheme.onPrimary, size: 20);
    }

    VoidCallback? onPressed;
    if (!_isSending) {
      onPressed = _sendMessage;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(onPressed: onPressed, icon: buttonIcon),
    );
  }
}

class DateSeparator extends StatelessWidget {
  final DateTime date;
  final ColorScheme colorScheme;

  const DateSeparator({
    super.key,
    required this.date,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    String dateText = _getDateText();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _getDateText() {
    DateTime now = DateTime.now();

    bool isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    bool isYesterday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1;

    if (isToday) {
      return 'Today';
    } else if (isYesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final DateTime time;
  final bool isMe;
  final ColorScheme colorScheme;

  const MessageBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isMe,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width * 0.75;

    Alignment alignment;
    if (isMe) {
      alignment = Alignment.centerRight;
    } else {
      alignment = Alignment.centerLeft;
    }

    Color backgroundColor;
    if (isMe) {
      backgroundColor = colorScheme.primary;
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.5,
      );
    }

    BorderRadius borderRadius = _getBorderRadius();

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildMessageText(),
            const SizedBox(height: 4),
            _buildTimeText(),
          ],
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    Radius topLeft = const Radius.circular(16);
    Radius topRight = const Radius.circular(16);
    Radius bottomLeft;
    Radius bottomRight;

    if (isMe) {
      bottomLeft = const Radius.circular(16);
      bottomRight = const Radius.circular(4);
    } else {
      bottomLeft = const Radius.circular(4);
      bottomRight = const Radius.circular(16);
    }

    return BorderRadius.only(
      topLeft: topLeft,
      topRight: topRight,
      bottomLeft: bottomLeft,
      bottomRight: bottomRight,
    );
  }

  Widget _buildMessageText() {
    Color textColor;
    if (isMe) {
      textColor = colorScheme.onPrimary;
    } else {
      textColor = colorScheme.onSurface;
    }

    return Text(message, style: TextStyle(color: textColor, fontSize: 15));
  }

  Widget _buildTimeText() {
    Color timeColor;
    if (isMe) {
      timeColor = colorScheme.onPrimary.withValues(alpha: 0.7);
    } else {
      timeColor = colorScheme.onSurfaceVariant;
    }

    String timeString = DateFormat('HH:mm').format(time);

    return Text(timeString, style: TextStyle(fontSize: 10, color: timeColor));
  }
}
