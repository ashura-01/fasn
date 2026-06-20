import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/hive_service.dart';
import '../../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  bool _showApiKey = false;

  // Profile controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _professionCtrl;

  // AI controllers
  late TextEditingController _baseUrlCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _modelCtrl;

  @override
  void initState() {
    super.initState();
    _settings = HiveService.getAppSettings();
    _nameCtrl       = TextEditingController(text: _settings.userName ?? '');
    _ageCtrl        = TextEditingController(text: _settings.userAge ?? '');
    _professionCtrl = TextEditingController(text: _settings.userProfession ?? '');
    _baseUrlCtrl    = TextEditingController(text: _settings.aiBaseUrl ?? '');
    _apiKeyCtrl     = TextEditingController(text: _settings.aiApiKey ?? '');
    _modelCtrl      = TextEditingController(text: _settings.aiModel ?? 'gpt-4o-mini');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _ageCtrl.dispose(); _professionCtrl.dispose();
    _baseUrlCtrl.dispose(); _apiKeyCtrl.dispose(); _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _settings.userName       = _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim();
    _settings.userAge        = _ageCtrl.text.trim().isEmpty ? null : _ageCtrl.text.trim();
    _settings.userProfession = _professionCtrl.text.trim().isEmpty ? null : _professionCtrl.text.trim();
    _settings.aiBaseUrl      = _baseUrlCtrl.text.trim().isEmpty ? null : _baseUrlCtrl.text.trim();
    _settings.aiApiKey       = _apiKeyCtrl.text.trim().isEmpty ? null : _apiKeyCtrl.text.trim();
    _settings.aiModel        = _modelCtrl.text.trim().isEmpty ? 'gpt-4o-mini' : _modelCtrl.text.trim();
    await HiveService.saveAppSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: AppTheme.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(children: [
            _buildProfileSection(),
            const SizedBox(height: 16),
            _buildAISection(),
            const SizedBox(height: 16),
            _buildAppearanceSection(),
            const SizedBox(height: 16),
            _buildDataSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
            const SizedBox(height: 24),
            _buildAbout(),
          ]),
        )),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 20),
      color: AppTheme.surface,
      child: const Text('Settings',
        style: TextStyle(fontFamily: 'Poppins', fontSize: 26,
          fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
    );
  }

  // ── Profile ──────────────────────────────────────────────────
  Widget _buildProfileSection() {
    return _Card(
      title: 'Your Profile',
      subtitle: 'Helps Lumina personalise your experience',
      icon: Icons.person_rounded,
      children: [
        _SettingsField(
          controller: _nameCtrl,
          label: 'Your name',
          hint: 'e.g. Sarah',
          icon: Icons.badge_rounded,
        ),
        const SizedBox(height: 12),
        _SettingsField(
          controller: _ageCtrl,
          label: 'Your age',
          hint: 'e.g. 22',
          icon: Icons.cake_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _SettingsField(
          controller: _professionCtrl,
          label: 'Your profession / role',
          hint: 'e.g. Medical student, Software engineer, Teacher...',
          icon: Icons.work_rounded,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.primaryDark),
            SizedBox(width: 8),
            Expanded(child: Text(
              'This info is stored locally and only shared with your AI when chatting.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                color: AppTheme.textSecondary, height: 1.4),
            )),
          ]),
        ),
      ],
    );
  }

  // ── AI Config ────────────────────────────────────────────────
  Widget _buildAISection() {
    return _Card(
      title: 'AI Configuration',
      subtitle: 'Connect any OpenAI-compatible API',
      icon: Icons.auto_awesome_rounded,
      children: [
        _SettingsField(
          controller: _baseUrlCtrl,
          label: 'API Base URL',
          hint: 'https://api.openai.com/v1',
          icon: Icons.link_rounded,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        // API Key with show/hide toggle
        TextField(
          controller: _apiKeyCtrl,
          obscureText: !_showApiKey,
          decoration: InputDecoration(
            labelText: 'API Key',
            hintText: 'sk-...',
            prefixIcon: const Icon(Icons.key_rounded,
              color: AppTheme.textSecondary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _showApiKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18, color: AppTheme.textHint,
              ),
              onPressed: () => setState(() => _showApiKey = !_showApiKey),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsField(
          controller: _modelCtrl,
          label: 'Model name',
          hint: 'gpt-4o-mini, claude-3-haiku, etc.',
          icon: Icons.psychology_rounded,
        ),
        const SizedBox(height: 12),
        // Quick preset buttons
        const Text('Quick presets',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
            fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _PresetChip(
            label: 'OpenAI',
            onTap: () => setState(() {
              _baseUrlCtrl.text = 'https://api.openai.com/v1';
              _modelCtrl.text = 'gpt-4o-mini';
            }),
          ),
          _PresetChip(
            label: 'Claude (Anthropic)',
            onTap: () => setState(() {
              _baseUrlCtrl.text = 'https://api.anthropic.com/v1';
              _modelCtrl.text = 'claude-3-haiku-20240307';
            }),
          ),
          _PresetChip(
            label: 'Groq',
            onTap: () => setState(() {
              _baseUrlCtrl.text = 'https://api.groq.com/openai/v1';
              _modelCtrl.text = 'llama3-8b-8192';
            }),
          ),
          _PresetChip(
            label: 'Local (Ollama)',
            onTap: () => setState(() {
              _baseUrlCtrl.text = 'http://localhost:11434/v1';
              _modelCtrl.text = 'llama3';
            }),
          ),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.5)),
          ),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFFF8F00)),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Your API key is stored locally on this device only. Use a key with limited permissions for safety.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                color: Color(0xFF795548), height: 1.4),
            )),
          ]),
        ),
      ],
    );
  }

  // ── Appearance ───────────────────────────────────────────────
  Widget _buildAppearanceSection() {
    return _Card(
      title: 'Appearance',
      subtitle: 'Make the app feel like yours',
      icon: Icons.palette_rounded,
      children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.4),
              borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.local_florist_rounded,
              color: AppTheme.primaryDark, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Floating flowers',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text('Decorative pink flowers in the background',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                color: AppTheme.textSecondary)),
          ])),
          Switch(
            value: _settings.showFloatingFlowers,
            onChanged: (v) async {
              setState(() => _settings.showFloatingFlowers = v);
              await HiveService.saveAppSettings(_settings);
            },
          ),
        ]),
      ],
    );
  }

  // ── Data ─────────────────────────────────────────────────────
  Widget _buildDataSection() {
    return _Card(
      title: 'Data & Privacy',
      subtitle: 'Everything is stored locally on your device',
      icon: Icons.shield_rounded,
      children: [
        _ActionRow(
          icon: Icons.delete_sweep_rounded,
          label: 'Clear chat history',
          color: AppTheme.textSecondary,
          onTap: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Clear Chat'),
              content: const Text('Delete all Lumina chat history?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    await HiveService.clearChat();
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat cleared'),
                        backgroundColor: AppTheme.primaryDark));
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.divider),
        _ActionRow(
          icon: Icons.delete_forever_rounded,
          label: 'Clear ALL app data',
          color: Colors.red.shade400,
          onTap: _confirmClearAll,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.save_rounded, color: Colors.white),
        label: const Text('Save Settings'),
      ),
    );
  }

  Widget _buildAbout() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F3), Color(0xFFFFD6DC)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primaryDark.withOpacity(0.12),
            shape: BoxShape.circle),
          child: const Icon(Icons.favorite_rounded, color: AppTheme.primaryDark, size: 30),
        ),
        const SizedBox(height: 12),
        const Text('fasn', style: TextStyle(fontFamily: 'Poppins',
          fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        const Text('Version 1.0.0', style: TextStyle(fontFamily: 'Poppins',
          fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        const Text('Made with love, for you',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.textSecondary)),
      ]),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This permanently deletes all routines, notes, gratitude entries, and chat history. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
            onPressed: () async {
              await HiveService.clearAll();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared'),
                  backgroundColor: AppTheme.primaryDark));
            },
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ───────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  const _Card({required this.title, required this.subtitle,
    required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppTheme.primaryDark, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15,
            fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
            color: AppTheme.textSecondary)),
        ])),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    ]);
  }
}

class _SettingsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  const _SettingsField({required this.controller, required this.label,
    required this.hint, required this.icon,
    this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryDark.withOpacity(0.3)),
        ),
        child: Text(label, style: const TextStyle(fontFamily: 'Poppins',
          fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontFamily: 'Poppins',
            fontSize: 14, fontWeight: FontWeight.w500, color: color))),
          Icon(Icons.chevron_right_rounded, size: 18, color: color.withOpacity(0.6)),
        ]),
      ),
    );
  }
}
