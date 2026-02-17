
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/models/note.dart';
import 'package:finans_app/data/providers/note_provider.dart';
import 'package:intl/intl.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Defteri')),
      body: Consumer<NoteProvider>(
        builder: (context, noteProvider, child) {
          if (noteProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
           if (noteProvider.notes.isEmpty) {
            return const Center(child: Text('Henüz not eklenmemiş.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: noteProvider.notes.length,
            itemBuilder: (context, index) {
              final note = noteProvider.notes[index];
              return Card(
                color: Color(note.color),
                child: ListTile(
                  title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  subtitle: Text(
                    note.content, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  trailing: Text(
                    DateFormat('dd.MM.yyyy').format(note.date),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  onTap: () {
                    // Navigate to Edit Note
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditNoteScreen(note: note),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Note
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditNoteScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  int _selectedColor = 0xFFFFFFFF; // White default
  
  final List<int> _colors = [
    0xFFFFFFFF, // White
    0xFFFFCDD2, // Red 100
    0xFFF8BBD0, // Pink 100
    0xFFE1BEE7, // Purple 100
    0xFFD1C4E9, // Deep Purple 100
    0xFFC5CAE9, // Indigo 100
    0xFFBBDEFB, // Blue 100
    0xFFB3E5FC, // Light Blue 100
    0xFFB2EBF2, // Cyan 100
    0xFFB2DFDB, // Teal 100
    0xFFC8E6C9, // Green 100
    0xFFDCEDC8, // Light Green 100
    0xFFF0F4C3, // Lime 100
    0xFFFFF9C4, // Yellow 100
    0xFFFFECB3, // Amber 100
    0xFFFFE0B2, // Orange 100
    0xFFFFCCBC, // Deep Orange 100
  ];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedColor = widget.note!.color;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      return;
    }

    final provider = Provider.of<NoteProvider>(context, listen: false);
    
    if (widget.note != null) {
      // Update
      final updatedNote = widget.note!.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        color: _selectedColor,
        date: DateTime.now(),
      );
      provider.updateNote(updatedNote);
    } else {
      // Create
      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        content: _contentController.text,
        date: DateTime.now(),
        color: _selectedColor,
      );
      provider.addNote(newNote);
    }
    Navigator.pop(context);
  }

  void _delete() {
    if (widget.note != null) {
      Provider.of<NoteProvider>(context, listen: false).deleteNote(widget.note!.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(_selectedColor), // Make background the note color? Or just card.
      // Let's keep scaffold dark/default and use a colored container
      appBar: AppBar(
        title: Text(widget.note == null ? 'Not Ekle' : 'Not Düzenle'),
        actions: [
          if (widget.note != null)
             IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Color Picker
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color ? Colors.blue : Colors.grey,
                          width: _selectedColor == color ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Başlık',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black), 
              // Force black text since background will be light (from colors list)
              // Wait, scaffold background is dark, fields might be invisible if transparent?
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Color(_selectedColor),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minHeight: 200),
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Notunuz...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  static const double padding = 8.0;
}
