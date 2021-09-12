import 'User.dart';

class MemberModel {
  String userID = '';
  String name = '';
  String role = '';
  String channelParticipationID = '';
  User user2;

  MemberModel({this.userID, this.name, this.role, this.channelParticipationID});

  factory MemberModel.fromJson(Map<String, dynamic> parsedJson) {
    return new MemberModel(
        userID: parsedJson['userID'] ?? '',
        name: parsedJson['name'] ?? '',
        role: parsedJson['role'] ?? '',
        channelParticipationID: parsedJson['channelParticipationID'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      "userID": this.userID,
      "name": this.name,
      "role": this.role,
      "channelParticipationID": this.channelParticipationID,
    };
  }
}
