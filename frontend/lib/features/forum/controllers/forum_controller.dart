import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/forum_post.dart';
import '../../../models/forum_reply.dart';
import '../../../services/forum_service.dart';

class ForumController extends ChangeNotifier {
  final ForumService _service = ForumService();

  // ─── State ─────────────────────────────────────────────────────────────────

  bool isLoading = false;
  String? errorMessage;
  PostCategory? selectedCategory;

  // ─── Category Filter ───────────────────────────────────────────────────────

  void setCategory(PostCategory? category) {
    selectedCategory = category;
    notifyListeners();
  }

  // ─── Posts Stream ──────────────────────────────────────────────────────────

  Stream<List<ForumPost>> postsStream(String buildingId) {
    return _service.postsStream(buildingId, category: selectedCategory);
  }

  Stream<ForumPost?> postStream(String postId) {
    return _service.postStream(postId);
  }

  // ─── Replies Stream ────────────────────────────────────────────────────────

  Stream<List<ForumReply>> repliesStream(String postId) {
    return _service.repliesStream(postId);
  }

  // ─── Create Post ───────────────────────────────────────────────────────────

  Future<String?> createPost({
    required String authorId,
    required String authorName,
    String authorAvatarUrl = '',
    required String buildingId,
    required String title,
    required String body,
    required PostCategory category,
    List<File> imageFiles = const [],
  }) async {
    _setLoading(true);
    try {
      final postId = await _service.createPost(
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        buildingId: buildingId,
        title: title,
        body: body,
        category: category,
        imageFiles: imageFiles,
      );
      return postId;
    } catch (e) {
      errorMessage = 'Failed to create post: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Delete Post ───────────────────────────────────────────────────────────

  Future<bool> deletePost(String postId) async {
    _setLoading(true);
    try {
      await _service.deletePost(postId);
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete post: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Upvote Post ───────────────────────────────────────────────────────────

  Future<void> togglePostUpvote(String postId, String userId) async {
    try {
      await _service.togglePostUpvote(postId, userId);
    } catch (e) {
      errorMessage = 'Failed to upvote: $e';
      notifyListeners();
    }
  }

  // ─── Pin Post ──────────────────────────────────────────────────────────────

  Future<void> togglePin(String postId, bool pinned) async {
    try {
      await _service.togglePin(postId, pinned);
    } catch (e) {
      errorMessage = 'Failed to update pin: $e';
      notifyListeners();
    }
  }

  // ─── Create Reply ──────────────────────────────────────────────────────────

  Future<bool> createReply({
    required String postId,
    required String authorId,
    required String authorName,
    String authorAvatarUrl = '',
    required String body,
    List<File> imageFiles = const [],
  }) async {
    _setLoading(true);
    try {
      await _service.createReply(
        postId: postId,
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        body: body,
        imageFiles: imageFiles,
      );
      return true;
    } catch (e) {
      errorMessage = 'Failed to post reply: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Delete Reply ──────────────────────────────────────────────────────────

  Future<bool> deleteReply(String postId, String replyId) async {
    try {
      await _service.deleteReply(postId, replyId);
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete reply: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── Upvote Reply ──────────────────────────────────────────────────────────

  Future<void> toggleReplyUpvote(
      String postId, String replyId, String userId) async {
    try {
      await _service.toggleReplyUpvote(postId, replyId, userId);
    } catch (e) {
      errorMessage = 'Failed to upvote reply: $e';
      notifyListeners();
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}