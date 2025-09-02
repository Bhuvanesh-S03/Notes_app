// notes_editor.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:notes_app/hero_tags.dart'; // Import the new file

/// Result payload returned to HomeScreen when saving.
class NoteEditorResult {
  final String title;
  final String content;
  final Color accent;
  final bool isPrivate;

  NoteEditorResult({
    required this.title,
    required this.content,
    required this.accent,
    required this.isPrivate,
  });
}

class NoteEditor extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final Color initialAccent;
  final List<Color> palette;
  final String heroTag;
  final bool isPrivate;

  const NoteEditor({
    super.key,
    required this.initialTitle,
    required this.initialContent,
    required this.initialAccent,
    required this.palette,
    required this.heroTag,
    this.isPrivate = false,
  });

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late Color _accent;
  late bool _isPrivate;
  late SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _content = TextEditingController(text: widget.initialContent);
    _accent = widget.initialAccent;
    _isPrivate = widget.isPrivate;
    _speech = SpeechToText();
    _tts = FlutterTts();
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      NoteEditorResult(
        title: _title.text,
        content: _content.text,
        accent: _accent,
        isPrivate: _isPrivate,
      ),
    );
  }

  void _shareNote() {
    final text = 'Title: ${_title.text}\n\nContent: ${_content.text}';
    Share.share(text);
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'listening') {
            setState(() => _isListening = true);
          } else {
            setState(() => _isListening = false);
          }
        },
        onError: (error) => debugPrint('Speech error: $error'),
      );
      if (available) {
        _speech.listen(
          onResult: (result) {
            setState(() {
              _content.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  void _textToSpeech() async {
    await _tts.speak(_content.text);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D12),
      body: Stack(
        children: [
          // Background overlay that fades in to mask any artifacts
          AnimatedBuilder(
            animation:
                ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation,
            builder: (context, child) {
              final animation =
                  ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
              return FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 0.7).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
                child: Container(color: Colors.black),
              );
            },
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
              child: Hero(
                tag: widget.heroTag,
                createRectTween: (begin, end) {
                  return RectTween(begin: begin, end: end);
                },
                flightShuttleBuilder: (
                  flightContext,
                  animation,
                  flightDirection,
                  fromHeroContext,
                  toHeroContext,
                ) {
                  return Material(
                    type: MaterialType.transparency,
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: _GlassCard(
                            accent: _accent,
                            child: Container(),
                          ),
                        );
                      },
                    ),
                  );
                },
                child: Material(
                  type: MaterialType.transparency,
                  child: _GlassCard(
                    accent: _accent,
                    child: _EditorScaffold(
                      titleController: _title,
                      contentController: _content,
                      accent: _accent,
                      palette: widget.palette,
                      onAccentChanged: (c) => setState(() => _accent = c),
                      onSave: _save,
                      isPrivate: _isPrivate,
                      onPrivateChanged:
                          (val) => setState(() => _isPrivate = val),
                      onShare: _shareNote,
                      onVoiceToText: _startListening,
                      isListening: _isListening,
                      onTextToSpeech: _textToSpeech,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: FilledButton(onPressed: _save, child: const Text('Save')),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color accent;

  const _GlassCard({required this.child, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        constraints: const BoxConstraints(maxWidth: 720),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withOpacity(0.55), width: 1.2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.06),
              Colors.white.withOpacity(0.03),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _EditorScaffold extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final Color accent;
  final List<Color> palette;
  final ValueChanged<Color> onAccentChanged;
  final VoidCallback onSave;
  final bool isPrivate;
  final ValueChanged<bool> onPrivateChanged;
  final VoidCallback onShare;
  final VoidCallback onVoiceToText;
  final bool isListening;
  final VoidCallback onTextToSpeech;

  const _EditorScaffold({
    required this.titleController,
    required this.contentController,
    required this.accent,
    required this.palette,
    required this.onAccentChanged,
    required this.onSave,
    required this.isPrivate,
    required this.onPrivateChanged,
    required this.onShare,
    required this.onVoiceToText,
    required this.isListening,
    required this.onTextToSpeech,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: Colors.white.withOpacity(0.82),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Edit Note',
                          style: Theme.of(context).textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _NeonField(
                    controller: titleController,
                    hint: 'Title',
                    accent: accent,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: 120,
                        maxHeight: constraints.maxHeight * 0.4,
                      ),
                      child: _NeonField(
                        controller: contentController,
                        hint: 'Write your thoughts…',
                        accent: accent,
                        maxLines: null,
                        expands: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Accent', style: labelStyle),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Private',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                                Switch(
                                  value: isPrivate,
                                  onChanged: onPrivateChanged,
                                  activeColor: accent,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final c in palette)
                              _AccentDot(
                                color: c,
                                selected: c.value == accent.value,
                                onTap: () => onAccentChanged(c),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: onVoiceToText,
                                    icon: Icon(
                                      isListening ? Icons.mic_off : Icons.mic,
                                      size: 28,
                                    ),
                                    tooltip: 'Voice to Text',
                                  ),
                                  const Text(
                                    'Voice',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: onTextToSpeech,
                                    icon: const Icon(Icons.volume_up, size: 28),
                                    tooltip: 'Text to Speech',
                                  ),
                                  const Text(
                                    'Speak',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: onShare,
                                    icon: const Icon(Icons.share, size: 28),
                                    tooltip: 'Share Note',
                                  ),
                                  const Text(
                                    'Share',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NeonField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color accent;
  final int? maxLines;
  final bool expands;
  final TextStyle? style;

  const _NeonField({
    required this.controller,
    required this.hint,
    required this.accent,
    this.maxLines,
    this.expands = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
    );

    return TextField(
      controller: controller,
      maxLines: maxLines,
      expands: expands,
      style: style,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: accent.withOpacity(0.7), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AccentDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.25),
            width: selected ? 2 : 1,
          ),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.95), color.withOpacity(0.65)],
          ),
        ),
      ),
    );
  }
}
