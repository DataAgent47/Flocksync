import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/forum_post.dart';
import '../models/forum_reply.dart';

class ForumService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── Collections ───────────────────────────────────────────────────────────

  CollectionReference get _posts => _db.collection('forum_posts');
  CollectionReference _replies(String postId) =>
      _db.collection('forum_posts').doc(postId).collection('replies');

  // ─── Posts ─────────────────────────────────────────────────────────────────

  /// Stream all posts for a building, newest first. Pinned posts float to top.
  Stream<List<ForumPost>> postsStream(String buildingId,
      {PostCategory? category}) {
    Query query = _posts
        .where('buildingId', isEqualTo: buildingId)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map((d) => ForumPost.fromFirestore(d)).toList(),
        );
  }

  /// Single post stream (for detail screen reactivity)
  Stream<ForumPost?> postStream(String postId) {
    return _posts.doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ForumPost.fromFirestore(doc);
    });
  }

  /// Create a new post, optionally uploading images first.
  Future<String> createPost({
    required String authorId,
    required String authorName,
    String authorAvatarUrl = '',
    required String buildingId,
    required String title,
    required String body,
    required PostCategory category,
    List<File> imageFiles = const [],
  }) async {
    final imageUrls = await _uploadImages(imageFiles, 'forum_posts');

    final ref = _posts.doc();
    final now = DateTime.now();
    final post = ForumPost(
      id: ref.id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      buildingId: buildingId,
      title: title,
      body: body,
      category: category,
      imageUrls: imageUrls,
      createdAt: now,
      updatedAt: now,
    );

    await ref.set(post.toMap());
    return ref.id;
  }

  /// Delete a post and all its replies (management/author only — enforce in UI).
  Future<void> deletePost(String postId) async {
    final repliesSnap = await _replies(postId).get();
    final batch = _db.batch();
    for (final doc in repliesSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_posts.doc(postId));
    await batch.commit();
  }

  /// Toggle upvote on a post for a given user.
  Future<void> togglePostUpvote(String postId, String userId) async {
    final ref = _posts.doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final upvotedBy = List<String>.from(snap['upvotedBy'] ?? []);
      if (upvotedBy.contains(userId)) {
        upvotedBy.remove(userId);
      } else {
        upvotedBy.add(userId);
      }
      tx.update(ref, {'upvotedBy': upvotedBy});
    });
  }

  /// Pin / unpin a post (management only — enforce in UI).
  Future<void> togglePin(String postId, bool pinned) async {
    await _posts.doc(postId).update({'isPinned': pinned});
  }

  // ─── Replies ───────────────────────────────────────────────────────────────

  Stream<List<ForumReply>> repliesStream(String postId) {
    return _replies(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ForumReply.fromFirestore(d)).toList());
  }

  Future<void> createReply({
    required String postId,
    required String authorId,
    required String authorName,
    String authorAvatarUrl = '',
    required String body,
    List<File> imageFiles = const [],
  }) async {
    final imageUrls = await _uploadImages(imageFiles, 'forum_replies/$postId');

    final ref = _replies(postId).doc();
    final reply = ForumReply(
      id: ref.id,
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      body: body,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(ref, reply.toMap());
    batch.update(_posts.doc(postId), {'replyCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> deleteReply(String postId, String replyId) async {
    final batch = _db.batch();
    batch.delete(_replies(postId).doc(replyId));
    batch.update(_posts.doc(postId), {'replyCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<void> toggleReplyUpvote(
      String postId, String replyId, String userId) async {
    final ref = _replies(postId).doc(replyId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final upvotedBy = List<String>.from(snap['upvotedBy'] ?? []);
      if (upvotedBy.contains(userId)) {
        upvotedBy.remove(userId);
      } else {
        upvotedBy.add(userId);
      }
      tx.update(ref, {'upvotedBy': upvotedBy});
    });
  }

  // ─── Image Upload ──────────────────────────────────────────────────────────

  Future<List<String>> _uploadImages(List<File> files, String folder) async {
    if (files.isEmpty) return [];
    final urls = await Future.wait(files.map((file) async {
      final name =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref('$folder/$name');
      await ref.putFile(file);
      return ref.getDownloadURL();
    }));
    return urls;
  }
}