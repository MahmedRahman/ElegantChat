import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  int currentNumberMembers = 0;
  String description = '';
  String creatorID = '';
  String name = '';
  String distinguishedArrangement = '';
  bool especially = false;
  String lastMessage = '';
  int msgCount = 0;
  String id = '';
  bool normalArrangement = false;
  int numberOfMembers = 0;
  int readCount = 0;
  Timestamp paidArrangement = Timestamp.fromDate(DateTime(2018, 01, 13));

  GroupModel(
      {this.creatorID,
      this.name,
      this.currentNumberMembers,
      this.description,
      this.distinguishedArrangement,
      this.especially,
      this.lastMessage,
      this.msgCount,
      this.id,
      this.normalArrangement,
      this.numberOfMembers,
      this.readCount,
      this.paidArrangement});

  factory GroupModel.fromJson(Map<String, dynamic> parsedJson) {
    return new GroupModel(
        creatorID: parsedJson['creatorID'] ?? "",
        name: parsedJson['name'] ?? "",
        currentNumberMembers: parsedJson['currentNumberMembers'] ?? 0,
        description: parsedJson['description'] ?? "",
        distinguishedArrangement: parsedJson['distinguishedArrangement'] ?? "",
        especially: parsedJson['especially'] ?? false,
        lastMessage: parsedJson['lastMessage'] ?? "",
        msgCount: parsedJson['msgCount'] ?? 0,
        id: parsedJson['id'] ?? "",
        normalArrangement: parsedJson['normalArrangement'] ?? false,
        numberOfMembers: parsedJson['numberOfMembers'] ?? 0,
        readCount: parsedJson['readCount'] ?? 0,
        paidArrangement: parsedJson['paidArrangement']);
  }

  Map<String, dynamic> toJson() {
    return {
      "creatorID": this.creatorID,
      "name": this.name,
      "currentNumberMembers": this.currentNumberMembers,
      "description": this.description,
      "distinguishedArrangement": this.distinguishedArrangement,
      "especially": this.especially,
      "lastMessage": this.lastMessage,
      "msgCount": this.msgCount,
      "id": this.id,
      "normalArrangement": this.normalArrangement,
      "numberOfMembers": this.numberOfMembers,
      "readCount": this.readCount,
      "paidArrangement": this.paidArrangement
    };
  }
}
