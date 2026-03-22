import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post.dart';
import '../models/post_comment.dart';

class CommunityService {
  CommunityService._();
  static final CommunityService _instance = CommunityService._();
  factory CommunityService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection('posts');

  CollectionReference<Map<String, dynamic>> get _commentsRef =>
      _firestore.collection('post_comments');

  // ---------------------------------------------------------------------------
  // Posts
  // ---------------------------------------------------------------------------

  /// Stream of general-feed posts, client-side sorted by createdAt desc.
  Stream<List<Post>> feedPostsStream() {
    return _postsRef
        .where('scope', isEqualTo: 'feed')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => Post.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Stream of posts scoped to a specific bowl.
  Stream<List<Post>> bowlPostsStream(String bowlId) {
    return _postsRef
        .where('bowlId', isEqualTo: bowlId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => Post.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Fetch a single post by ID.
  Future<Post?> getPost(String postId) async {
    final doc = await _postsRef.doc(postId).get();
    if (!doc.exists) return null;
    return Post.fromFirestore(doc);
  }

  /// Create a new post (feed or bowl-scoped).
  Future<Post> createPost({
    required String authorId,
    required String authorName,
    required String authorRole,
    required String content,
    String? imageUrl,
    String? authorImageUrl,
    String scope = 'feed',
    String? bowlId,
  }) async {
    final post = Post(
      id: '',
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      content: content,
      imageUrl: imageUrl,
      authorImageUrl: authorImageUrl,
      scope: scope,
      bowlId: bowlId,
    );
    final docRef = await _postsRef.add(post.toFirestoreCreate());
    final created = await docRef.get();
    return Post.fromFirestore(created);
  }

  /// Delete own post.
  Future<void> deletePost(String postId) async {
    await _postsRef.doc(postId).delete();
  }

  // ---------------------------------------------------------------------------
  // Likes (Posts)
  // ---------------------------------------------------------------------------

  /// Toggle like on a post. Returns true if now liked, false if unliked.
  Future<bool> toggleLike(String postId, String userId) async {
    final docRef = _postsRef.doc(postId);
    final doc = await docRef.get();
    if (!doc.exists) return false;

    final likedBy = List<String>.from(
      (doc.data()?['likedBy'] as List<dynamic>?) ?? [],
    );
    final alreadyLiked = likedBy.contains(userId);

    if (alreadyLiked) {
      await docRef.update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likeCount': FieldValue.increment(-1),
      });
      return false;
    } else {
      await docRef.update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likeCount': FieldValue.increment(1),
      });
      return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------------

  /// Stream of comments for a post, client-side sorted by createdAt asc.
  Stream<List<PostComment>> commentsStream(String postId) {
    return _commentsRef
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => PostComment.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2099);
        final bTime = b.createdAt ?? DateTime(2099);
        return aTime.compareTo(bTime);
      });
      return list;
    });
  }

  /// Add a comment (or reply) to a post.
  Future<PostComment> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String authorRole,
    required String content,
    String? authorImageUrl,
    String? parentCommentId,
  }) async {
    final comment = PostComment(
      id: '',
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      content: content,
      authorImageUrl: authorImageUrl,
      parentCommentId: parentCommentId,
    );
    final docRef = await _commentsRef.add(comment.toFirestoreCreate());

    // Increment comment count on parent post.
    await _postsRef.doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });

    final created = await docRef.get();
    return PostComment.fromFirestore(created);
  }

  // ---------------------------------------------------------------------------
  // Likes (Comments)
  // ---------------------------------------------------------------------------

  /// Toggle like on a comment. Returns true if now liked, false if unliked.
  Future<bool> toggleCommentLike(String commentId, String userId) async {
    final docRef = _commentsRef.doc(commentId);
    final doc = await docRef.get();
    if (!doc.exists) return false;

    final likedBy = List<String>.from(
      (doc.data()?['likedBy'] as List<dynamic>?) ?? [],
    );
    final alreadyLiked = likedBy.contains(userId);

    if (alreadyLiked) {
      await docRef.update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likeCount': FieldValue.increment(-1),
      });
      return false;
    } else {
      await docRef.update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likeCount': FieldValue.increment(1),
      });
      return true;
    }
  }
}
