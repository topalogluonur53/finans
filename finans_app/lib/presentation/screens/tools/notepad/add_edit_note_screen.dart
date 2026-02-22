import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/providers/note_provider.dart';
import 'package:finans_app/data/models/note.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

const List<int> kNoteColors = [
  0xFF1E1E2E, // Dark (default)
  0xFF2D2D44, // Dark blue
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

class _AddEditNoteScreenState extends State<AddEditNoteScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  int _selectedColor = kNoteColors[0];
  bool _isNewNote = true;
  bool _isPinned = false;
  List<String> _tags = [];
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _isNewNote = widget.note == null;
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tagController = TextEditingController();
    _selectedColor = widget.note?.color ?? kNoteColors[0];
    _isPinned = widget.note?.isPinned ?? false;
    _tags = List<String>.from(widget.note?.tags ?? []);

    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));

    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _animController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Color get _bgColor => Color(_selectedColor);
  bool get _isDark => _bgColor.computeLuminance() < 0.5;
  Color get _textColor => _isDark ? Colors.white : Colors.black87;
  Color get _subtleColor => _isDark
      ? Colors.white.withValues(alpha: 0.45)
      : Colors.black.withValues(alpha: 0.38);

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty ||
      _contentController.text.trim().isNotEmpty;

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) return;

    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    if (_isNewNote) {
      noteProvider.addNote(Note(
        id: const Uuid().v4(),
        title: title.isEmpty ? 'Baslıksız' : title,
        content: content,
        date: DateTime.now(),
        color: _selectedColor,
        isPinned: _isPinned,
        tags: _tags,
      ));
    } else {
      noteProvider.updateNote(widget.note!.copyWith(
        title: title.isEmpty ? 'Baslıksız' : title,
        content: content,
        date: DateTime.now(),
        color: _selectedColor,
        isPinned: _isPinned,
        tags: _tags,
      ));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Notu Sil',
            style: TextStyle(color: AppTheme.textLight)),
        content: const Text(
          'Bu notu silmek istediginizden emin misiniz?',
          style: TextStyle(color: AppTheme.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Iptal',
                style: TextStyle(color: AppTheme.textDim)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<NoteProvider>(context, listen: false)
                  .deleteNote(widget.note!.id);
              Navigator.pop(context);
            },
            child: const Text('Sil',
                style: TextStyle(color: Colors.redAccent)),
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

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ColorPickerSheet(
        selectedColor: _selectedColor,
        onSelected: (color) {
          setState(() => _selectedColor = color);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ────────────────────────────────────────────
              _TopBar(
                isNewNote: _isNewNote,
                isPinned: _isPinned,
                canSave: _canSave,
                textColor: _textColor,
                subtleColor: _subtleColor,
                onBack: () => Navigator.pop(context),
                onPin: () => setState(() => _isPinned = !_isPinned),
                onColorPicker: _showColorPicker,
                onDelete: !_isNewNote ? _deleteConfirmation : null,
                onSave: _canSave ? _saveNote : null,
              ),

              // ── Writing Area ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_contentFocus),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: _textColor,
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Baslik...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: _subtleColor,
                          ),
                        ),
                        maxLines: null,
                      ),

                      // Divider
                      Divider(
                        color: _textColor.withValues(alpha: 0.12),
                        height: 16,
                      ),

                      // Content Field
                      TextField(
                        controller: _contentController,
                        focusNode: _contentFocus,
                        style: TextStyle(
                          fontSize: 16,
                          color: _textColor,
                          height: 1.65,
                          letterSpacing: 0.1,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Notunuzu buraya yazin...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: _subtleColor,
                            height: 1.65,
                          ),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),

                      const SizedBox(height: 24),

                      // Tags Section
                      _TagsSection(
                        tags: _tags,
                        textColor: _textColor,
                        subtleColor: _subtleColor,
                        tagController: _tagController,
                        onAddTag: _addTag,
                        onRemoveTag: _removeTag,
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom Toolbar ──────────────────────────────────────────
        bottomNavigationBar: _BottomToolbar(
          bgColor: _bgColor,
          textColor: _textColor,
          subtleColor: _subtleColor,
          isPinned: _isPinned,
          wordCount: _contentController.text.trim().isEmpty
              ? 0
              : _contentController.text.trim().split(RegExp(r'\s+')).length,
          charCount: _contentController.text.length,
          onColorPicker: _showColorPicker,
          onPin: () => setState(() => _isPinned = !_isPinned),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isNewNote;
  final bool isPinned;
  final bool canSave;
  final Color textColor;
  final Color subtleColor;
  final VoidCallback onBack;
  final VoidCallback onPin;
  final VoidCallback onColorPicker;
  final VoidCallback? onDelete;
  final VoidCallback? onSave;

  const _TopBar({
    required this.isNewNote,
    required this.isPinned,
    required this.canSave,
    required this.textColor,
    required this.subtleColor,
    required this.onBack,
    required this.onPin,
    required this.onColorPicker,
    this.onDelete,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      child: Row(
        children: [
          // Back
          _IconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            color: textColor,
            onTap: onBack,
            tooltip: 'Geri',
          ),
          const Spacer(),
          // Pin
          _IconBtn(
            icon: isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            color: isPinned ? Colors.amber : textColor,
            onTap: onPin,
            tooltip: isPinned ? 'Sabiti Kaldir' : 'Sabitle',
          ),
          // Color
          _IconBtn(
            icon: Icons.palette_outlined,
            color: textColor,
            onTap: onColorPicker,
            tooltip: 'Renk Sec',
          ),
          // Delete
          if (onDelete != null)
            _IconBtn(
              icon: Icons.delete_outline_rounded,
              color: textColor,
              onTap: onDelete!,
              tooltip: 'Sil',
            ),
          // Save
          AnimatedOpacity(
            opacity: canSave ? 1.0 : 0.35,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: onSave,
              child: Container(
                margin: const EdgeInsets.only(left: 4, right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 16, color: textColor),
                    const SizedBox(width: 5),
                    Text(
                      'Kaydet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _TagsSection extends StatelessWidget {
  final List<String> tags;
  final Color textColor;
  final Color subtleColor;
  final TextEditingController tagController;
  final VoidCallback onAddTag;
  final void Function(String) onRemoveTag;

  const _TagsSection({
    required this.tags,
    required this.textColor,
    required this.subtleColor,
    required this.tagController,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing tags
        if (tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((tag) {
              return GestureDetector(
                onTap: () => onRemoveTag(tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: textColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_outline, size: 12, color: subtleColor),
                      const SizedBox(width: 4),
                      Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textColor.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.close_rounded, size: 12, color: subtleColor),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 10),

        // Add tag field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.label_outline, size: 16, color: subtleColor),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: tagController,
                  style: TextStyle(fontSize: 13, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Etiket ekle...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(fontSize: 13, color: subtleColor),
                  ),
                  onSubmitted: (_) => onAddTag(),
                  textInputAction: TextInputAction.done,
                ),
              ),
              GestureDetector(
                onTap: onAddTag,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, size: 14, color: textColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final Color bgColor;
  final Color textColor;
  final Color subtleColor;
  final bool isPinned;
  final int wordCount;
  final int charCount;
  final VoidCallback onColorPicker;
  final VoidCallback onPin;

  const _BottomToolbar({
    required this.bgColor,
    required this.textColor,
    required this.subtleColor,
    required this.isPinned,
    required this.wordCount,
    required this.charCount,
    required this.onColorPicker,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = bgColor.computeLuminance() < 0.5;
    final toolbarBg = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.07);

    return Container(
      color: bgColor,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: toolbarBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Word / Char count
              Icon(Icons.format_size, size: 14, color: subtleColor),
              const SizedBox(width: 6),
              Text(
                '$wordCount kelime · $charCount karakter',
                style: TextStyle(fontSize: 12, color: subtleColor),
              ),
              const Spacer(),
              // Color swatch
              GestureDetector(
                onTap: onColorPicker,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: textColor.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Pin toggle
              GestureDetector(
                onTap: onPin,
                child: Icon(
                  isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  size: 20,
                  color: isPinned ? Colors.amber : subtleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPickerSheet extends StatelessWidget {
  final int selectedColor;
  final void Function(int) onSelected;

  const _ColorPickerSheet({
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Arkaplan Rengi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textLight,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: kNoteColors.length,
            itemBuilder: (context, index) {
              final color = kNoteColors[index];
              final isSelected = selectedColor == color;
              return GestureDetector(
                onTap: () => onSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(color).withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}