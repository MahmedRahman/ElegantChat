import 'package:cloud_firestore/cloud_firestore.dart';

class ChannelParticipation2 {
  String channel = '';
  String user = '';
  int readCount = 0;
  String role = '';
  FieldValue timeOfEntry = FieldValue.serverTimestamp();
  bool active = false;
  bool block = false;

  ChannelParticipation2(
      {this.channel,
      this.user,
      this.readCount,
      this.role,
      this.timeOfEntry,
      this.block,
      this.active});

  factory ChannelParticipation2.fromJson(Map<String, dynamic> parsedJson) {
    return new ChannelParticipation2(
      channel: parsedJson['channel'] ?? "",
      user: parsedJson['user'] ?? "",
      readCount: parsedJson['readCount'] ?? 0,
      role: parsedJson['role'] ?? "",
      timeOfEntry: parsedJson['timeOfEntry'],
      active: parsedJson['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "channel": this.channel,
      "user": this.user,
      "readCount": this.readCount,
      "role": this.role,
      "timeOfEntry": this.timeOfEntry,
      "active": this.active,
    };
  }
}

class ChannelParticipation {
  String channel = '';
  String user = '';
  int readCount = 0;
  String role = '';
  Timestamp timeOfEntry = Timestamp.now();
  bool active = false;
  bool block = false;

  ChannelParticipation(
      {this.channel,
      this.user,
      this.readCount,
      this.role,
      this.timeOfEntry,
      this.block,
      this.active});

  factory ChannelParticipation.fromJson(Map<String, dynamic> parsedJson) {
    return new ChannelParticipation(
      channel: parsedJson['channel'] ?? "",
      user: parsedJson['user'] ?? "",
      readCount: parsedJson['readCount'] ?? 0,
      role: parsedJson['role'] ?? "",
      timeOfEntry: parsedJson['timeOfEntry'],
      active: parsedJson['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "channel": this.channel,
      "user": this.user,
      "readCount": this.readCount,
      "role": this.role,
      "timeOfEntry": this.timeOfEntry,
      "active": this.active,
    };
  }
}
