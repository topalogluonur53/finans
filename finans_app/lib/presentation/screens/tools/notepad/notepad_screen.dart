import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/providers/note_provider.dart';
import 'package:finans_app/presentation/screens/tools/notepad/add_edit_note_screen.dart';
import 'package:finans_app/data/models/note.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotepadScreen extends StatefulWidget {
  const NotepadScreen({super.key});

  @override
  State<NotepadScreen> createState() => _NotepadScreenState();
}

class _NotepadScreenState extends State<NotepadScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Finansal notlarda ara...',
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
                onChanged: (val) {
                  context.read<NoteProvider>().setSearch(val);
                },
              )
            : const Text('Finansal Not Defteri'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchController.clear();
                context.read<NoteProvider>().setSearch('');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Consumer<NoteProvider>(
            builder: (context, provider, _) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _StatChip(
                      label: '${provider.totalNotes} Not',
                      icon: Icons.note_alt,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    if (provider.pinnedCount > 0)
                      _StatChip(
                        label: '${provider.pinnedCount} Sabitli',
                        icon: Icons.push_pin,
                        color: Colors.amber,
                      ),
                    const Spacer(),
                    // Tag filter chips
                    if (provider.allTags.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showTagFilter(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: provider.selectedTag != null
                                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                : AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(20),
                            border: provider.selectedTag != null
                                ? Border.all(color: AppTheme.primaryColor)
                                : null,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.label_outline,
                                  size: 14, color: AppTheme.textDim),
                              const SizedBox(width: 4),
                              Text(
                                provider.selectedTag ?? 'Etiket',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: provider.selectedTag != null
                                      ? AppTheme.primaryColor
                                      : AppTheme.textDim,
                                ),
                              ),
                              if (provider.selectedTag != null) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => provider.setSelectedTag(null),
                                  child: const Icon(Icons.close,
                                      size: 14, color: AppTheme.primaryColor),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          // Note grid
          Expanded(
            child: Consumer<NoteProvider>(
              builder: (context, noteProvider, child) {
                if (noteProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notes = noteProvider.notes;

                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          noteProvider.searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.notes,
                          size: 64,
                          color: AppTheme.textDim,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          noteProvider.searchQuery.isNotEmpty
                              ? 'Arama sonucu bulunamadı'
                              : 'Henüz finansal notunuz veya işlem kaydınız bulunmuyor',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18, color: AppTheme.textDim),
                        ),
                        const SizedBox(height: 8),
                        if (noteProvider.searchQuery.isEmpty)
                          const Text(
                            'Piyasa analizi, hedef fiyat veya stratejilerinizi not alın',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textDim),
                          ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _NoteCard(note: note);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddEditNoteScreen()),
          );
        },
        icon: const Icon(Icons.add_chart),
        label: const Text('Finansal Not'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showTagFilter(BuildContext context, NoteProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Etiket Filtrele',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.allTags.map((tag) {
                  final isSelected = provider.selectedTag == tag;
                  return GestureDetector(
                    onTap: () {
                      provider.setSelectedTag(isSelected ? null : tag);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textDim.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.label, size: 14),
                          const SizedBox(width: 4),
                          Text(tag,
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textLight)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _NoteCard extends StatefulWidget {
  final Note note;

  const _NoteCard({required this.note});

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final noteColor = Color(widget.note.color);
    final isDark = noteColor.computeLuminance() < 0.5;
    final textColor = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditNoteScreen(note: widget.note),
          ),
        );
      },
      onLongPress: () {
        context.read<NoteProvider>().togglePin(widget.note.id);
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: noteColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: noteColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Pin
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.note.title.isEmpty
                          ? 'Başlıksız'
                          : widget.note.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.note.isPinned)
                    Icon(Icons.push_pin,
                        size: 14, color: textColor.withValues(alpha: 0.7)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM', 'tr_TR').format(widget.note.date),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  widget.note.content,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: textColor.withValues(alpha: 0.85),
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.fade,
                ),
              ),
              // Tags
              if (widget.note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: widget.note.tags.take(2).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
