import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/hive_service.dart';
import '../../services/ai_service.dart';
import '../../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = false;
  bool _configMissing = false;

  @override
  void initState() {
    super.initState();
    _messages = HiveService.getAllChat();
    final s = HiveService.getAppSettings();
    _configMissing = (s.aiApiKey?.isEmpty ?? true) || (s.aiBaseUrl?.isEmpty ?? true);
    if (_messages.isEmpty && !_configMissing) _sendWelcome();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendWelcome() async {
    final s = HiveService.getAppSettings();
    final name = s.userName?.isNotEmpty == true ? s.userName!.split(' ').first : 'there';
    final profession = s.userProfession?.isNotEmpty == true ? ' As a ${s.userProfession},' : '';
    final welcomeText =
        'Hello, $name! I\'m Lumina, your personal wellness companion.$profession I\'m here to listen, support, and help you see the light even on the darkest days. '
        'How are you feeling right now? You can tell me anything — I\'m all yours.';
    final welcome = ChatMessage(
      id: const Uuid().v4(), content: welcomeText,
      isUser: false, timestamp: DateTime.now());
    await HiveService.saveChat(welcome);
    if (mounted) setState(() => _messages = HiveService.getAllChat());
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();

    final userMsg = ChatMessage(
      id: const Uuid().v4(), content: text,
      isUser: true, timestamp: DateTime.now());
    await HiveService.saveChat(userMsg);
    setState(() { _messages = HiveService.getAllChat(); _loading = true; });
    _scrollToBottom();

    try {
      final response = await AiService.chat(userMessage: text, history: _messages);
      final aiMsg = ChatMessage(
        id: const Uuid().v4(), content: response,
        isUser: false, timestamp: DateTime.now());
      await HiveService.saveChat(aiMsg);
      if (mounted) setState(() { _messages = HiveService.getAllChat(); _loading = false; });
      _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut);
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text('This will delete all your chat history with Lumina. Start fresh?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await HiveService.clearChat();
              if (mounted) {
                setState(() => _messages = []);
                Navigator.pop(ctx);
                _sendWelcome();
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: AppColors.pinkGradient),
              shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Lumina', style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            Text('AI Wellness Companion', style: TextStyle(fontFamily: 'Poppins',
              fontSize: 10, color: AppTheme.textSecondary)),
          ]),
        ]),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.textHint),
              onPressed: _clearChat,
              tooltip: 'Clear chat',
            ),
        ],
      ),
      body: Column(children: [
        if (_configMissing) _buildConfigBanner(),
        Expanded(
          child: _messages.isEmpty && !_loading
            ? _buildEmptyState()
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == _messages.length) return const _TypingIndicator();
                  return _ChatBubble(message: _messages[i]);
                },
              ),
        ),
        _buildInputBar(),
      ]),
    );
  }

  Widget _buildConfigBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF8F00), size: 20),
        const SizedBox(width: 10),
        const Expanded(child: Text(
          'Set up your AI in Settings to enable Lumina.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF795548)))),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Settings', style: TextStyle(fontFamily: 'Poppins',
            fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.pinkGradient),
            shape: BoxShape.circle),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text('Meet Lumina', style: TextStyle(fontFamily: 'Poppins',
          fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        const Text('Your personal AI wellness companion. Share your thoughts, feelings, or anything on your mind. Lumina is here to listen, reflect, and uplift you.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
            color: AppTheme.textSecondary, height: 1.6),
          textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16,
        MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.divider)),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.06),
          blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            maxLines: 4,
            minLines: 1,
            onSubmitted: (_) => _send(),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Talk to Lumina...',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _loading ? null : _send,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _loading
                    ? [AppTheme.textHint, AppTheme.textHint]
                    : AppColors.pinkGradient),
              shape: BoxShape.circle,
              boxShadow: _loading ? [] : [BoxShadow(
                color: AppTheme.primaryDark.withOpacity(0.3),
                blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: _loading
              ? const Padding(padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.pinkGradient),
                shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(colors: AppColors.pinkGradient)
                    : null,
                color: isUser ? null : AppTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: AppTheme.divider),
                boxShadow: [BoxShadow(
                  color: (isUser ? AppTheme.primaryDark : Colors.black).withOpacity(0.06),
                  blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(message.content,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                    color: isUser ? Colors.white : AppTheme.textPrimary, height: 1.5)),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
                    color: isUser ? Colors.white70 : AppTheme.textHint)),
              ]),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $s';
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.pinkGradient),
            shape: BoxShape.circle),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
            border: Border.all(color: AppTheme.divider)),
          child: FadeTransition(
            opacity: _anim,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _Dot(delay: 0, ctrl: _ctrl),
              const SizedBox(width: 4),
              _Dot(delay: 0.3, ctrl: _ctrl),
              const SizedBox(width: 4),
              _Dot(delay: 0.6, ctrl: _ctrl),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final double delay;
  final AnimationController ctrl;
  const _Dot({required this.delay, required this.ctrl});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: AppTheme.primaryDark.withOpacity(0.3 + 0.7 * ctrl.value),
          shape: BoxShape.circle),
      ),
    );
  }
}
