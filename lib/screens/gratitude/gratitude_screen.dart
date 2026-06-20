import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/hive_service.dart';
import '../../services/ai_service.dart';
import '../../utils/app_theme.dart';
import 'gratitude_entry_screen.dart';
import 'chat_screen.dart';

class GratitudeScreen extends StatefulWidget {
  const GratitudeScreen({super.key});
  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String? _dailyAffirmation;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _pickDailyAffirmation();
    HiveService.seedAffirmationsIfEmpty().then((_) {
      if (mounted) setState(() => _pickDailyAffirmation());
    });
  }

  void _pickDailyAffirmation() {
    final all = HiveService.getAllAffirmations();
    if (all.isEmpty) return;
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    _dailyAffirmation = all[dayOfYear % all.length].text;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = HiveService.getGratitudeStreak();
    final todayEntry = HiveService.getGratitudeForDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverToBoxAdapter(child: _buildHeader(streak, todayEntry)),
          if (_dailyAffirmation != null)
            SliverToBoxAdapter(child: _buildAffirmationCard()),
          SliverToBoxAdapter(child: _buildTabBar()),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _JournalTab(onRefresh: () => setState(() {})),
            _AffirmationsTab(onRefresh: () => setState(() => _pickDailyAffirmation())),
            const _InsightsTab(),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(todayEntry),
    );
  }

  Widget _buildHeader(int streak, GratitudeEntry? todayEntry) {
    final settings = HiveService.getAppSettings();
    final firstName = (settings.userName?.isNotEmpty == true)
        ? ', ${settings.userName!.split(' ').first}'
        : '';
    final total = HiveService.getAllGratitude().length;
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF0F3), Color(0xFFFFE4EC)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$greeting$firstName',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            const Text('Gratitude Garden',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 26,
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ])),
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.pinkGradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppTheme.primaryDark.withOpacity(0.25),
                  blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Lumina', style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _StatPill(icon: Icons.local_fire_department_rounded,
            value: '$streak', label: 'day streak', color: const Color(0xFFFF6B6B)),
          const SizedBox(width: 10),
          _StatPill(icon: Icons.menu_book_rounded,
            value: '$total', label: 'entries', color: AppTheme.primaryDark),
          const SizedBox(width: 10),
          _StatPill(
            icon: todayEntry != null
                ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            value: todayEntry != null ? 'Done' : 'Pending',
            label: 'today',
            color: todayEntry != null ? const Color(0xFF4CAF50) : AppTheme.textHint,
          ),
        ]),
      ]),
    );
  }

  Widget _buildAffirmationCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8FA3), Color(0xFFFFB6C1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppTheme.primaryDark.withOpacity(0.18),
          blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.format_quote_rounded, color: Colors.white70, size: 20),
          const SizedBox(width: 6),
          const Text('Affirmation of the Day',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
              fontWeight: FontWeight.w600, color: Colors.white70)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              final all = HiveService.getAllAffirmations();
              if (all.isNotEmpty) {
                setState(() => _dailyAffirmation = all[Random().nextInt(all.length)].text);
              }
            },
            child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
          ),
        ]),
        const SizedBox(height: 10),
        Text(_dailyAffirmation!,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16,
            fontWeight: FontWeight.w600, color: Colors.white, height: 1.5)),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.1),
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TabBar(
        controller: _tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.pinkGradient),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
        tabs: const [Tab(text: 'Journal'), Tab(text: 'Affirmations'), Tab(text: 'Insights')],
      ),
    );
  }

  Widget _buildFAB(GratitudeEntry? todayEntry) {
    return FloatingActionButton.extended(
      onPressed: () async {
        final r = await Navigator.push(context,
          MaterialPageRoute(builder: (_) => GratitudeEntryScreen(existing: todayEntry)));
        if (r == true && mounted) setState(() {});
      },
      backgroundColor: AppTheme.primaryDark,
      icon: Icon(todayEntry != null ? Icons.edit_rounded : Icons.add_rounded, color: Colors.white),
      label: Text(todayEntry != null ? 'Edit Today' : 'Write Today',
        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

// ── Journal Tab ────────────────────────────────────────────────
class _JournalTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _JournalTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final entries = HiveService.getAllGratitude();
    if (entries.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_stories_rounded, size: 64, color: AppTheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Your gratitude journey begins here',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
              fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Write your first entry — even one small thing you are grateful for can shift your entire day.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
              color: AppTheme.textSecondary, height: 1.6),
            textAlign: TextAlign.center),
        ]),
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: entries.length,
      itemBuilder: (ctx, i) => _JournalCard(
        entry: entries[i],
        onTap: () async {
          final r = await Navigator.push(ctx,
            MaterialPageRoute(builder: (_) => GratitudeEntryScreen(existing: entries[i])));
          if (r == true) onRefresh();
        },
        onDelete: () async {
          await HiveService.deleteGratitude(entries[i].id);
          onRefresh();
        },
      ),
    );
  }
}

class _JournalCard extends StatefulWidget {
  final GratitudeEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _JournalCard({required this.entry, required this.onTap, required this.onDelete});
  @override
  State<_JournalCard> createState() => _JournalCardState();
}

class _JournalCardState extends State<_JournalCard> {
  bool _expanded = false;
  bool _loadingAI = false;

  static const Map<String, Map<String, dynamic>> _moodMeta = {
    'peaceful': {'icon': Icons.spa_rounded,      'color': Color(0xFF80CBC4)},
    'happy':    {'icon': Icons.wb_sunny_rounded, 'color': Color(0xFFFFD54F)},
    'anxious':  {'icon': Icons.air_rounded,      'color': Color(0xFFB39DDB)},
    'tired':    {'icon': Icons.nightlight_round, 'color': Color(0xFF90A4AE)},
    'grateful': {'icon': Icons.favorite_rounded, 'color': Color(0xFFFF8FA3)},
  };

  Future<void> _aiReflect() async {
    if (widget.entry.aiReflection != null) {
      setState(() => _expanded = !_expanded);
      return;
    }
    setState(() => _loadingAI = true);
    try {
      final r = await AiService.generateReflection(widget.entry);
      widget.entry.aiReflection = r;
      await HiveService.saveGratitude(widget.entry);
      if (mounted) setState(() { _loadingAI = false; _expanded = true; });
    } catch (_) {
      if (mounted) setState(() => _loadingAI = false);
    }
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final mood = widget.entry.moodTag;
    final meta = mood != null ? _moodMeta[mood] : null;
    final isToday = _isToday(widget.entry.date);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isToday ? AppTheme.primaryDark.withOpacity(0.4) : AppTheme.divider,
            width: isToday ? 1.8 : 1),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.07),
            blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.primaryDark,
                        borderRadius: BorderRadius.circular(8)),
                      child: const Text('Today', style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  Text(DateFormat('EEE, MMM d').format(widget.entry.date),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                      fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ]),
                if (mood != null && meta != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(children: [
                      Icon(meta['icon'] as IconData, size: 13, color: meta['color'] as Color),
                      const SizedBox(width: 4),
                      Text(mood[0].toUpperCase() + mood.substring(1),
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                          color: meta['color'] as Color, fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ])),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.textHint),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (v) {
                  if (v == 'delete') widget.onDelete();
                  if (v == 'ai') _aiReflect();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'ai', child: Row(children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.primaryDark),
                    SizedBox(width: 8),
                    Text('AI Reflection', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                  ])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [
                    Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.red)),
                  ])),
                ],
              ),
            ]),
          ),
          // Gratitude items
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.entry.gratitudes.asMap().entries.map((e) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 22, height: 22,
                      margin: const EdgeInsets.only(right: 10, top: 1),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.pinkGradient),
                        shape: BoxShape.circle),
                      child: Center(child: Text('${e.key + 1}',
                        style: const TextStyle(fontFamily: 'Poppins',
                          fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
                    ),
                    Expanded(child: Text(e.value,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                        color: AppTheme.textPrimary, height: 1.5))),
                  ]),
                ),
              ).toList(),
            ),
          ),
          if (widget.entry.freeWrite?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(widget.entry.freeWrite!,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  color: AppTheme.textSecondary, fontStyle: FontStyle.italic, height: 1.5),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          // AI reflection
          if (_loadingAI)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _AILoadingIndicator()),
          if (_expanded && widget.entry.aiReflection != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _AIReflectionBox(
                text: widget.entry.aiReflection!,
                onClose: () => setState(() => _expanded = false))),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(children: [
              const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(DateFormat('h:mm a').format(widget.entry.date),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppTheme.textHint)),
              const Spacer(),
              if (!_expanded && !_loadingAI)
                GestureDetector(
                  onTap: _aiReflect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.auto_awesome_rounded, size: 12, color: AppTheme.primaryDark),
                      SizedBox(width: 4),
                      Text('AI Reflect', style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
                    ]),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Affirmations Tab ───────────────────────────────────────────
class _AffirmationsTab extends StatefulWidget {
  final VoidCallback onRefresh;
  const _AffirmationsTab({required this.onRefresh});
  @override
  State<_AffirmationsTab> createState() => _AffirmationsTabState();
}

class _AffirmationsTabState extends State<_AffirmationsTab> {
  @override
  Widget build(BuildContext context) {
    final list = HiveService.getAllAffirmations();
    return Stack(children: [
      list.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.format_quote_rounded, size: 56, color: AppTheme.primary.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text('Add your first affirmation',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: AppTheme.textSecondary)),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: list.length,
            itemBuilder: (ctx, i) => _AffirmationCard(
              affirmation: list[i],
              onDelete: () async {
                await HiveService.deleteAffirmation(list[i].id);
                widget.onRefresh();
                setState(() {});
              },
              onFav: () async {
                list[i].isFavorite = !list[i].isFavorite;
                await HiveService.saveAffirmation(list[i]);
                setState(() {});
              },
            ),
          ),
      Positioned(
        bottom: 16, right: 16,
        child: FloatingActionButton.small(
          heroTag: 'add_affirmation',
          onPressed: () => _showAddAffirmationDialog(context),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    ]);
  }

  void _showAddAffirmationDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Affirmation'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'I am strong, capable, and worthy...',
            labelText: 'Your affirmation',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final a = Affirmation(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                text: ctrl.text.trim(),
                order: HiveService.getAllAffirmations().length,
              );
              await HiveService.saveAffirmation(a);
              widget.onRefresh();
              if (mounted) setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _AffirmationCard extends StatelessWidget {
  final Affirmation affirmation;
  final VoidCallback onDelete;
  final VoidCallback onFav;
  const _AffirmationCard({required this.affirmation, required this.onDelete, required this.onFav});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: affirmation.isFavorite
            ? AppTheme.primaryLight.withOpacity(0.25) : AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: affirmation.isFavorite
              ? AppTheme.primaryDark.withOpacity(0.35) : AppTheme.divider,
          width: affirmation.isFavorite ? 1.5 : 1),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.format_quote_rounded, color: AppTheme.primaryDark, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(affirmation.text,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
            color: AppTheme.textPrimary, height: 1.55))),
        Column(children: [
          GestureDetector(onTap: onFav,
            child: Icon(
              affirmation.isFavorite
                  ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              size: 20,
              color: affirmation.isFavorite ? AppTheme.primaryDark : AppTheme.textHint)),
          const SizedBox(height: 8),
          GestureDetector(onTap: onDelete,
            child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textHint)),
        ]),
      ]),
    );
  }
}

// ── Insights Tab ───────────────────────────────────────────────
class _InsightsTab extends StatelessWidget {
  const _InsightsTab();

  @override
  Widget build(BuildContext context) {
    final entries = HiveService.getAllGratitude();
    if (entries.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.insights_rounded, size: 56, color: AppTheme.primary.withOpacity(0.5)),
        const SizedBox(height: 12),
        const Text('Insights appear after\nyour first entry',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: AppTheme.textSecondary),
          textAlign: TextAlign.center),
      ]));
    }

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 89));
    final entryDays = entries.map((e) =>
      '${e.date.year}-${e.date.month}-${e.date.day}').toSet();

    final moodCounts = <String, int>{};
    for (final e in entries) {
      if (e.moodTag != null) moodCounts[e.moodTag!] = (moodCounts[e.moodTag!] ?? 0) + 1;
    }

    const stopwords = {'i','am','the','a','for','my','and','of','to','in','is','it',
      'that','was','with','have','be','at','an','this','me','so','very','just','so'};
    final wordFreq = <String, int>{};
    for (final e in entries) {
      for (final g in e.gratitudes) {
        for (final w in g.toLowerCase().split(RegExp(r'\W+'))) {
          if (w.length > 3 && !stopwords.contains(w)) {
            wordFreq[w] = (wordFreq[w] ?? 0) + 1;
          }
        }
      }
    }
    final topWords = (wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))).take(15).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _SectionHeader(title: 'Consistency', subtitle: '${HiveService.getGratitudeStreak()} day streak'),
        const SizedBox(height: 10),
        _HeatmapGrid(startDate: startDate, endDate: now, entryDays: entryDays),
        const SizedBox(height: 20),
        if (moodCounts.isNotEmpty) ...[
          _SectionHeader(title: 'Mood Patterns',
            subtitle: '${entries.where((e) => e.moodTag != null).length} moods logged'),
          const SizedBox(height: 10),
          _MoodDistribution(moodCounts: moodCounts),
          const SizedBox(height: 20),
        ],
        if (topWords.isNotEmpty) ...[
          _SectionHeader(title: 'What You Value Most', subtitle: 'from all your entries'),
          const SizedBox(height: 10),
          _WordCloud(words: topWords),
          const SizedBox(height: 20),
        ],
        _SummaryCard(entries: entries),
      ],
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatPill({required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
            fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
            color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}

class _AILoadingIndicator extends StatelessWidget {
  const _AILoadingIndicator();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14)),
      child: const Row(children: [
        SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryDark)),
        SizedBox(width: 10),
        Text('Lumina is reflecting...',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
            color: AppTheme.primaryDark, fontStyle: FontStyle.italic)),
      ]),
    );
  }
}

class _AIReflectionBox extends StatelessWidget {
  final String text;
  final VoidCallback onClose;
  const _AIReflectionBox({required this.text, required this.onClose});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F3), Color(0xFFFFE4EC)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.primaryDark),
          const SizedBox(width: 6),
          const Text('Lumina says', style: TextStyle(fontFamily: 'Poppins',
            fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
          const Spacer(),
          GestureDetector(onTap: onClose,
            child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textHint)),
        ]),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
          color: AppTheme.textPrimary, height: 1.6)),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16,
      fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
    Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
      color: AppTheme.textSecondary)),
  ]);
}

class _HeatmapGrid extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Set<String> entryDays;
  const _HeatmapGrid({required this.startDate, required this.endDate, required this.entryDays});
  @override
  Widget build(BuildContext context) {
    final days = endDate.difference(startDate).inDays + 1;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 4, runSpacing: 4, children: List.generate(days, (i) {
          final d = startDate.add(Duration(days: i));
          final key = '${d.year}-${d.month}-${d.day}';
          final has = entryDays.contains(key);
          final isToday = key == '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
          return Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              color: has ? AppTheme.primaryDark : AppTheme.divider.withOpacity(0.5),
              borderRadius: BorderRadius.circular(3),
              border: isToday ? Border.all(color: AppTheme.primaryDark, width: 1.5) : null),
          );
        })),
        const SizedBox(height: 10),
        Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(
            color: AppTheme.divider.withOpacity(0.5), borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          const Text('No entry', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppTheme.textHint)),
          const SizedBox(width: 14),
          Container(width: 12, height: 12, decoration: BoxDecoration(
            color: AppTheme.primaryDark, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          const Text('Written', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppTheme.textHint)),
        ]),
      ]),
    );
  }
}

class _MoodDistribution extends StatelessWidget {
  final Map<String, int> moodCounts;
  const _MoodDistribution({required this.moodCounts});
  static const Map<String, Map<String, dynamic>> _meta = {
    'peaceful': {'icon': Icons.spa_rounded,      'color': Color(0xFF80CBC4), 'label': 'Peaceful'},
    'happy':    {'icon': Icons.wb_sunny_rounded, 'color': Color(0xFFFFD54F), 'label': 'Happy'},
    'anxious':  {'icon': Icons.air_rounded,      'color': Color(0xFFB39DDB), 'label': 'Anxious'},
    'tired':    {'icon': Icons.nightlight_round, 'color': Color(0xFF90A4AE), 'label': 'Tired'},
    'grateful': {'icon': Icons.favorite_rounded, 'color': Color(0xFFFF8FA3), 'label': 'Grateful'},
  };
  @override
  Widget build(BuildContext context) {
    final total = moodCounts.values.fold(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.divider)),
      child: Column(
        children: moodCounts.entries.map((e) {
          final m = _meta[e.key]; if (m == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Icon(m['icon'] as IconData, size: 18, color: m['color'] as Color),
              const SizedBox(width: 10),
              SizedBox(width: 70, child: Text(m['label'] as String,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppTheme.textPrimary))),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: e.value / total,
                  backgroundColor: AppTheme.divider, color: m['color'] as Color, minHeight: 8))),
              const SizedBox(width: 8),
              Text('${e.value}', style: const TextStyle(fontFamily: 'Poppins',
                fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

class _WordCloud extends StatelessWidget {
  final List<MapEntry<String, int>> words;
  const _WordCloud({required this.words});
  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const SizedBox.shrink();
    final maxCount = words.first.value.toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.divider)),
      child: Wrap(spacing: 8, runSpacing: 8, children: words.map((e) {
        final size = 11.0 + (e.value / maxCount) * 10;
        final opacity = 0.5 + (e.value / maxCount) * 0.5;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(opacity * 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryDark.withOpacity(opacity * 0.5))),
          child: Text(e.key, style: TextStyle(fontFamily: 'Poppins', fontSize: size,
            fontWeight: e.value > (maxCount * 0.6) ? FontWeight.w700 : FontWeight.w500,
            color: AppTheme.primaryDark.withOpacity(opacity))),
        );
      }).toList()),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<GratitudeEntry> entries;
  const _SummaryCard({required this.entries});
  @override
  Widget build(BuildContext context) {
    final thisMonth = entries.where((e) =>
      e.date.month == DateTime.now().month && e.date.year == DateTime.now().year).length;
    final streak = HiveService.getGratitudeStreak();
    final message = streak >= 30
      ? 'You are extraordinary. 30+ days of gratitude — you have built something truly beautiful.'
      : streak >= 14
      ? 'Two weeks of showing up for yourself. That commitment is rare and powerful.'
      : streak >= 7
      ? 'A whole week of gratitude! You are building a habit that will change how you see the world.'
      : entries.isNotEmpty
      ? 'Every entry you write is a gift to your future self. Keep going — you are doing something wonderful.'
      : 'Your journey starts today. One entry, one small step — that is all it takes.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF0F3), Color(0xFFFFD6DC)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.primaryDark),
          SizedBox(width: 8),
          Text('Your Journey', style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
            fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ]),
        const SizedBox(height: 10),
        Text(message, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
          color: AppTheme.textPrimary, height: 1.6)),
        const SizedBox(height: 8),
        Text('$thisMonth entries this month · $streak day streak',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppTheme.textSecondary)),
      ]),
    );
  }
}
