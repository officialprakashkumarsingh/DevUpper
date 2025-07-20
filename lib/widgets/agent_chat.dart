import 'package:flutter/material.dart';
import '../models/repository.dart';
import '../services/ai_service.dart';

class AgentChat extends StatefulWidget {
  final AIService aiService;
  final Repository? selectedRepository;
  final List<Repository> repositories;
  final Function(Repository?) onRepositoryChanged;

  const AgentChat({
    super.key,
    required this.aiService,
    required this.selectedRepository,
    required this.repositories,
    required this.onRepositoryChanged,
  });

  @override
  State<AgentChat> createState() => _AgentChatState();
}

class _AgentChatState extends State<AgentChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text: "Hello! I'm your AI development assistant. I can help you with:\n\n"
            "• Code generation and review\n"
            "• Repository analysis\n"
            "• Bug fixing and refactoring\n"
            "• Creating pull requests\n"
            "• Running tests and more!\n\n"
            "Select a repository and ask me anything!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Get AI response
      final response = await widget.aiService.chatWithAgent(
        message,
        repository: widget.selectedRepository,
        conversationHistory: _messages
            .where((m) => !m.isUser)
            .map((m) => m.text)
            .toList(),
      );

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I encountered an error: ${e.toString()}",
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showSuggestions() async {
    try {
      final suggestions = await widget.aiService.getSuggestions(
        _messageController.text,
        repository: widget.selectedRepository,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _SuggestionsDialog(
            suggestions: suggestions,
            onSelected: (suggestion) {
              _messageController.text = suggestion;
              Navigator.pop(context);
            },
          ),
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRepositorySelector(),
        Expanded(
          child: _buildMessagesList(),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildRepositorySelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Repository?>(
          value: widget.selectedRepository,
          hint: const Text('Select repository'),
          isExpanded: true,
          items: [
            const DropdownMenuItem<Repository?>(
              value: null,
              child: Text('No repository selected'),
            ),
            ...widget.repositories.map((repo) {
              return DropdownMenuItem<Repository?>(
                value: repo,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: repo.isPrivate ? Colors.orange : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        repo.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: widget.onRepositoryChanged,
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator();
        }

        final message = _messages[index];
        return _buildMessage(message);
      },
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(false),
          if (!message.isUser) const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : message.isError
                        ? Colors.red.shade50
                        : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: message.isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: message.isError
                    ? Border.all(color: Colors.red.shade200)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : message.isError
                              ? Colors.red.shade700
                              : Colors.grey.shade800,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 12),
          if (message.isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade600,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _buildAvatar(false),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade400.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _showSuggestions,
            icon: Icon(
              Icons.lightbulb_outline,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask me anything about your code...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _sendMessage,
              icon: Icon(
                _isLoading ? Icons.hourglass_empty : Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

class _SuggestionsDialog extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSelected;

  const _SuggestionsDialog({
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Suggestions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: suggestions.map((suggestion) {
            return ListTile(
              title: Text(suggestion),
              onTap: () => onSelected(suggestion),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}