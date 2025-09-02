// hero_tags.dart

/// Generates a unique hero tag for a note based on its ID.
/// Returns a consistent string for the "New Note" hero transition.
String getHeroTag(int? noteId) {
  if (noteId == null) {
    return 'new-note-hero-tag';
  }
  return 'note-${noteId}';
}
