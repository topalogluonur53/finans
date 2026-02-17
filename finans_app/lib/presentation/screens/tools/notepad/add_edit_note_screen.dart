
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/providers/note_provider.dart';
import 'package:finans_app/data/models/note.dart';
import 'package:uuid/uuid.dart';

// Simple color options for now
const List<int> kNoteColors = [
  0xFFFFFFFF, // Default white
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
  _AddEditNoteScreenState createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  int _selectedColor = kNoteColors[0];
  bool _isNewNote = true;

  @override
  void initState() {
    super.initState();
    _isNewNote = widget.note == null;
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedColor = widget.note?.color ?? kNoteColors[0];

    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      return;
    }

    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    
    if (_isNewNote) {
      final newNote = Note(
        id: const Uuid().v4(),
        title: title.isEmpty ? 'Başlıksız' : title,
        content: content,
        date: DateTime.now(),
        color: _selectedColor,
      );
      noteProvider.addNote(newNote);
    } else {
      final updatedNote = widget.note!.copyWith(
        title: title.isEmpty ? 'Başlıksız' : title,
        content: content,
        date: DateTime.now(),
        color: _selectedColor,
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
        title: const Text('Notu Sil'),
        content: const Text('Bu notu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Provider.of<NoteProvider>(context, listen: false).deleteNote(widget.note!.id);
              Navigator.pop(context); // Close screen
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canSave = _titleController.text.trim().isNotEmpty || _contentController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Color(_selectedColor), // Change background based on note color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => _showColorPicker(),
          ),
          if (!_isNewNote)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteConfirmation,
            ),
          IconButton(
            icon: Icon(Icons.check, color: canSave ? Colors.black87 : Colors.black26),
            onPressed: canSave ? _saveNote : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Başlık',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Notunuzu buraya yazın...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 18, color: Colors.black45),
                ),
                style: const TextStyle(fontSize: 18),
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: kNoteColors.length,
            itemBuilder: (context, index) {
              final color = kNoteColors[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _selectedColor == color
                      ? const Icon(Icons.check, color: Colors.black54)
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
