import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel2 {
  String id = '';
  String creatorId = '';
  String lastMessage = '';
  String name = '';
  String description = '';
  FieldValue lastMessageDate = FieldValue.serverTimestamp();
  int msgCount = 0;
  int currentNumberMembers = 0;

  ConversationModel2({
    this.id,
    this.creatorId,
    this.lastMessage,
    this.name,
    this.description,
    this.lastMessageDate,
    this.msgCount,
    this.currentNumberMembers,
  });

  factory ConversationModel2.fromJson(Map<String, dynamic> parsedJson) {
    return new ConversationModel2(
      id: parsedJson['id'] ?? '',
      creatorId: parsedJson['creatorID'] ?? parsedJson['creator_id'] ?? '',
      lastMessage: parsedJson['lastMessage'] ?? '',
      name: parsedJson['name'] ?? '',
      description: parsedJson['description'] ?? '',
      lastMessageDate:
          parsedJson['lastMessageDate'] ?? FieldValue.serverTimestamp(),
      msgCount: parsedJson['msgCount'] ?? 0,
      currentNumberMembers: parsedJson['currentNumberMembers'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "creatorID": this.creatorId,
      "lastMessage": this.lastMessage,
      "name": this.name,
      "description": this.description,
      "lastMessageDate": this.lastMessageDate,
      "msgCount": this.msgCount,
      "currentNumberMembers": this.currentNumberMembers,
    };
  }
}

class ConversationModel {
  String id = '';
  String creatorId = '';
  String lastMessage = '';
  String name = '';
  String description = '';
  Timestamp lastMessageDate = Timestamp.now();
  int msgCount = 0;
  int currentNumberMembers = 0;

  ConversationModel({
    this.id,
    this.creatorId,
    this.lastMessage,
    this.name,
    this.description,
    this.lastMessageDate,
    this.msgCount,
    this.currentNumberMembers,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> parsedJson) {
    return new ConversationModel(
      id: parsedJson['id'] ?? '',
      creatorId: parsedJson['creatorID'] ?? parsedJson['creator_id'] ?? '',
      lastMessage: parsedJson['lastMessage'] ?? '',
      name: parsedJson['name'] ?? '',
      description: parsedJson['description'] ?? '',
      lastMessageDate: parsedJson['lastMessageDate'] ?? Timestamp.now(),
      msgCount: parsedJson['msgCount'] ?? 0,
      currentNumberMembers: parsedJson['currentNumberMembers'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "creatorID": this.creatorId,
      "lastMessage": this.lastMessage,
      "name": this.name,
      "description": this.description,
      "lastMessageDate": this.lastMessageDate,
      "msgCount": this.msgCount,
      "currentNumberMembers": this.currentNumberMembers,
    };
  }
}
