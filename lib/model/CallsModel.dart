import 'package:cloud_firestore/cloud_firestore.dart';

class CallsModel {
  String id = '';
  String user1 = '';
  String nameUser1 = '';
  String nameUser2 = '';
  String user2 = '';
  String channelName = '';
  String typeCall = '';
  String status = '';
  Timestamp createdAt = Timestamp.now();

  CallsModel(
      {this.id,
      this.user1,
      this.nameUser1,
      this.nameUser2,
      this.user2,
      this.createdAt,
      this.channelName,
      this.typeCall,
      this.status});

  factory CallsModel.fromJson(Map<String, dynamic> parsedJson) {
    return new CallsModel(
        id: parsedJson['id'] ?? "",
        user1: parsedJson['user1'] ?? "",
        nameUser1: parsedJson['nameUser1'] ?? "",
        nameUser2: parsedJson['nameUser2'] ?? "",
        user2: parsedJson['user2'] ?? '',
        channelName: parsedJson['channelName'] ?? '',
        typeCall: parsedJson['typeCall'] ?? '',
        status: parsedJson['status'] ?? '',
        createdAt: parsedJson['created_at'] ?? Timestamp.now());
  }

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "user1": this.user1,
      "nameUser1": this.nameUser1,
      "nameUser2": this.nameUser2,
      "user2": this.user2,
      "channelName": this.channelName,
      "typeCall": this.typeCall,
      "status": this.status,
      "created_at": this.createdAt
    };
  }
}
