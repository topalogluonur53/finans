import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/constants/api_constants.dart';
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

    // Sort: pinned first, then by date (newest first)
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/tools/notes/'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> data =
              jsonDecode(utf8.decode(response.bodyBytes));
          _notes = data
              .map((json) => Note(
                    id: json['id'].toString(),
                    title: json['title'] ?? '',
                    content: json['content'] ?? '',
                    date: DateTime.parse(json['created_at']),
                    color: json['color'] ?? 0xFFFFFFFF,
                    isPinned: json['is_pinned'] ?? false,
                    tags: List<String>.from(json['tags'] ?? []),
                  ))
              .toList();
        }
      } else {
        // Fallback for offline tests
        final List<String>? notesJson = prefs.getStringList('notes');
        if (notesJson != null) {
          _notes = notesJson.map((e) => Note.fromJson(jsonDecode(e))).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/tools/notes/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=UTF-8'
          },
          body: jsonEncode({
            'title': note.title,
            'content': note.content,
            'color': note.color,
            'is_pinned': note.isPinned,
            'tags': note.tags
          }),
        );
        if (response.statusCode == 201) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final savedNote = note.copyWith(id: data['id'].toString());
          _notes.add(savedNote);
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error adding note: $e');
    }
    // Fallback sync
    _notes.add(note);
    await _saveNotesLocally();
    notifyListeners();
  }

  Future<void> updateNote(Note updatedNote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        final response = await http.put(
          Uri.parse('${ApiConstants.baseUrl}/tools/notes/${updatedNote.id}/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=UTF-8'
          },
          body: jsonEncode({
            'title': updatedNote.title,
            'content': updatedNote.content,
            'color': updatedNote.color,
            'is_pinned': updatedNote.isPinned,
            'tags': updatedNote.tags
          }),
        );
        if (response.statusCode == 200) {
          final index = _notes.indexWhere((note) => note.id == updatedNote.id);
          if (index != -1) {
            _notes[index] = updatedNote;
            notifyListeners();
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error updating note: $e');
    }

    // Fallback sync
    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      await _saveNotesLocally();
      notifyListeners();
    }
  }

  Future<void> togglePin(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final updated = _notes[index].copyWith(isPinned: !_notes[index].isPinned);
      await updateNote(updated);
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        final response = await http.delete(
          Uri.parse('${ApiConstants.baseUrl}/tools/notes/$id/'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 204) {
          _notes.removeWhere((note) => note.id == id);
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error deleting note: $e');
    }
    _notes.removeWhere((note) => note.id == id);
    await _saveNotesLocally();
    notifyListeners();
  }

  Future<void> _saveNotesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notesJson =
        _notes.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('notes', notesJson);
  }
}
