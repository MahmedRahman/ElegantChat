import 'dart:io';

import 'package:camera/camera.dart';
import 'package:elegant/homeGroup.dart';
import 'package:elegant/main.dart';
import 'package:elegant/ui/Store/StoreScreen.dart';
import 'package:elegant/ui/account/AccountDetailsScreen.dart';
import 'package:elegant/ui/account/UpdateImageAndState.dart';
import 'package:elegant/ui/auth/AuthScreen.dart';
import 'package:elegant/ui/chat/CallReceiverScreen.dart';
import 'package:elegant/ui/contactUs/ContactUsScreen.dart';
import 'package:elegant/ui/contacts/ContactsScreen.dart';
import 'package:elegant/ui/contacts/FreindsScreen.dart';
import 'package:elegant/ui/contacts/SearchScreen.dart';
import 'package:elegant/ui/conversations/ConversationsScreen.dart';
import 'package:elegant/ui/services/FirebaseHelper.dart';
import 'package:elegant/ui/services/UserHelper.dart';
import 'package:elegant/ui/settings/SettingsScreen.dart';
import 'package:elegant/ui/utils/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart' as Constants;
import 'model/CallsModel.dart';
import 'model/User.dart';

class Home extends StatefulWidget {
  final List<CameraDescription> cameras;
  final User user;

  Home({this.cameras, this.user});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  TabController _tabController;
  bool showFab = true;
  bool showSearchBar = false;
  Stream<CallsModel> callsStream;
  FireStoreUtils _fireStoreUtils = FireStoreUtils();
  UserHelper userHelper = new UserHelper();

  @override
  void initState() {
    super.initState();
    userHelper.notification(context, '');
    setupStream();
    _tabController = TabController(vsync: this, initialIndex: 2, length: 4);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        showFab = true;
      } else {
        showFab = false;
      }
      setState(() {});
    });
  }

  setupStream() {
    callsStream = _fireStoreUtils
        .getCalls(context, widget.user.userID)
        .asBroadcastStream();
    callsStream.listen((callModel) {
      if (callModel.status == "wait") {
        push(context, CallReceiverScreen(callModel: callModel));
      } else {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(Constants.COLOR_PRIMARY),
        title: Text("Elegant Chat "),
        elevation: 0.7,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: <Widget>[
            Tab(icon: Icon(Icons.camera_alt)),
            Tab(
                child: Text(
              "الأصدقاء",
              style: TextStyle(fontSize: 13),
            )),
            Tab(
                child: Text(
              "الدردشة",
              style: TextStyle(fontSize: 13),
            )),
            Tab(
                child: Text(
              "الغرف",
              style: TextStyle(fontSize: 13),
            )),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              MyAppState.currentUser.searchBar == true
                  ? setState(() {
                      MyAppState.currentUser.searchBar = false;
                    })
                  : setState(() {
                      MyAppState.currentUser.searchBar = true;
                    });
            },
          ),
          // Visibility(
          //   visible:  MyAppState.currentUser.refresh==true ? true : false,
          //     child:
          // IconButton(
          //   icon: Icon(Icons.refresh),
          //   onPressed: () {
          //    setState(() {
          //      MyAppState.currentUser.refreshClick = true;
          //    });
          //   },
          // ),
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (BuildContext bc) => [
              PopupMenuItem(
                  child: Text(
                    "المساعدة",
                    style: TextStyle(fontSize: 12),
                  ),
                  value: "help"),
              PopupMenuItem(
                  child: Text(
                    "مشاركة",
                    style: TextStyle(fontSize: 12),
                  ),
                  value: "share"),
            ],
            onSelected: (route) {
              switch (route) {
                case "help":
                  push(context, ContactUsScreen());
                  break;
                case "share":
                  Share.share(
                      Constants.INVITE_TEXT + '\n' + Constants.INVITE_URL);
                  break;
              }
            },
          ),
        ],
      ),
      drawer: new Drawer(
        child: new ListView(
          children: <Widget>[
            new ListTile(
                title: new Text("الملف الشخصي"),
                trailing: new Icon(Icons.account_box_outlined),
                onTap: () {
                  Navigator.pop(context);
                  push(context, AccountDetailsScreen(user: widget.user));
                }),
            new ListTile(
                title: new Text("إنشاء غرفة"),
                trailing: new Icon(Icons.message),
                onTap: () {
                  Navigator.pop(context);
                  push(context, ContactsScreen(user: widget.user));
                }),
            new ListTile(
                title: new Text("اضافة أصدقاء"),
                trailing: new Icon(Icons.group_add),
                onTap: () {
                  Navigator.pop(context);
                  push(context, SearchScreen(user: widget.user));
                }),
            new ListTile(
                title: new Text("الاعدادات"),
                trailing: new Icon(Icons.settings),
                onTap: () {
                  Navigator.pop(context);
                  push(context, SettingsScreen(user: widget.user));
                }),
            new Divider(),
            new ListTile(
                title: new Text("المتجر والنقاط"),
                trailing: new Icon(Icons.local_grocery_store),
                onTap: () {
                  Navigator.pop(context);
                  push(context, StoreScreen(user: widget.user));
                }),
            new Divider(),
            new ListTile(
                title: new Text("تسجيل خروج"),
                trailing: new Icon(Icons.exit_to_app),
                onTap: () async {
                  widget.user.active = false;

                  _fireStoreUtils
                      .updateChannelParticipation(widget.user.userID);
                  _fireStoreUtils.updateUser(false, widget.user.userID);
                  MyAppState.currentUser = null;

                  FirebaseUser user = await FirebaseAuth.instance.currentUser();
                  user.delete();

                  await FirebaseAuth.instance.signOut();
                  MyAppState.currentUser = null;
                  pushAndRemoveUntil(context, AuthScreen(), false);
                  SharedPreferences shard =
                      await SharedPreferences.getInstance();
                  shard.clear();
                  pushAndRemoveUntil(context, AuthScreen(), false);
                }),
          ],
        ),
      ),
      body: WillPopScope(
        onWillPop: () {
          return showDialog<bool>(
            context: context,
            barrierDismissible: false, // user must tap button!
            builder: (BuildContext context) {

              return AlertDialog(
                title: const Text('Exit Message'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: const <Widget>[
                      Text('Are you sure you want to exit.'),
                      Text('.'),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Yes'),
                    onPressed: () {
                      exit(0);
                   
                    },
                  ),
                    TextButton(
                    child: const Text('No'),
                    onPressed: () {
                    
                      Navigator.of(context).pop();
                        return true;
                    },
                  ),
                ],
              );
            },
          );
        },
        child: TabBarView(
          controller: _tabController,
          children: <Widget>[
            UpdateImageAndState(user: widget.user),
            FreindsScreen(),
            ConversationsScreen(user: widget.user),
            HomeGroup(user: widget.user),
          ],
        ),
      ),
    );
  }
}

Future<bool> _willPopCallback(BuildContext context) async {
  // await showDialog or Show add banners or whatever
  // then
  _showMyDialog(context); // return true if the route to be popped
}

Future<void> _showMyDialog(BuildContext context) async {}
