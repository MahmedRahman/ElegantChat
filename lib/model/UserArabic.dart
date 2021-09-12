import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'User.dart';

class UserArabic with ChangeNotifier {
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
  String age = '';
  String merchantID = '';
  bool selected = false;
  bool privateLock = true;
  bool hideFriends = true;
  int points = 0;
  String color = '';
  String password = '';
  String appIdentifier = 'ChatStars ${Platform.operatingSystem}';

  UserArabic(
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
      this.age,
      this.merchantID,
      this.privateLock,
      this.hideFriends,
      this.points,
      this.color});

  String fullName() {
    return '$name';
  }

  factory UserArabic.fromJson(Map<String, dynamic> parsedJson) {
    return new UserArabic(
        name: parsedJson['name'] ?? '',
        password: parsedJson['password'] ?? '',
        about: parsedJson['about'] ?? '',
        phone: parsedJson['phone'] ?? '',
        associatedEmail: parsedJson['associatedEmail'] ?? '',
        active: parsedJson['active'] ?? false,
        privateLock: parsedJson['privateLock'] ?? true,
        hideFriends: parsedJson['hideFriends'] ?? false,
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
        age: parsedJson['age'] ?? '',
        merchantID: parsedJson['merchantID'] ?? '',
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
      'country': this.country,
      'typeUser': this.typeUser,
      'age': this.age,
      'merchantID': this.merchantID,
      'privateLock': this.privateLock,
      'hideFriends': this.hideFriends,
      'points': this.points,
      'color': this.color,
    };
  }
}
