import 'package:camera/camera.dart';
import 'package:elegant/ui/Group/GroupScreen.dart';
import 'package:elegant/ui/contacts/ContactsFriendsScreen.dart';
import 'package:elegant/ui/contacts/FriendshipRequests.dart';
import 'package:elegant/ui/group/testScreen.dart';
import 'package:elegant/ui/search/SearchGroupScreen.dart';
import 'package:elegant/ui/services/UserHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'constants.dart' as Constants;
import 'model/User.dart';

class HomeFriends extends StatefulWidget {
  final List<CameraDescription> cameras;
  final User user;

  HomeFriends({this.cameras, this.user});

  @override
  _HomeFriendsState createState() => _HomeFriendsState();
}

class _HomeFriendsState extends State<HomeFriends>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  bool showFab = true;
  bool showSearchBar = false;
  UserHelper userHelper = new UserHelper();

  @override
  void initState() {
    super.initState();

    userHelper.notification(context, '');
    _tabController = TabController(vsync: this, initialIndex: 0, length: 3);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        showFab = true;
      } else {
        showFab = false;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: TabBar(
          controller: _tabController,
          indicatorColor: Color(Constants.COLOR_PRIMARY),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black45,
          indicatorWeight: 5,
          tabs: <Widget>[
            Tab(
                child: Text(
              "الاصدقاء",
              style: TextStyle(fontSize: 13),
            )),
            Tab(
                child: Text(
              "طلبات الصداقة",
              style: TextStyle(fontSize: 13),
            )),
            Tab(
                child: Text(
              "المحظورين",
              style: TextStyle(fontSize: 13),
            )),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          FriendsContactsScreen(user: widget.user),
          FriendshipRequestsScreen(user: widget.user),
          SearchGroupScreen(user: widget.user),
        ],
      ),
    );
  }
}
