import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zeno/features/library/domain/deck.dart';

class DeckDto {
  DeckDto._();

  static Deck fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? <String, dynamic>{};
    return Deck(
      id: snap.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String?,
      tags: List<String>.from(
        (d['tags'] as List<dynamic>?) ?? const <dynamic>[],
      ),
      coverColor: d['coverColor'] as String? ?? 'indigo',
      cardCount: (d['cardCount'] as num?)?.toInt() ?? 0,
      dueCount: (d['dueCount'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toFirestore(Deck d) => {
        'title': d.title,
        'description': d.description,
        'tags': d.tags,
        'coverColor': d.coverColor,
        'cardCount': d.cardCount,
        'dueCount': d.dueCount,
        'createdAt': Timestamp.fromDate(d.createdAt),
        'updatedAt': Timestamp.fromDate(d.updatedAt),
      };
}
