import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/model/UserArabic.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

import '../../constants.dart';
import '../../constants.dart' as Constants;
import '../../main.dart';
import '../../model/User.dart';
import 'FirebaseHelper.dart';

class UserHelper {
  FirebaseMessaging _firebaseMessaging1 = FirebaseMessaging();
  static Firestore firestore = Firestore.instance;
  static DocumentReference currentUserDocRef =
      firestore.collection(USERS).document(MyAppState.currentUser.userID);
  StorageReference storage = FirebaseStorage.instance.ref();
  FireStoreUtils _fireStoreUtils = new FireStoreUtils();

  Future<User> getPointsUser(String userID) async {
    User user = new User();
    var points = 0;
    await firestore.collection(USERS).document(userID).get().then((value) {
      print(value.data["points"]);
      if (value.data["points"] != null) {
        points = value.data["points"];

        assert(points is int);
        user.points = value.data["points"];
        MyAppState.currentUser.points = value.data["points"];
      }
    });

    return user;
  }

  Future<bool> checkNameGroup(String nameGroup) async {
    bool isSuccessful = false;
    await firestore
        .collection(CHANNELS)
        .where('name', isEqualTo: nameGroup)
        .getDocuments()
        .then((value1) {
      if (value1.documents.isEmpty) {
        isSuccessful = true;
      } else if (value1.documents.isNotEmpty) {
        isSuccessful = false;
      }
    });

    return isSuccessful;
  }

  Future<bool> checkUserName(String name) async {
    bool isSuccessful = false;
    await firestore
        .collection(USERS)
        .where('name', isEqualTo: name)
        .getDocuments()
        .then((value1) {
      if (value1.documents.isEmpty) {
        isSuccessful = true;
      } else if (value1.documents.isNotEmpty) {
        isSuccessful = false;
      }
    });

    return isSuccessful;
  }

  Future<User> login(String name, String password1) async {
    User user;
    String password2;
    await firestore
        .collection(USERS)
        .where('name', isEqualTo: name)
        .getDocuments()
        .then((value1) async {
      if (value1.documents.isNotEmpty) {
        User userTemp = User.fromJson(value1.documents.first.data);
        password2 = userTemp.password;
        if (password1 == password2) {
          user = userTemp;
          MyAppState.currentUser = user;
        }
      }
    });

    return user;
  }

  Future<UserTimeServer> createUser(
      UserTimeServer user, String password) async {
    UserTimeServer userTemp = new UserTimeServer();

    DocumentReference userDoc = firestore.collection(USERS).document();
    user.userID = userDoc.documentID;

    print(userDoc.documentID);
    await userDoc.setData(user.toJson()).then((onValue) async {
      SharedPreferences shard = await SharedPreferences.getInstance();
      shard.setString("userID", user.userID);
    });
    return userTemp;
  }

  Future<UserArabic> createUserArabic(UserArabic user, String password) async {
    UserArabic userTemp = new UserArabic();

    DocumentReference userDoc = firestore.collection(USERS).document();
    userTemp.userID = userDoc.documentID;
    userTemp.points = user.points;
    userTemp.active = user.active;
    userTemp.color = user.color;
    userTemp.createdAt = user.createdAt;
    userTemp.name = user.name;
    userTemp.password = password;
    userTemp.about = user.about;
    userTemp.country = user.country;
    userTemp.typeUser = user.typeUser;
    userTemp.merchantID = MyAppState.currentUser.userID;
    userTemp.gender = user.gender;
    userTemp.phone = user.phone;
    userTemp.settings = user.settings;
    userTemp.associatedEmail = user.associatedEmail;
    userTemp.profilePictureURL = user.profilePictureURL;
    print(userDoc.documentID);
    await userDoc.setData(userTemp.toJson()).then((onValue) async {
      //MyAppState.currentUser = userTemp;
      //SharedPreferences shard = await SharedPreferences.getInstance();
      // shard.setString("userID", userTemp.userID);
    });
    return userTemp;
  }

  Future<bool> paymentPoints(int cost) async {
    bool isSuccessful = false;
    int newPoint;
    int point = MyAppState.currentUser.points;
    print(" Point : {$point}");
    if (cost <= point) {
      print(" Cost : {$cost}");
      newPoint = point - cost;
      print(" New Point : {$newPoint}");
      if (newPoint < point) {
        await firestore
            .collection(USERS)
            .document(MyAppState.currentUser.userID)
            .updateData({'points': newPoint});
        MyAppState.currentUser.points = newPoint;
        isSuccessful = true;
      } else {
        isSuccessful = false;
      }
    }

    return isSuccessful;
  }

  Future<bool> transferPoints(
      int point, int pointMerchant, int pointUser2, String user2ID) async {
    bool isSuccessful = false;
    int newPointUser2 = pointUser2 + point;
    int newPointMerchant = pointMerchant - point;
    print(" newPointUser2 : {$newPointUser2}");
    print(" newPointMerchant : {$newPointMerchant}");

    if (newPointUser2 > 0 && newPointMerchant >= 0) {
      await firestore
          .collection(USERS)
          .document(MyAppState.currentUser.userID)
          .updateData({'points': newPointMerchant});
      MyAppState.currentUser.points = newPointMerchant;
      await firestore
          .collection(USERS)
          .document(user2ID)
          .updateData({'points': newPointUser2});

      isSuccessful = true;
    } else {
      isSuccessful = false;
    }

    return isSuccessful;
  }

  Future<void> sentNotification(
      String userID2, String nameSender, String type, String message) async {
    await http.post(Constants.URL_HOSTING_API + Constants.URL_PUSH_NOTIFICATION,
        body: {
          "userID2": userID2,
          "nameSender": nameSender,
          "type": type,
          "message": message
        });
    print("userID2 : ${userID2}");
    print("nameSender : ${nameSender}");
    print("type : ${type}");
    print("message : ${message}");
  }

  notification(BuildContext context, String screen) {
    _firebaseMessaging1.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        // alert(context, message['notification']['title'],
        //     message['notification']['body']);
        switch (message['data']['action']) {
          case "NEW_FRIEND_REQUEST":
            Toast.show(message['notification']['body'], context,
                duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
            break;
          case "NEW_MESSAGE":
            if (screen == 'chat') {
            } else {
              Toast.show(message['notification']['body'], context,
                  duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
            }
            break;
        }
      },
    );
  }
}
