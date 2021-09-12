import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/constants.dart';
import 'package:elegant/main.dart';
import 'package:elegant/model/User.dart';
import 'package:elegant/ui/services/FirebaseHelper.dart';
import 'package:elegant/ui/services/UserHelper.dart';
import 'package:elegant/ui/utils/helper.dart';
import 'package:flutter/material.dart';

import 'ContactsBlockedScreen.dart';
import 'ContactsFriendsScreen.dart';
import 'FriendshipRequests.dart';
import 'FriendshipRequestsSend.dart';

Firestore firestore = Firestore.instance;
FireStoreUtils _fireStoreUtils = FireStoreUtils();
UserHelper _userHelper = new UserHelper();
String idStudent = '';
String idSchool = '';

class FreindsScreen extends StatefulWidget {
  @override
  _FreindsScreenState createState() => _FreindsScreenState();
}

class _FreindsScreenState extends State<FreindsScreen> {
  var friendsCount = '0';

  @override
  void initState() {
    getMyFriends(user.userID, false);

    super.initState();
  }

  Future<String> getMyFriends(String userID, bool searchScreen) async {
    await firestore
        .collection(FRIENDSHIP)
        .where('user2', isEqualTo: userID)
        .getDocuments()
        .then((querysnapShot) {
      setState(() {
        friendsCount = querysnapShot.documents.length.toString();
      });
    });
  }

  User user = MyAppState.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          margin: EdgeInsets.all(50),
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: .85,
            crossAxisSpacing: 20,
            mainAxisSpacing: 30,
            children: <Widget>[
              InkWell(
                onTap: () {
                  push(context, FriendsContactsScreen(user: user));
                },
                child: Card(
                  child: Column(children: <Widget>[
                    Padding(padding: EdgeInsets.only(top: 25)),
                    SizedBox(
                      width: 100,
                      child: Icon(
                        Icons.people_outline_sharp,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    Text('$friendsCount أصدقائي'),
                  ]),
                ),
              ),
              InkWell(
                onTap: () {
                  push(context, FriendshipRequestsScreen(user: user));
                },
                child: Card(
                  child: Column(children: <Widget>[
                    Padding(padding: EdgeInsets.only(top: 25)),
                    SizedBox(
                      width: 100,
                      child: Icon(
                        Icons.arrow_circle_down_sharp,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    Text('طلبات واردة'),
                  ]),
                ),
              ),
              InkWell(
                onTap: () {
                  push(context, FriendshipRequestsSendScreen(user: user));
                },
                child: Card(
                  child: Column(children: <Widget>[
                    Padding(padding: EdgeInsets.only(top: 25)),
                    SizedBox(
                      width: 100,
                      child: Icon(
                        Icons.arrow_circle_up_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    Text('طلبات مرسلة'),
                  ]),
                ),
              ),
              InkWell(
                onTap: () {
                  push(context, FriendsBlockedScreen(user: user));
                },
                child: Card(
                  child: Column(children: <Widget>[
                    Padding(padding: EdgeInsets.only(top: 25)),
                    SizedBox(
                      width: 200,
                      child: Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    Text('الحظر'),
                  ]),
                ),
              ),
            ],
          ),
        ));
  }
}
