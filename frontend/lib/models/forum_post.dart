import 'package:cloud_firestore/cloud_firestore.dart';

enum PostCategory { announcement, maintenance, general, question, marketplace }

class ForumPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String buildingId;
  final String title;
  final String body;
  final PostCategory category;
  final List<String> imageUrls;
  final List<String> upvotedBy;
  final int replyCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  ForumPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl = '',
    required this.buildingId,
    required this.title,
    required this.body,
    required this.category,
    this.imageUrls = const [],
    this.upvotedBy = const [],
    this.replyCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  int get upvoteCount => upvotedBy.length;

  bool isUpvotedBy(String userId) => upvotedBy.contains(userId);

  factory ForumPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawCategory = (data['category'] ?? 'general').toString().trim();
    final normalizedCategory = switch (rawCategory.toLowerCase()) {
      'maintenence' => 'maintenance',
      'announcement' => 'announcement',
      'maintenance' => 'maintenance',
      'general' => 'general',
      'question' => 'question',
      'marketplace' => 'marketplace',
      _ => 'general',
    };
    return ForumPost(
      id: doc.id,
      authorId: data['authorId'] ?? data['authorUid'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      authorAvatarUrl: data['authorAvatarUrl'] ?? '',
      buildingId: data['buildingId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? data['content'] ?? '',
      category: PostCategory.values.firstWhere(
        (e) => e.name == normalizedCategory,
        orElse: () => PostCategory.general,
      ),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      upvotedBy: List<String>.from(data['upvotedBy'] ?? []),
      replyCount: data['replyCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUid': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'buildingId': buildingId,
      'title': title,
      'body': body,
      'content': body,
      'category': category.name,
      'imageUrls': imageUrls,
      'upvotedBy': upvotedBy,
      'replyCount': replyCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPinned': isPinned,
    };
  }

  ForumPost copyWith({
    List<String>? upvotedBy,
    int? replyCount,
    bool? isPinned,
  }) {
    return ForumPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      buildingId: buildingId,
      title: title,
      body: body,
      category: category,
      imageUrls: imageUrls,
      upvotedBy: upvotedBy ?? this.upvotedBy,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}