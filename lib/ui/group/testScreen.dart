import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/main.dart';
import 'package:elegant/model/ChannelModel.dart';
import 'package:elegant/ui/chat/ChatGroup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:toast/toast.dart';

import '../../constants.dart';
import '../../model/HomeConversationModel.dart';
import '../../model/User.dart';
import '../services/FirebaseHelper.dart';
import '../utils/helper.dart';

List<ChannelModel> _contacts = [];

class TestScreen extends StatefulWidget {
  final User user;

  const TestScreen({Key key, @required this.user}) : super(key: key);

  @override
  _TestScreenState createState() => _TestScreenState(user);
}

class _TestScreenState extends State<TestScreen> {
  final User user;
  bool showSearchBar = false;
  final fireStoreUtils = FireStoreUtils();
  static Firestore firestore = Firestore.instance;

  _TestScreenState(this.user);

  List<ChannelModel> groupList = [];
  Future<List<ChannelModel>> _future;

  FireStoreUtils _fireStoreUtils = FireStoreUtils();

  @override
  void initState() {
    super.initState();

    MyAppState.currentUser.refresh = true;

    this.refresh();
  }

  refresh() {
    setState(() {
      // contact = null;
      groupList.clear();
    });

    _future = groupUserActive();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Color(COLOR_PRIMARY),
      //   onPressed: () => push(context, SearchScreen(user: user)),
      //   child: Icon(
      //     Icons.group_add,
      //     size: 30,
      //   ),
      // ),
      body: Column(
        children: <Widget>[
          Padding(padding: EdgeInsets.all(2.0)),
          FutureBuilder<List<ChannelModel>>(
            future: _future,
            initialData: [],
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Expanded(
                  child: Container(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(COLOR_ACCENT),
                        ),
                      ),
                    ),
                  ),
                );
              } else if (!snap.hasData || snap.data.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Text(
                      'ليس لديك أي غرف نشطة',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                );
              } else {
                return Expanded(
                  child: ListView.builder(
                    itemCount: snap.hasData ? snap.data.length : 0,
                    itemBuilder: (BuildContext context, int index) {
                      if (snap.hasData) {
                        _contacts = snap.data.cast<ChannelModel>();
                        ChannelModel contact = snap.data[index];
                        return Card(
                            child: Column(
                          children: <Widget>[
                            ListTile(
                              onTap: () async {
                                String id = MyAppState.currentUser.userID;
                                String groupID = contact.id;
                                print("groupID ${groupID}");
                                await firestore
                                    .collection(CHANNEL_PARTICIPATION)
                                    .where('channel', isEqualTo: contact.id)
                                    .where('user', isEqualTo: id)
                                    .getDocuments()
                                    .then((querysnapShot) {
                                  querysnapShot.documents.forEach((doc) async {
                                    if (doc.data.isNotEmpty) {
                                      HomeConversationModel
                                          groupChatConversationModel =
                                          await _fireStoreUtils.enterGroupChat(
                                              user, groupID);

                                      if (groupChatConversationModel.active ==
                                          true) {
                                        push(
                                            context,
                                            ChatGroup(
                                                homeConversationModel:
                                                    groupChatConversationModel));
                                      } else {
                                        Toast.show(
                                            "لقد غادرت هذه الفرفة منذ قليل",
                                            context,
                                            duration: Toast.LENGTH_LONG,
                                            gravity: Toast.BOTTOM);
                                      }
                                    } else {
                                      Toast.show(
                                          "يرجى المحاولة لاحقاَ", context,
                                          duration: Toast.LENGTH_LONG,
                                          gravity: Toast.BOTTOM);
                                    }
                                  });
                                });
                              },
                              leading: Image.asset(
                                "assets/images/logo-chat.png",
                                width: 50,
                              ),
                              title: Text('${contact.name}'),
                              subtitle: Text(
                                contact.description.length > 50
                                    ? contact.description.substring(0, 50)
                                    : contact.description,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
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
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<List<ChannelModel>> groupUserActive() async {
    groupList.clear();
    firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('user', isEqualTo: MyAppState.currentUser.userID)
        .where('active', isEqualTo: true)
        .snapshots()
        .listen((onData) async {
      onData.documents.forEach((document) async {
        if (document.data.isNotEmpty) {
          firestore
              .collection(CHANNELS)
              .where('id', isEqualTo: document.data["channel"])
              .getDocuments()
              .then((onValue) {
            onValue.documents.asMap().forEach((index, group) {
              ChannelModel c = ChannelModel.fromJson(group.data);
              print(c.id);
              if (c.id != null) {
                groupList.removeWhere((GroupModelToDelete) {
                  return c.id == GroupModelToDelete.id;
                });
                if(mounted){
                setState(() {
                  groupList.add(c);
                });
              }
              }
              print(c.name);
            });
          });
        }
      });
    });
    return groupList;
  }
}
