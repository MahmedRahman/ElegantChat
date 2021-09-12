import 'package:cloud_firestore/cloud_firestore.dart';

class Friendship {
  String id = '';
  String user1 = '';
  String user2 = '';
  Timestamp createdAt = Timestamp.now();

  Friendship({this.id, this.user1, this.user2, this.createdAt});

  factory Friendship.fromJson(Map<String, dynamic> parsedJson) {
    return new Friendship(
        id: parsedJson['id'] ?? "",
        user1: parsedJson['user1'] ?? "",
        user2: parsedJson['user2'] ?? '',
        createdAt: parsedJson['created_at'] ?? Timestamp.now());
  }

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "user1": this.user1,
      "user2": this.user2,
      "created_at": this.createdAt
    };
  }
}
