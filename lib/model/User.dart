import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class User with ChangeNotifier {
  String name = '';
  String about = '';
  String phone = '';
  String associatedEmail = '';
  String pushToken = '';
  Settings settings = Settings(allowPushNotifications: true);
  bool active = false;
  Timestamp lastOnlineTimestamp = Timestamp.now();
  Timestamp createdAt = Timestamp.now();
  String userID;
  String profilePictureURL = '';
  String gender = '';
  String country = '';
  String typeUser = '';
  String merchantID = '';
  String age = '';
  String anonymouslyID = '';
  bool selected = false;
  bool privateLock = false;
  bool hideFriends = false;
  int points = 0;
  String color = '';
  String password = '';
  bool searchBar = false;
  bool refresh = true;
  bool refreshClick = false;
  String appIdentifier = 'ChatStars ${Platform.operatingSystem}';

  User(
      {this.name,
      this.password,
      this.about,
      this.phone,
      this.associatedEmail,
      this.active,
      this.lastOnlineTimestamp,
      this.createdAt,
      this.settings,
      this.userID,
      this.profilePictureURL,
      this.pushToken,
      this.gender,
      this.country,
      this.typeUser,
      this.merchantID,
      this.age,
      this.anonymouslyID,
      this.privateLock,
      this.hideFriends,
      this.points,
      this.color});

  String fullName() {
    return '$name';
  }

  factory User.fromJson(Map<String, dynamic> parsedJson) {
    return new User(
        name: parsedJson['name'] ?? '',
        password: parsedJson['password'] ?? '',
        about: parsedJson['about'] ?? '',
        phone: parsedJson['phone'] ?? '',
        associatedEmail: parsedJson['associatedEmail'] ?? '',
        active: parsedJson['active'] ?? false,
        lastOnlineTimestamp: parsedJson['lastOnlineTimestamp'],
        createdAt: parsedJson['createdAt'],
        settings: Settings.fromJson(
            parsedJson['settings'] ?? {'allowPushNotifications': true}),
        userID: parsedJson['id'] ?? parsedJson['userID'] ?? '',
        profilePictureURL: parsedJson['profilePictureURL'] ?? "",
        pushToken: parsedJson['pushToken'] ?? "",
        gender: parsedJson['gender'] ?? '',
        country: parsedJson['country'] ?? '',
        typeUser: parsedJson['typeUser'] ?? '',
        merchantID: parsedJson['merchantID'] ?? '',
        age: parsedJson['age'] ?? '',
        anonymouslyID: parsedJson['anonymouslyID'] ?? '',
        privateLock: parsedJson['privateLock'] ?? false,
        hideFriends: parsedJson['hideFriends'] ?? false,
        points: parsedJson['points'] ?? '',
        color: parsedJson['color'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'name': this.name,
      'password': this.password,
      'about': this.about,
      'phone': this.phone,
      'associatedEmail': this.associatedEmail,
      'settings': this.settings.toJson(),
      'id': this.userID,
      'userID': this.userID,
      'active': this.active,
      'lastOnlineTimestamp': this.lastOnlineTimestamp,
      'createdAt': this.createdAt,
      'profilePictureURL': this.profilePictureURL,
      'appIdentifier': this.appIdentifier,
      'pushToken': this.pushToken,
      'gender': this.gender,
      'age': this.age,
      'country': this.country,
      'typeUser': this.typeUser,
      'merchantID': this.merchantID,
      'anonymouslyID': this.anonymouslyID,
      'privateLock': this.privateLock,
      'hideFriends': this.hideFriends,
      'points': this.points,
      'color': this.color,
    };
  }
}

class Settings {
  bool allowPushNotifications = true;

  Settings({this.allowPushNotifications});

  factory Settings.fromJson(Map<dynamic, dynamic> parsedJson) {
    return new Settings(
        allowPushNotifications: parsedJson['allowPushNotifications'] ?? true);
  }

  Map<String, dynamic> toJson() {
    return {'allowPushNotifications': this.allowPushNotifications};
  }
}

class UserTimeServer with ChangeNotifier {
  String name = '';
  String about = '';
  String phone = '';
  String associatedEmail = '';
  String pushToken = '';
  Settings settings = Settings(allowPushNotifications: true);
  bool active = false;
  FieldValue lastOnlineTimestamp = FieldValue.serverTimestamp();
  FieldValue createdAt = FieldValue.serverTimestamp();
  String userID;
  String profilePictureURL = '';
  String gender = '';
  String country = '';
  String typeUser = '';
  String merchantID = '';
  String age = '';
  String anonymouslyID = '';
  bool selected = false;
  bool privateLock = false;
  bool hideFriends = false;
  int points = 0;
  String color = '';
  String password = '';
  bool searchBar = false;
  bool refresh = true;
  bool refreshClick = false;
  String appIdentifier = 'ChatStars ${Platform.operatingSystem}';

  UserTimeServer(
      {this.name,
      this.password,
      this.about,
      this.phone,
      this.associatedEmail,
      this.active,
      this.lastOnlineTimestamp,
      this.createdAt,
      this.settings,
      this.userID,
      this.profilePictureURL,
      this.pushToken,
      this.gender,
      this.country,
      this.typeUser,
      this.merchantID,
      this.age,
      this.anonymouslyID,
      this.privateLock,
      this.hideFriends,
      this.points,
      this.color});

  String fullName() {
    return '$name';
  }

  factory UserTimeServer.fromJson(Map<String, dynamic> parsedJson) {
    return new UserTimeServer(
        name: parsedJson['name'] ?? '',
        password: parsedJson['password'] ?? '',
        about: parsedJson['about'] ?? '',
        phone: parsedJson['phone'] ?? '',
        associatedEmail: parsedJson['associatedEmail'] ?? '',
        active: parsedJson['active'] ?? false,
        lastOnlineTimestamp: parsedJson['lastOnlineTimestamp'],
        createdAt: parsedJson['createdAt'],
        settings: Settings.fromJson(
            parsedJson['settings'] ?? {'allowPushNotifications': true}),
        userID: parsedJson['id'] ?? parsedJson['userID'] ?? '',
        profilePictureURL: parsedJson['profilePictureURL'] ?? "",
        pushToken: parsedJson['pushToken'] ?? "",
        gender: parsedJson['gender'] ?? '',
        country: parsedJson['country'] ?? '',
        typeUser: parsedJson['typeUser'] ?? '',
        merchantID: parsedJson['merchantID'] ?? '',
        age: parsedJson['age'] ?? '',
        anonymouslyID: parsedJson['anonymouslyID'] ?? '',
        privateLock: parsedJson['privateLock'] ?? false,
        hideFriends: parsedJson['hideFriends'] ?? false,
        points: parsedJson['points'] ?? '',
        color: parsedJson['color'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'name': this.name,
      'password': this.password,
      'about': this.about,
      'phone': this.phone,
      'associatedEmail': this.associatedEmail,
      'settings': this.settings.toJson(),
      'id': this.userID,
      'userID': this.userID,
      'active': this.active,
      'lastOnlineTimestamp': this.lastOnlineTimestamp,
      'createdAt': this.createdAt,
      'profilePictureURL': this.profilePictureURL,
      'appIdentifier': this.appIdentifier,
      'pushToken': this.pushToken,
      'gender': this.gender,
      'age': this.age,
      'country': this.country,
      'typeUser': this.typeUser,
      'merchantID': this.merchantID,
      'anonymouslyID': this.anonymouslyID,
      'privateLock': this.privateLock,
      'hideFriends': this.hideFriends,
      'points': this.points,
      'color': this.color,
    };
  }
}
