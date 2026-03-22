import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    this.authorImageUrl,
    this.parentCommentId,
    this.likedBy = const [],
    this.likeCount = 0,
    this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final String? authorImageUrl;
  final String? parentCommentId;
  final List<String> likedBy;
  final int likeCount;
  final DateTime? createdAt;

  bool get isReply => parentCommentId != null;
  bool isLikedBy(String uid) => likedBy.contains(uid);

  factory PostComment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) throw StateError('PostComment ${doc.id} has no data');
    final rawLikedBy = (data['likedBy'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    return PostComment(
      id: doc.id,
      postId: data['postId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorRole: data['authorRole'] as String? ?? 'Expat',
      content: data['content'] as String? ?? '',
      authorImageUrl: data['authorImageUrl'] as String?,
      parentCommentId: data['parentCommentId'] as String?,
      likedBy: rawLikedBy,
      likeCount: data['likeCount'] as int? ?? rawLikedBy.length,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'content': content,
        'authorImageUrl': authorImageUrl,
        'parentCommentId': parentCommentId,
        'likedBy': likedBy,
        'likeCount': likeCount,
      };

  Map<String, dynamic> toFirestoreCreate() {
    final map = toFirestore();
    map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }
}
