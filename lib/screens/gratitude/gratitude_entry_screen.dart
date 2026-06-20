import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/hive_service.dart';
import '../../utils/app_theme.dart';

class GratitudeEntryScreen extends StatefulWidget {
  final GratitudeEntry? existing;
  const GratitudeEntryScreen({super.key, this.existing});
  @override
  State<GratitudeEntryScreen> createState() => _GratitudeEntryScreenState();
}

class _GratitudeEntryScreenState extends State<GratitudeEntryScreen> {
  final _g1 = TextEditingController();
  final _g2 = TextEditingController();
  final _g3 = TextEditingController();
  final _free = TextEditingController();
  String? _mood;
  bool _saving = false;

  static const List<Map<String, dynamic>> _moods = [
    {'key': 'peaceful', 'label': 'Peaceful',  'icon': Icons.spa_rounded,      'color': Color(0xFF80CBC4)},
    {'key': 'happy',    'label': 'Happy',      'icon': Icons.wb_sunny_rounded, 'color': Color(0xFFFFD54F)},
    {'key': 'grateful', 'label': 'Grateful',   'icon': Icons.favorite_rounded, 'color': Color(0xFFFF8FA3)},
    {'key': 'tired',    'label': 'Tired',      'icon': Icons.nightlight_round, 'color': Color(0xFF90A4AE)},
    {'key': 'anxious',  'label': 'Anxious',    'icon': Icons.air_rounded,      'color': Color(0xFFB39DDB)},
  ];

  static const List<String> _prompts = [
    'Something that made you smile today...',
    'A person who made a difference...',
    'Something about yourself you appreciate...',
    'A small moment of beauty you noticed...',
    'Something you usually take for granted...',
    'A challenge that helped you grow...',
    'Something kind someone did for you...',
    'A simple pleasure you enjoyed today...',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      if (e.gratitudes.isNotEmpty) _g1.text = e.gratitudes[0];
      if (e.gratitudes.length > 1) _g2.text = e.gratitudes[1];
      if (e.gratitudes.length > 2) _g3.text = e.gratitudes[2];
      _free.text = e.freeWrite ?? '';
      _mood = e.moodTag;
    }
  }

  @override
  void dispose() {
    _g1.dispose(); _g2.dispose(); _g3.dispose(); _free.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final gratitudes = [_g1.text.trim(), _g2.text.trim(), _g3.text.trim()]
        .where((g) => g.isNotEmpty).toList();
    if (gratitudes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write at least one thing you are grateful for'),
          backgroundColor: AppTheme.primaryDark));
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final entry = GratitudeEntry(
      id: widget.existing?.id ?? now.millisecondsSinceEpoch.toString(),
      date: widget.existing?.date ?? now,
      gratitudes: gratitudes,
      freeWrite: _free.text.trim().isEmpty ? null : _free.text.trim(),
      moodTag: _mood,
      aiReflection: null, // reset on edit
    );
    await HiveService.saveGratitude(entry);
    if (mounted) { setState(() => _saving = false); Navigator.pop(context, true); }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final now = DateTime.now();
    // Rotate through prompts by day
    final dayIdx = now.day % _prompts.length;
    final prompt1 = _prompts[dayIdx];
    final prompt2 = _prompts[(dayIdx + 1) % _prompts.length];
    final prompt3 = _prompts[(dayIdx + 2) % _prompts.length];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Entry' : 'Today\'s Gratitude'),
        backgroundColor: AppTheme.surface,
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryDark)))
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w700, color: AppTheme.primaryDark, fontSize: 15)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.pinkGradient),
              borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(DateFormat('EEEE, MMMM d, yyyy').format(now),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                  fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 24),

          // Gratitude section
          const Text('What are you grateful for today?',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 17,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Write 3 things, big or small. They all matter.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),

          _GratitudeField(number: 1, controller: _g1, hint: prompt1),
          const SizedBox(height: 12),
          _GratitudeField(number: 2, controller: _g2, hint: prompt2),
          const SizedBox(height: 12),
          _GratitudeField(number: 3, controller: _g3, hint: prompt3),
          const SizedBox(height: 24),

          // Mood
          const Text('How are you feeling?',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _moods.map((m) {
              final selected = _mood == m['key'];
              return GestureDetector(
                onTap: () => setState(() => _mood = selected ? null : m['key'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? (m['color'] as Color).withOpacity(0.15)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? m['color'] as Color : AppTheme.divider,
                      width: selected ? 2 : 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(m['icon'] as IconData,
                      size: 18, color: selected ? m['color'] as Color : AppTheme.textHint),
                    const SizedBox(width: 6),
                    Text(m['label'] as String,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? m['color'] as Color : AppTheme.textSecondary)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Free write
          const Text('Anything else on your mind?',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Optional — let it all out.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: _free,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Write freely here — no rules, no judgment...',
              alignLabelWithHint: true),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : isEdit ? 'Update Entry' : 'Save Entry'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _GratitudeField extends StatelessWidget {
  final int number;
  final TextEditingController controller;
  final String hint;
  const _GratitudeField({required this.number, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        margin: const EdgeInsets.only(right: 12, top: 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: AppColors.pinkGradient),
          shape: BoxShape.circle),
        child: Center(child: Text('$number',
          style: const TextStyle(fontFamily: 'Poppins',
            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
      ),
      Expanded(child: TextField(
        controller: controller,
        maxLines: 2,
        decoration: InputDecoration(hintText: hint),
        textCapitalization: TextCapitalization.sentences,
      )),
    ]);
  }
}
