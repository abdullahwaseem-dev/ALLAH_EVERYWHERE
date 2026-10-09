enum BookmarkType { surah, hadith, dua, divineName, mushafPage, prophetStory }

/// A saved reference into Quran/Hadith/Dua content. [refId] is
/// type-specific: a Surah id for [BookmarkType.surah], a
/// "bookSlug|chapterId" pair for [BookmarkType.hadith], a
/// "categoryTitle|duaTitle" pair for [BookmarkType.dua], the Name's
/// number (1-99) for [BookmarkType.divineName], the page number (1-604)
/// for [BookmarkType.mushafPage], and a "prophetId|chapterIndex" pair for
/// [BookmarkType.prophetStory] - each screen that
/// creates a bookmark knows how to both build and parse its own refId.
class Bookmark {
  final String id;
  final BookmarkType type;
  final String refId;
  final String title;
  final String subtitle;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.type,
    required this.refId,
    required this.title,
    required this.subtitle,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'refId': refId,
        'title': title,
        'subtitle': subtitle,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromMap(String id, Map<String, dynamic> map) => Bookmark(
        id: id,
        type: BookmarkType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => BookmarkType.surah,
        ),
        refId: map['refId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        subtitle: map['subtitle'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
