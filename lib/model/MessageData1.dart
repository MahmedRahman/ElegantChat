import 'package:cloud_firestore/cloud_firestore.dart';

class MessageData1 {
  String messageID = '';
  UrlMessage url = UrlMessage(url: '', mime: '');
  String content = '';
  FieldValue created = FieldValue.serverTimestamp();
  String recipientFirstName = '';
  String recipientLastName = '';
  String recipientProfilePictureURL = '';
  String recipientID = '';
  String senderFirstName = '';
  String senderLastName = '';
  String senderProfilePictureURL = '';
  String senderID = '';
  String videoThumbnail = '';
  String voiceUrl = '';
  String notify = '';
  String nameColor = '0xFF222834';
  String role;

  MessageData1({
    this.messageID,
    this.url,
    this.content,
    this.created,
    this.recipientFirstName,
    this.recipientLastName,
    this.recipientProfilePictureURL,
    this.recipientID,
    this.senderFirstName,
    this.senderLastName,
    this.senderProfilePictureURL,
    this.senderID,
    this.videoThumbnail,
    this.voiceUrl,
    this.notify,
    this.nameColor,
    this.role,
  });

  factory MessageData1.fromJson(Map<String, dynamic> parsedJson) {
    return new MessageData1(
      messageID: parsedJson['id'] ?? parsedJson['messageID'] ?? '',
      url: UrlMessage.fromJson(
          parsedJson['urlMessage'] ?? {'mime': '', 'url': ''}),
      content: parsedJson['content'] ?? '',
      created: parsedJson['createdAt'] ??
          parsedJson['created'] ??
          FieldValue.serverTimestamp(),
      recipientFirstName: parsedJson['recipientFirstName'] ?? '',
      recipientLastName: parsedJson['recipientLastName'] ?? '',
      recipientProfilePictureURL:
          parsedJson['recipientProfilePictureURL'] ?? '',
      recipientID: parsedJson['recipientID'] ?? '',
      senderFirstName: parsedJson['senderFirstName'] ?? '',
      senderLastName: parsedJson['senderLastName'] ?? '',
      senderProfilePictureURL: parsedJson['senderProfilePictureURL'] ?? '',
      senderID: parsedJson['senderID'] ?? '',
      videoThumbnail: parsedJson['videoThumbnail'] ?? '',
      voiceUrl: parsedJson['voiceUrl'] ?? '',
      notify: parsedJson['notify'] ?? '',
      nameColor: parsedJson['nameColor'] ?? '',
      role: parsedJson['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": this.messageID,
      "url": this.url.toJson(),
      "content": this.content,
      "createdAt": this.created,
      "recipientFirstName": this.recipientFirstName,
      'recipientLastName': this.recipientLastName,
      'recipientProfilePictureURL': this.recipientProfilePictureURL,
      "recipientID": this.recipientID,
      "senderFirstName": this.senderFirstName,
      "senderLastName": this.senderLastName,
      "senderProfilePictureURL": this.senderProfilePictureURL,
      "senderID": this.senderID,
      "videoThumbnail": this.videoThumbnail,
      "voiceUrl": this.voiceUrl,
      "notify": this.notify,
      "nameColor": this.nameColor,
      "role": this.role,
    };
  }
}

class UrlMessage {
  String mime = '';
  String url = '';

  UrlMessage({this.mime, this.url});

  factory UrlMessage.fromJson(Map<dynamic, dynamic> parsedJson) {
    return new UrlMessage(
        mime: parsedJson['mime'] ?? '', url: parsedJson['url'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'mime': this.mime, 'url': this.url};
  }
}
