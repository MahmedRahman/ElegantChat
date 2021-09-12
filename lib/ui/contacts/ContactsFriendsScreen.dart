import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/main.dart';
import 'package:elegant/model/Friendship.dart';
import 'package:elegant/ui/account/ProfileScreen.dart';
import 'package:elegant/ui/services/UserHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../constants.dart' as Constants;
import '../../constants.dart' ;

import '../../model/User.dart';
import '../../ui/chat/ChatScreen.dart';
import '../../ui/services/FirebaseHelper.dart';
import '../../ui/utils/helper.dart';
import 'SearchScreen.dart';

List<User> _searchResult = [];

List<User> _contacts = [];

class FriendsContactsScreen extends StatefulWidget {
  final User user;

  const FriendsContactsScreen({Key key, @required this.user}) : super(key: key);

  @override
  _FriendsContactsScreenState createState() =>
      _FriendsContactsScreenState(user);
}

class _FriendsContactsScreenState extends State<FriendsContactsScreen> {
  final User user;
  bool showSearchBar = false;
  TextEditingController controller = TextEditingController();
  final fireStoreUtils = FireStoreUtils();
  static Firestore firestore = Firestore.instance;
  _FriendsContactsScreenState(this.user);

  Future<List<User>> _future;
  UserHelper userHelper = new UserHelper();
  List<User> userList = [];


  @override
  void initState() {
    super.initState();
     userHelper.notification(context, 'FriendsContactsScreen');
    fireStoreUtils.getBlocks().listen((shouldRefresh) {
      if (shouldRefresh) {
        setState(() {});
      }
    });
    MyAppState.currentUser.searchBar = false;
    MyAppState.currentUser.refresh = true;
    if (MyAppState.currentUser.searchBar == true) {
      showSearchBar = !showSearchBar;
    }
    if (MyAppState.currentUser.refreshClick == true) {
      setState(() {
        MyAppState.currentUser.refreshClick = false;
        this.refresh();
      });
    }
    this.refresh();
    refresh();
    setState(() {});
  }

  refresh() {
    _future =  getMyFriends(user.userID, false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("الاصدقاء"),
        backgroundColor: Color(Constants.COLOR_PRIMARY),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(COLOR_PRIMARY),
        onPressed: () => push(context, SearchScreen(user: user)),
        child: Icon(
          Icons.group_add,
          size: 30,
        ),
      ),
      body: Container(
  
        child: Column(
          children: <Widget>[
            MyAppState.currentUser.searchBar == true
                ? Padding(
                    padding: const EdgeInsets.only(
                        left: 8, right: 8, top: 8, bottom: 4),
                    child: TextField(
                      controller: controller,
                      onChanged: _onSearchTextChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(0),
                          isDense: true,
                          fillColor: Colors.grey[200],
                          filled: true,
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(360),
                              ),
                              borderSide: BorderSide(style: BorderStyle.none)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(360),
                              ),
                              borderSide: BorderSide(style: BorderStyle.none)),
                          hintText: 'ابحث ضمن اصدقاءك',
                          suffixIcon: IconButton(
                            iconSize: 20,
                            icon: Icon(Icons.close),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              controller.clear();
                              _onSearchTextChanged('');
                            },
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                          )),
                    ),
                  )
                : Container(),
            Padding(padding: EdgeInsets.all(3.0)),
            FutureBuilder<List<User>>(
              future: _future,
              initialData: [],
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Expanded(
                    child: Container(
                      // child: Center(
                      //   child: CircularProgressIndicator(
                      //     valueColor: AlwaysStoppedAnimation<Color>(
                      //       Color(COLOR_ACCENT),
                      //     ),
                      //   ),
                      // ),
                    ),
                  );
                } else if (!snap.hasData || snap.data.isEmpty) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        '',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                } else {
                  return Expanded(
                    child: _searchResult.length != 0 || controller.text.isNotEmpty
                        ? ListView.builder(
                            itemCount: _searchResult.length,
                            itemBuilder: (context, index) {
                              User contact = _searchResult[index];
                              return ListTile(
                                onTap: () async {

                                },
                                leading: displayCircleImage(
                                    contact.profilePictureURL, 48, false),
                                title: Text(
                                  '${contact.fullName()}',
                                  style: TextStyle(fontSize: 12),
                                ),
                                //  subtitle: Text(contact.user.about.length>50? contact.user.about.substring(0,50):contact.user.about),

                                //subtitle: Text('${contact.user.about}'),
                                trailing: RaisedButton(
                                  elevation: 0,
                                  onPressed: () async {
                                    bool result = await _onContactButtonClicked(
                                        contact, index, true);
                                    if (result) {
                                      hideProgress();
                                      setState(() {});
                                    } else {
                                      hideProgress();
                                      showAlertDialog(
                                          context,
                                          'Couldn\'t Process',
                                          'Some Error occured');
                                    }
                                  },

                                ),
                              );
                            })
                        : ListView.builder(
                            itemCount: snap.hasData ? snap.data.length : 0,
                            itemBuilder: (BuildContext context, int index) {
                              if (snap.hasData) {
                                _contacts = snap.data;
                                User contact = snap.data[index];
                                return Card(
                                    child: Column(
                                  children: <Widget>[
                                    ListTile(
                                      onTap: () async {
                                        Navigator.of(context).push(MaterialPageRoute(
                                            builder: (BuildContext context) => new ProfileScreen(
                                                user1: MyAppState.currentUser, user2: contact)));
                                      },
                                      leading:
                                      Stack(
                                          alignment: Alignment.topLeft,
                                          children: <Widget>[

                                      CircleAvatar(
                                        backgroundImage: NetworkImage(
                                            contact.profilePictureURL),
                                      ),
                                            Positioned(
                                                left: 1,
                                                bottom: 0,
                                                child: Container(
                                                  width: 4,

                                                  child: Icon(
                                                    contact.active? Icons.check_circle_rounded : Icons.check_circle_rounded,
                                                     color:  contact.active? Colors.green : Colors.black54 ,

                                                       ),
                                                )),
                                      ],
                                      ),
                                      title: Text(
                                        '${contact.fullName()}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      // subtitle: Text('${contact.user.about}'),
                                      trailing: RaisedButton(
                                        elevation: 0,
                                        color: Colors.grey[200],
                                        onPressed: () async {
                                          bool result = await _onContactButtonClicked(
                                              contact, index, false);
                                          if (result) {
                                            hideProgress();
                                            setState(() {});
                                          } else {
                                            hideProgress();
                                            showAlertDialog(
                                                context,
                                                'Couldn\'t Process',
                                                'Some Error occured');
                                          }
                                        },
                                        child: Text(
                                          "الغاء الصداقة",
                                          style: TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    )
                                  ],
                                ));
                              } else {
                                return Container();
                              }
                            },
                          ),
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }

  _onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }
    _contacts.forEach((contact) {
      if (contact.fullName().toLowerCase().contains(text.toLowerCase())) {
        _searchResult.add(contact);
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    _searchResult.clear();
    super.dispose();
  }

  Future<bool> _onContactButtonClicked(
      User contact, int index, bool fromSearch) async {
    bool isSuccessful = false;

        showProgress(context, 'ازالة الصداقة', false);
        isSuccessful =
        await fireStoreUtils.onUnFriend(contact, user.userID, false);
        if (isSuccessful) {
          if (!fromSearch) {
            _contacts.removeAt(index);


          } else {
            _searchResult.removeAt(index);
            _contacts
                .removeWhere((item) => item.userID == contact.userID);
          }


    }
    return isSuccessful;
  }
  Future<List<User>> getMyFriends(
      String userID, bool searchScreen) async {
userList.clear();
    await firestore
        .collection(FRIENDSHIP)
        .where('user1', isEqualTo: userID)
        .getDocuments()
        .then((querysnapShot) {
      querysnapShot.documents.forEach((doc) async {
        Friendship friendship = Friendship.fromJson(doc.data);
        print(friendship.id);
        if (friendship.id.isNotEmpty ) {
          User u = await getUser(friendship.user2);
          setState(() {
            if (u.userID != null) {
              userList.removeWhere((UserToDelete) {
                return   friendship.user2== UserToDelete.userID;
              });
              setState(() {
                userList.add(u);
              });
            }

            print(u.name);
          });
        }

      });
    });
    await firestore
        .collection(FRIENDSHIP)
        .where('user2', isEqualTo: userID)
        .getDocuments()
        .then((querysnapShot) {
      querysnapShot.documents.forEach((doc) async {
        Friendship friendship = Friendship.fromJson(doc.data);
        print(friendship.id);
        if (friendship.id.isNotEmpty ) {
          User u = await getUser(friendship.user1);
          setState(() {
            if (u.userID != null) {
              userList.removeWhere((UserToDelete) {
                return friendship.user1 == UserToDelete.userID;
              });
              setState(() {
                userList.add(u);
              });
            }

            print(u.name);
          });
        }

      });
    });
    return userList ;
  }
 
 
 
  Future<User> getUser(String userID) async {
    DocumentSnapshot userDocument =
    await firestore.collection(USERS).document(userID).get();
    if (userDocument != null && userDocument.exists) {
      return User.fromJson(userDocument.data);
    } else {
      return null;
    }
  }
}
