// home_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:notes_app/custom_transtion.dart';
import 'package:notes_app/note.dart';
import 'package:notes_app/notes_editor.dart';
 // Import the new file

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Note> _notesBox;
  final LocalAuthentication auth = LocalAuthentication();
  bool _boxInitialized = false;

  static const List<Color> neonPalette = [
    Color(0xFF00E5FF),
    Color(0xFFFF2ED1),
    Color(0xFF7C4DFF),
    Color(0xFF00FFA3),
    Color(0xFFFFEA00),
  ];

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _notesBox = await Hive.openBox<Note>('notesBox');
    if (mounted) {
      setState(() {
        _boxInitialized = true;
      });
    }
  }

  Future<void> _authenticateAndEdit(Note note) async {
    if (!note.isPrivate) {
      _editNote(note);
      return;
    }

    bool isAuthenticated = false;
    try {
      final canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      if (canAuthenticateWithBiometrics) {
        isAuthenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to access this private note',
          options: const AuthenticationOptions(stickyAuth: true),
        );
      } else {
        isAuthenticated = await _showPasswordDialog(context);
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: ${e.message}')),
      );
      return;
    }

    if (isAuthenticated) {
      _editNote(note);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Authentication failed.')));
    }
  }

  Future<bool> _showPasswordDialog(BuildContext context) async {
    String? password;
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Enter Password'),
              content: TextField(
                onChanged: (value) => password = value,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (password == '1234') {
                      Navigator.of(context).pop(true);
                    } else {
                      Navigator.of(context).pop(false);
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_boxInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D12),
      appBar: AppBar(title: const Text('Neo Notes')),
      body:
          _notesBox.isEmpty
              ? const _EmptyHint()
              : Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                child: ValueListenableBuilder(
                  valueListenable: _notesBox.listenable(),
                  builder: (context, box, _) {
                    final notes = box.values.toList().reversed.toList();
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.86,
                          ),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return _NoteCard(
                          note: note,
                          onEdit: () => _authenticateAndEdit(note),
                          onDelete: () async {
                            await note.delete();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        label: const Text('New Note'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addNote() async {
    final accent = neonPalette[_notesBox.length % neonPalette.length];
    final result = await Navigator.of(context).push(
      // Use CustomNoteTransition for opening
      CustomNoteTransition(
        NoteEditor(
          initialTitle: '',
          initialContent: '',
          initialAccent: accent,
          palette: neonPalette,
          heroTag: 'new-note-hero-tag',
        ),
      ),
    );

    if (result is NoteEditorResult) {
      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch,
        title: result.title.trim(),
        content: result.content.trim(),
        accent: result.accent.value,
        createdAt: DateTime.now(),
        isPrivate: result.isPrivate,
      );
      await _notesBox.add(newNote);
    }
  }

  Future<void> _editNote(Note note) async {
    final result = await Navigator.of(context).push(
      // Use CustomNoteTransition for editing
      CustomNoteTransition(
        NoteEditor(
          initialTitle: note.title,
          initialContent: note.content,
          initialAccent: Color(note.accent),
          palette: neonPalette,
          heroTag: 'note-${note.id}',
          isPrivate: note.isPrivate,
        ),
      ),
    );

    if (result is NoteEditorResult) {
      note.title = result.title.trim();
      note.content = result.content.trim();
      note.accent = result.accent.value;
      note.isPrivate = result.isPrivate;
      await note.save();
    }
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.style_outlined, size: 64),
            SizedBox(height: 12),
            Text(
              'No notes yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text('Tap “New Note” to create your first note.'),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final Future<void> Function() onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = 'note-${note.id}';
    return GestureDetector(
      onTap: onEdit,
      child: Hero(
        tag: heroTag,
        child: _GlassCard(
          accent: Color(note.accent),
          title: note.title.isEmpty ? 'Untitled' : note.title,
          contentPreview: note.content,
          onDeleteTap: onDelete,
          isPrivate: note.isPrivate,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Color accent;
  final String title;
  final String contentPreview;
  final VoidCallback onDeleteTap;
  final bool isPrivate;

  const _GlassCard({
    required this.accent,
    required this.title,
    required this.contentPreview,
    required this.onDeleteTap,
    required this.isPrivate,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.55), width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.06),
              Colors.white.withOpacity(0.03),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isPrivate)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.lock, size: 16, color: Colors.white70),
                  ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDeleteTap,
                  icon: const Icon(Icons.delete_outline),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Opacity(
                opacity: 0.9,
                child: Text(
                  isPrivate
                      ? 'This is a private note'
                      : contentPreview.isEmpty
                      ? 'Tap to edit…'
                      : contentPreview,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    accent,
                    accent.withOpacity(0.5),
                    accent.withOpacity(0.2),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
