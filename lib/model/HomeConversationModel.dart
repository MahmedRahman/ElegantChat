import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/ConversationModel.dart';
import 'User.dart';

class HomeConversationModel2 {
  bool isGroupChat = false;
  List<User> members = [];
  String participentId = '';
  int readCount = 0;
  String role;
  FieldValue timeOfEntry = FieldValue.serverTimestamp();
  bool active = false;

  ConversationModel2 conversationModel = ConversationModel2();

  HomeConversationModel2({
    this.isGroupChat,
    this.members,
    this.conversationModel,
    this.participentId,
    this.readCount,
    this.role,
    this.timeOfEntry,
    this.active,
  });
}

class HomeConversationModel {
  bool isGroupChat = false;
  List<User> members = [];
  String participentId = '';
  int readCount = 0;
  String role;
  Timestamp timeOfEntry = Timestamp.now();
  bool active = false;

  ConversationModel conversationModel = ConversationModel();

  HomeConversationModel({
    this.isGroupChat,
    this.members,
    this.conversationModel,
    this.participentId,
    this.readCount,
    this.role,
    this.timeOfEntry,
    this.active,
  });
}
