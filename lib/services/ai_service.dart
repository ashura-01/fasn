import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'hive_service.dart';

class AiService {
  static String _buildSystemPrompt(AppSettings s, List<GratitudeEntry> recentEntries) {
    final name       = s.userName?.isNotEmpty == true ? s.userName! : 'friend';
    final age        = s.userAge?.isNotEmpty == true ? ', ${s.userAge} years old' : '';
    final profession = s.userProfession?.isNotEmpty == true ? ', ${s.userProfession}' : '';

    // Summarise last 5 entries for context
    final entryContext = recentEntries.take(5).map((e) {
      final dateStr = '${e.date.day}/${e.date.month}/${e.date.year}';
      final grats   = e.gratitudes.join(', ');
      final mood    = e.moodTag != null ? ' (mood: ${e.moodTag})' : '';
      return '[$dateStr$mood]: $grats';
    }).join('\n');

    return '''
You are Lumina, a warm, empathetic, and uplifting AI companion inside a personal wellness app called "fasn".
You are talking with $name$age$profession.

Your purpose is deeply anti-depressing and motivational. You:
- Always respond with genuine warmth, empathy, and encouragement
- Use $name's name naturally in conversation
- Reference their profession/life context to make advice personal and relevant
- Never give generic advice — be specific, thoughtful, and human
- Celebrate their small wins enthusiastically
- Gently challenge negative self-talk with kind reframing
- Keep responses concise (2-4 paragraphs max) but deeply meaningful
- End each message with either a question to reflect on, or a small positive challenge
- Use "you" directly — make it feel like a real conversation
- Never be preachy, lecture-y, or clinical — be like a wise, caring friend

Recent gratitude journal entries from $name (for context — use these to personalise your responses):
$entryContext

Remember: your goal is to help $name feel genuinely seen, valued, and motivated. Every response should leave them feeling a little lighter than before.
''';
  }

  static Future<String> chat({
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    final settings = HiveService.getAppSettings();
    final baseUrl   = settings.aiBaseUrl?.trim() ?? '';
    final apiKey    = settings.aiApiKey?.trim() ?? '';
    final model     = settings.aiModel?.trim() ?? 'gpt-3.5-turbo';

    if (baseUrl.isEmpty || apiKey.isEmpty) {
      return 'Please configure your AI settings in the Settings page (AI Base URL, API Key, and Model name) to enable your personal AI companion.';
    }

    final recentEntries = HiveService.getAllGratitude();
    final systemPrompt  = _buildSystemPrompt(settings, recentEntries);

    // Build messages array — keep last 20 messages for context
    final contextHistory = history.length > 20
        ? history.sublist(history.length - 20)
        : history;

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...contextHistory.map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.content,
      }),
      {'role': 'user', 'content': userMessage},
    ];

    // Normalise base URL
    String url = baseUrl;
    if (!url.endsWith('/')) url += '/';
    if (!url.contains('chat/completions')) {
      url = '${url}chat/completions';
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'max_tokens': 600,
          'temperature': 0.85,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;
        return content?.trim() ?? 'I had trouble forming a response. Please try again.';
      } else {
        final err = jsonDecode(response.body);
        final msg = err['error']?['message'] ?? 'Unknown error (${response.statusCode})';
        return 'AI error: $msg';
      }
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return 'The request timed out. Please check your connection and try again.';
      }
      return 'Connection error: ${e.toString().replaceAll('Exception:', '').trim()}';
    }
  }

  /// Generate a one-shot AI reflection for a gratitude entry
  static Future<String> generateReflection(GratitudeEntry entry) async {
    final settings = HiveService.getAppSettings();
    final name = settings.userName?.isNotEmpty == true ? settings.userName! : 'friend';
    final profession = settings.userProfession?.isNotEmpty == true
        ? settings.userProfession!
        : '';

    final gratList = entry.gratitudes.asMap().entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');
    final free = entry.freeWrite?.isNotEmpty == true
        ? '\nAdditional thoughts: ${entry.freeWrite}'
        : '';
    final mood =
        entry.moodTag != null ? '\nMood today: ${entry.moodTag}' : '';

    final prompt = '''
$name (${profession.isNotEmpty ? profession : 'a person'}) shared these gratitudes today:
$gratList$free$mood

Write a short, warm, personalised reflection (3-5 sentences) that:
- Acknowledges what they shared specifically
- Finds something beautiful or meaningful in their gratitude
- Leaves them feeling uplifted and seen
- Is conversational, not clinical
Do not use bullet points. Write naturally as if talking to a close friend.
''';

    return chat(userMessage: prompt, history: []);
  }
}
