import 'package:cloud_firestore/cloud_firestore.dart';

class ForumReply {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String body;
  final List<String> imageUrls;
  final List<String> upvotedBy;
  final DateTime createdAt;

  ForumReply({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl = '',
    required this.body,
    this.imageUrls = const [],
    this.upvotedBy = const [],
    required this.createdAt,
  });

  int get upvoteCount => upvotedBy.length;

  bool isUpvotedBy(String userId) => upvotedBy.contains(userId);

  factory ForumReply.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ForumReply(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      authorAvatarUrl: data['authorAvatarUrl'] ?? '',
      body: data['body'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      upvotedBy: List<String>.from(data['upvotedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'body': body,
      'imageUrls': imageUrls,
      'upvotedBy': upvotedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ForumReply copyWith({List<String>? upvotedBy}) {
    return ForumReply(
      id: id,
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      body: body,
      imageUrls: imageUrls,
      upvotedBy: upvotedBy ?? this.upvotedBy,
      createdAt: createdAt,
    );
  }
}