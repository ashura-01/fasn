import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/hive_service.dart';
import '../../utils/app_theme.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late FocusNode _contentFocus;
  String? _selectedColorHex;
  bool _isBold = false;
  Color _textColor = AppTheme.textPrimary;
  bool _changed = false;

  static const List<Map<String, dynamic>> _colorPalette = [
    {'name': 'Default', 'hex': 'FF1A1A2E'},
    {'name': 'Rose', 'hex': 'FFFF4081'},
    {'name': 'Purple', 'hex': 'FF9C27B0'},
    {'name': 'Blue', 'hex': 'FF1976D2'},
    {'name': 'Teal', 'hex': 'FF009688'},
    {'name': 'Green', 'hex': 'FF388E3C'},
    {'name': 'Orange', 'hex': 'FFFF6F00'},
  ];

  static const List<Map<String, dynamic>> _noteBgColors = [
    {'label': 'White', 'hex': 'FFFFFFFF'},
    {'label': 'Pink', 'hex': 'FFFFF0F3'},
    {'label': 'Rose', 'hex': 'FFFFE0E6'},
    {'label': 'Yellow', 'hex': 'FFFFF8E1'},
    {'label': 'Mint', 'hex': 'FFE8F5E9'},
    {'label': 'Sky', 'hex': 'FFE3F2FD'},
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.note?.content ?? '');
    _selectedColorHex = widget.note?.colorHex;
    _contentFocus = FocusNode();
    _titleCtrl.addListener(() => _changed = true);
    _contentCtrl.addListener(() => _changed = true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_changed) await _save();
    return true;
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty && _contentCtrl.text.trim().isEmpty) {
      if (widget.note != null) HiveService.deleteNote(widget.note!.id);
      return;
    }
    final now = DateTime.now();
    final note = NoteModel(
      id: widget.note?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      colorHex: _selectedColorHex,
      isPinned: widget.note?.isPinned ?? false,
    );
    await HiveService.saveNote(note);
  }

  Color get _bgColor {
    if (_selectedColorHex == null) return AppTheme.surface;
    try {
      return Color(int.parse(_selectedColorHex!));
    } catch (_) {
      return AppTheme.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _onWillPop();
          if (context.mounted) Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              await _onWillPop();
              if (context.mounted) Navigator.pop(context, true);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: widget.note == null ? null : _deleteNote,
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: () async {
                await _save();
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textHint,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const Divider(color: AppTheme.divider, height: 20),
                    // Content
                    TextField(
                      controller: _contentCtrl,
                      focusNode: _contentFocus,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: _isBold ? FontWeight.w700 : FontWeight.w400,
                        color: _textColor,
                        height: 1.7,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Start writing...',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          color: AppTheme.textHint,
                          height: 1.7,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
            // Formatting toolbar
            _buildToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          top: BorderSide(color: AppTheme.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Bold
            _ToolbarButton(
              icon: Icons.format_bold_rounded,
              isActive: _isBold,
              onTap: () => setState(() => _isBold = !_isBold),
              tooltip: 'Bold',
            ),
            const SizedBox(width: 4),
            // Text color picker
            ..._colorPalette.map((c) {
              final color = Color(int.parse(c['hex']));
              final isSelected = _textColor.value == color.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => setState(() => _textColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color == AppTheme.textPrimary
                          ? const Color(0xFF1A1A2E)
                          : color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryDark
                            : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 6,
                              )
                            ]
                          : [],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            const VerticalDivider(width: 1, color: AppTheme.divider),
            const SizedBox(width: 8),
            // Note bg colors
            ..._noteBgColors.map((c) {
              final isSelected = _selectedColorHex == c['hex'];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedColorHex = c['hex']);
                    _changed = true;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Color(int.parse(c['hex'])),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryDark
                            : AppTheme.divider,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: AppTheme.primaryDark)
                        : null,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _deleteNote() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('This note will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
            onPressed: () {
              HiveService.deleteNote(widget.note!.id);
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _ToolbarButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryLight.withOpacity(0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: AppTheme.primaryDark, width: 1.5)
                : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? AppTheme.primaryDark : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
