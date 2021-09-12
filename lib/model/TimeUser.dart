import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TimeUser with ChangeNotifier {
  Timestamp timeLogin = Timestamp.now();

  TimeUser({
    this.timeLogin,
  });

  factory TimeUser.fromJson(Map<String, dynamic> parsedJson) {
    return new TimeUser(
      timeLogin: parsedJson['timeLogin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeLogin': this.timeLogin,
    };
  }
}
