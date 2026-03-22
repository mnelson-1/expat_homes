import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    this.imageUrl,
    this.scope = 'feed',
    this.bowlId,
    this.likedBy = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final String? imageUrl;
  final String scope;
  final String? bowlId;
  final List<String> likedBy;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool isLikedBy(String uid) => likedBy.contains(uid);

  factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError('Post ${doc.id} has no data');
    final rawLikedBy = (data['likedBy'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    return Post(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorRole: data['authorRole'] as String? ?? 'Expat',
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      scope: data['scope'] as String? ?? 'feed',
      bowlId: data['bowlId'] as String?,
      likedBy: rawLikedBy,
      likeCount: data['likeCount'] as int? ?? rawLikedBy.length,
      commentCount: data['commentCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'content': content,
        'imageUrl': imageUrl,
        'scope': scope,
        'bowlId': bowlId,
        'likedBy': likedBy,
        'likeCount': likeCount,
        'commentCount': commentCount,
      };

  Map<String, dynamic> toFirestoreCreate() {
    final map = toFirestore();
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }
}
