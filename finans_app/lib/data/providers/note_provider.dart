
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_app/data/models/note.dart';

class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedTag;

  List<Note> get notes {
    List<Note> filtered = _notes;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.content.toLowerCase().contains(q))
          .toList();
    }

    // Filter by tag
    if (_selectedTag != null) {
      filtered = filtered.where((n) => n.tags.contains(_selectedTag)).toList();
    }

    // Sort: pinned first, then by date
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.date.compareTo(a.date);
    });

    return filtered;
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;

  List<String> get allTags {
    final Set<String> tags = {};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  int get totalNotes => _notes.length;
  int get pinnedCount => _notes.where((n) => n.isPinned).length;

  NoteProvider() {
    _loadNotes();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
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

  Future<void> togglePin(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(isPinned: !_notes[index].isPinned);
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
    final List<String> notesJson =
        _notes.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('notes', notesJson);
  }
}
