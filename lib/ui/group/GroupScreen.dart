import 'package:avatar_letter/avatar_letter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/model/HomeConversationModel.dart';
import 'package:elegant/ui/services/ChatHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:toast/toast.dart';

import '../../constants.dart';
import '../../constants.dart' as Constants;
import '../../main.dart';
import '../../model/GroupModel.dart';
import '../../model/User.dart';
import '../chat/ChatGroup.dart';
import '../services/FirebaseHelper.dart';
import '../utils/helper.dart';

class ConversationsGroupScreen extends StatefulWidget {
  final User user;
  final String type;

  const ConversationsGroupScreen({Key key, @required this.user, this.type})
      : super(key: key);

  @override
  State createState() {
    return _ConversationsGroupState(user);
  }
}

class _ConversationsGroupState extends State<ConversationsGroupScreen> {
  final User user;
  final fireStoreUtils = FireStoreUtils();
  bool showSearch = false;
  Stream _conversationsStream;
  List<GroupModel> _conversations = [];
  TextEditingController controller = TextEditingController();
  FireStoreUtils _fireStoreUtils = FireStoreUtils();

  _ConversationsGroupState(this.user);

  Firestore fireStore = Firestore.instance;
  ChatHelper _chatHelper = new ChatHelper();

  @override
  Future<void> initState() {
    super.initState();
    _conversationsStream = fireStoreUtils.getConversations3();
    if (widget.type == "public") {
      setState(() {
        //  _conversationsStream = fireStoreUtils.getConversations3();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: <Widget>[
        widget.type == "public"
            ? Expanded(
                child: StreamBuilder<List<GroupModel>>(
                stream: _conversationsStream,
                initialData: [],
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.data == null &&
                      snapshot.connectionState == ConnectionState.done) {
                    return Center(
                      child: Text('يرجى المحاولة لاحقاً '),
                    );
                  } else {
                    return snapshot.data.length != 0
                        ? ListView.builder(
                            physics: ScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: snapshot.data.length,
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 3,
                                child: ListTile(
                                    leading:
                                        //Icon(Icons.vpn_lock_sharp),

                                        AvatarLetter(
                                      size: 50,
                                      backgroundColor:
                                          Color(Constants.COLOR_PRIMARY),
                                      textColor: Colors.white,
                                      fontSize: 20,
                                      upperCase: true,
                                      numberLetters: 1,
                                      letterType: LetterType.Circular,
                                      text: snapshot.data[index].name != null
                                          ? snapshot.data[index].name
                                          : "e",
                                    ),
                                    onTap: () async {
                                      String id = MyAppState.currentUser.userID;
                                      bool isBocked = await isBlocked(
                                          id, snapshot.data[index].id);
                                      if (!isBocked) {
                                        showProgress(
                                            context, 'الرجاء الانتظار', false);

                                        bool s = await cc(
                                            id, snapshot.data[index].id);
                                        if (s) {
                                          HomeConversationModel
                                              groupChatConversationModel =
                                              await _fireStoreUtils
                                                  .enterGroupChat(user,
                                                      snapshot.data[index].id);
                                          hideProgress();
                                          if (groupChatConversationModel
                                                  .active ==
                                              false) {
                                            if (snapshot.data[index]
                                                    .currentNumberMembers <=
                                                snapshot.data[index]
                                                    .numberOfMembers) {
                                              push(
                                                  context,
                                                  ChatGroup(
                                                      homeConversationModel:
                                                          groupChatConversationModel));
                                              _chatHelper.sendNotifyMessage(
                                                  groupChatConversationModel,
                                                  "انضم الى الغرفة");
                                            } else {
                                              Toast.show("العدد مكتمل", context,
                                                  duration: Toast.LENGTH_SHORT,
                                                  gravity: Toast.CENTER);
                                            }
                                          } else {
                                            push(
                                                context,
                                                ChatGroup(
                                                    homeConversationModel:
                                                        groupChatConversationModel));
                                          }
                                        } else {
                                          if (snapshot.data[index]
                                                  .currentNumberMembers <=
                                              snapshot.data[index]
                                                  .numberOfMembers) {
                                            HomeConversationModel
                                                groupChatConversationModel =
                                                await _fireStoreUtils
                                                    .joinGroupChat(
                                                        user,
                                                        snapshot
                                                            .data[index].id);
                                            hideProgress();
                                            push(
                                                context,
                                                ChatGroup(
                                                    homeConversationModel:
                                                        groupChatConversationModel));
                                            _chatHelper.sendNotifyMessage(
                                                groupChatConversationModel,
                                                "انضم الى الغرفة");

                                            print("NO");
                                          } else {
                                            hideProgress();
                                            Toast.show("العدد مكتمل", context,
                                                duration: Toast.LENGTH_SHORT,
                                                gravity: Toast.CENTER);
                                          }
                                        }
                                      } else {
                                        hideProgress();
                                        Toast.show(
                                            "تم حظر دخولك لهذه الغرفة", context,
                                            duration: Toast.LENGTH_SHORT,
                                            gravity: Toast.CENTER);
                                      }
                                    },
                                    title: Text(snapshot.data[index].name),
                                    subtitle: Text(
                                      snapshot.data[index].description.length >
                                              50
                                          ? snapshot.data[index].description
                                              .substring(0, 50)
                                          : snapshot.data[index].description,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(Icons.group),
                                          Padding(
                                              padding: const EdgeInsets.all(2)),
                                          Text(
                                            "(" +
                                                snapshot
                                                    .data[index].numberOfMembers
                                                    .toString() +
                                                "/" +
                                                snapshot.data[index]
                                                    .currentNumberMembers
                                                    .toString() +
                                                ")",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ])),
                              );
                            })
                        : Container();
                  }
                },
              ))
            : Container()
      ]),
    );
  }

  Future<bool> cc(String userID, String channelID) async {
    bool isSuccessful;

    await fireStore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: channelID)
        .where('user', isEqualTo: userID)
        .getDocuments()
        .then((querySnapShot) async {
      if (querySnapShot.documents.isNotEmpty) {
        isSuccessful = true;
      } else {
        isSuccessful = false;
      }
    });

    return isSuccessful;
  }

  Future<bool> isBlocked(String userID, String channelID) async {
    bool isSuccessful;

    await fireStore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: channelID)
        .where('user', isEqualTo: userID)
        .getDocuments()
        .then((querySnapShot) async {
      if (querySnapShot.documents.isNotEmpty &&
          querySnapShot.documents.first.data['block'] == true) {
        isSuccessful = true;
      } else {
        isSuccessful = false;
      }
    });

    return isSuccessful;
  }
}
