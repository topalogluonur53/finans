
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_app/data/models/note.dart';

class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  NoteProvider() {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final List<String>? notesJson = prefs.getStringList('notes');
    if (notesJson != null) {
      _notes = notesJson.map((e) => Note.fromJson(jsonDecode(e))).toList();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    _notes.add(note);
    await _saveNotes();
    notifyListeners();
  }

  Future<void> updateNote(Note updatedNote) async {
    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      await _saveNotes();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((note) => note.id == id);
    await _saveNotes();
    notifyListeners();
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notesJson = _notes.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('notes', notesJson);
  }
}
