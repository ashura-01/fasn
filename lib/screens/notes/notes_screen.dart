import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/hive_service.dart';
import '../../utils/app_theme.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _search = '';

  List<NoteModel> get _filteredNotes {
    final notes = HiveService.getAllNotes();
    if (_search.isEmpty) return notes;
    return notes
        .where((n) =>
            n.title.toLowerCase().contains(_search.toLowerCase()) ||
            n.content.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  static const List<String> _noteColors = [
    'FFFFFFFF', 'FFFFF0F3', 'FFFFE0E6', 'FFFFF8E1', 'FFE8F5E9', 'FFE3F2FD',
  ];

  @override
  Widget build(BuildContext context) {
    final notes = _filteredNotes;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: notes.isEmpty
                ? _buildEmpty()
                : GridView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: notes.length,
                    itemBuilder: (context, i) => _NoteCard(
                      note: notes[i],
                      onTap: () => _openNote(notes[i]),
                      onDelete: () => _deleteNote(notes[i]),
                      onPin: () => _togglePin(notes[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 16),
      color: AppTheme.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Notes',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${HiveService.getAllNotes().length} notes',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.sticky_note_2_rounded,
                color: AppTheme.primaryDark, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: const InputDecoration(
          hintText: 'Search notes...',
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textHint),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sticky_note_2_outlined,
              size: 60, color: AppTheme.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            'No notes yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap + to create your first note',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }

  void _addNote() {
    _openNote(null);
  }

  void _openNote(NoteModel? note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note),
      ),
    );
    if (result == true) setState(() {});
  }

  void _deleteNote(NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade300),
            onPressed: () {
              Navigator.pop(ctx);
              HiveService.deleteNote(note.id);
              setState(() {});
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _togglePin(NoteModel note) {
    note.isPinned = !note.isPinned;
    HiveService.saveNote(note);
    setState(() {});
  }
}

// ── Note Card ──────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onPin,
  });

  Color get _bg {
    if (note.colorHex == null) return AppTheme.surface;
    try {
      return Color(int.parse(note.colorHex!));
    } catch (_) {
      return AppTheme.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Untitled' : note.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (note.isPinned)
                  const Icon(Icons.push_pin_rounded,
                      size: 16, color: AppTheme.primaryDark),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                note.content.isEmpty ? 'No content' : note.content,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                overflow: TextOverflow.fade,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(note.updatedAt),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: AppTheme.textHint,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onPin,
                  child: Icon(
                    note.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 16,
                    color: AppTheme.textHint,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: AppTheme.textHint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }
}
