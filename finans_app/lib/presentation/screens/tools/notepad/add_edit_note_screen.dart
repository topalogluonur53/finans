import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/providers/note_provider.dart';
import 'package:finans_app/data/models/note.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

const List<int> kNoteColors = [
  0xFF2D2D44, // Dark (default)
  0xFFFFCDD2, // Red
  0xFFF8BBD0, // Pink
  0xFFE1BEE7, // Purple
  0xFFD1C4E9, // Deep Purple
  0xFFC5CAE9, // Indigo
  0xFFBBDEFB, // Blue
  0xFFB3E5FC, // Light Blue
  0xFFB2EBF2, // Cyan
  0xFFB2DFDB, // Teal
  0xFFC8E6C9, // Green
  0xFFDCEDC8, // Light Green
  0xFFF0F4C3, // Lime
  0xFFFFF9C4, // Yellow
  0xFFFFECB3, // Amber
  0xFFFFE0B2, // Orange
  0xFFFFCCBC, // Deep Orange
];

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  int _selectedColor = kNoteColors[0];
  bool _isNewNote = true;
  bool _isPinned = false;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _isNewNote = widget.note == null;
    _titleController =
        TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _tagController = TextEditingController();
    _selectedColor = widget.note?.color ?? kNoteColors[0];
    _isPinned = widget.note?.isPinned ?? false;
    _tags = List<String>.from(widget.note?.tags ?? []);

    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  bool get _isDarkNote {
    return Color(_selectedColor).computeLuminance() < 0.5;
  }

  Color get _textColor => _isDarkNote ? Colors.white : Colors.black87;

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) return;

    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    if (_isNewNote) {
      final newNote = Note(
        id: const Uuid().v4(),
        title: title.isEmpty ? 'Başlıksız' : title,
        content: content,
        date: DateTime.now(),
        color: _selectedColor,
        isPinned: _isPinned,
        tags: _tags,
      );
      noteProvider.addNote(newNote);
    } else {
      final updatedNote = widget.note!.copyWith(
        title: title.isEmpty ? 'Başlıksız' : title,
        content: content,
        date: DateTime.now(),
        color: _selectedColor,
        isPinned: _isPinned,
        tags: _tags,
      );
      noteProvider.updateNote(updatedNote);
    }
    Navigator.pop(context);
  }

  void _deleteConfirmation() {
    if (_isNewNote) {
      Navigator.pop(context);
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Notu Sil'),
        content: const Text('Bu notu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<NoteProvider>(context, listen: false)
                  .deleteNote(widget.note!.id);
              Navigator.pop(context);
            },
            child:
                const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    final bool canSave = _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Color(_selectedColor),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _textColor),
        title: Text(
          _isNewNote ? 'Yeni Not' : 'Notu Düzenle',
          style: TextStyle(color: _textColor, fontSize: 16),
        ),
        actions: [
          // Pin button
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? Colors.amber : _textColor,
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
            tooltip: _isPinned ? 'Sabiti Kaldır' : 'Sabitle',
          ),
          // Color palette
          IconButton(
            icon: Icon(Icons.palette_outlined, color: _textColor),
            onPressed: () => _showColorPicker(),
          ),
          // Delete
          if (!_isNewNote)
            IconButton(
              icon: Icon(Icons.delete_outline, color: _textColor),
              onPressed: _deleteConfirmation,
            ),
          // Save
          IconButton(
            icon: Icon(Icons.check,
                color: canSave
                    ? _textColor
                    : _textColor.withValues(alpha: 0.3)),
            onPressed: canSave ? _saveNote : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Başlık',
                border: InputBorder.none,
                fillColor: Colors.transparent,
                hintStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textColor.withValues(alpha: 0.4)),
              ),
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textColor),
            ),
            // Content
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: 'Notunuzu buraya yazın...',
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  hintStyle: TextStyle(
                      fontSize: 16,
                      color: _textColor.withValues(alpha: 0.4)),
                ),
                style: TextStyle(fontSize: 16, color: _textColor, height: 1.5),
                maxLines: null,
                expands: true,
              ),
            ),
            // Tag section
            _buildTagSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing tags
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tags.map((tag) {
              return GestureDetector(
                onTap: () => _removeTag(tag),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _textColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _textColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('#$tag',
                          style: TextStyle(
                              fontSize: 12,
                              color: _textColor.withValues(alpha: 0.9))),
                      const SizedBox(width: 4),
                      Icon(Icons.close,
                          size: 12,
                          color: _textColor.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        // Add tag field
        Row(
          children: [
            Icon(Icons.label_outline,
                size: 18, color: _textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Etiket ekle...',
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  isDense: true,
                  hintStyle: TextStyle(
                      fontSize: 13,
                      color: _textColor.withValues(alpha: 0.4)),
                ),
                style: TextStyle(fontSize: 13, color: _textColor),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            GestureDetector(
              onTap: _addTag,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _textColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add,
                    size: 16, color: _textColor.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Renk Seç',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: kNoteColors.length,
                itemBuilder: (context, index) {
                  final color = kNoteColors[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColor = color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color
                              ? AppTheme.primaryColor
                              : Colors.grey.shade600,
                          width: _selectedColor == color ? 3 : 1,
                        ),
                      ),
                      child: _selectedColor == color
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
