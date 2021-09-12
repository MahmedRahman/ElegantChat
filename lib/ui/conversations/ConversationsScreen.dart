import 'package:camera/camera.dart';
import 'package:elegant/ui/services/UserHelper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../constants.dart';
import '../../home.dart';
import '../../model/HomeConversationModel.dart';
import '../../model/User.dart';
import '../../ui/chat/ChatScreen.dart';
import '../../ui/contacts/ContactsScreen.dart';
import '../../ui/services/FirebaseHelper.dart';
import '../../ui/utils/helper.dart';

List<User> _friendsSearchResult = [];
List<HomeConversationModel> _conversationsSearchResult = [];
List<HomeConversationModel> _conversations = [];
List<CameraDescription> cameras;

class ConversationsScreen extends StatefulWidget {
  final User user;

  const ConversationsScreen({Key key, @required this.user}) : super(key: key);

  @override
  State createState() {
    return _ConversationsState(user);
  }
}

class _ConversationsState extends State<ConversationsScreen> {
  final User user;
  final fireStoreUtils = FireStoreUtils();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool showSearch = false;
  Stream<List<HomeConversationModel>> _conversationsStream;
  TextEditingController controller = TextEditingController();
  UserHelper userHelper = new UserHelper();

  _ConversationsState(this.user);

  @override
  void initState() {
    super.initState();
    userHelper.notification(context, '');
    fireStoreUtils.getBlocks().listen((shouldRefresh) {
      if (shouldRefresh) {
        setState(() {});
      }
    });
    _conversationsStream = fireStoreUtils.getConversations(user.userID);
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        if (message['notification']['title'] == "leaveGroup") {
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) =>
                  new ConversationsScreen(user: user)));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(COLOR_PRIMARY),
        onPressed: () => push(context, ContactsScreen(user: user)),
        child: Icon(
          Icons.chat,
          size: 30,
        ),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            showSearch
                ? Padding(
                    padding: const EdgeInsets.only(
                        left: 8, right: 8, top: 8, bottom: 4),
                    child: TextField(
                      onChanged: _onSearch,
                      textAlignVertical: TextAlignVertical.center,
                      controller: controller,
                      textInputAction: TextInputAction.search,
                      textCapitalization: TextCapitalization.words,
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
                          hintText: 'بحث ...',
                          suffixIcon: IconButton(
                            focusColor: Colors.black,
                            iconSize: 20,
                            icon: Icon(Icons.close),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              controller.clear();
                              _onSearch('');
                              setState(() {});
                            },
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                          )),
                    ),
                  )
                : Container(),
            Expanded(
              child: StreamBuilder<List<HomeConversationModel>>(
                stream: _conversationsStream,
                initialData: [],
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // return Container(
                    //   child: Center(
                    //     child: CircularProgressIndicator(
                    //       valueColor: AlwaysStoppedAnimation<Color>(
                    //           Color(COLOR_ACCENT)),
                    //     ),
                    //   ),
                    // );
                    return Container(
                        margin: const EdgeInsets.only(top: 10.0, bottom: 150),
                        child: SizedBox(
                          width: 150,
                          child: new Image.asset("assets/images/logo-chat.png"),
                        ));
                  } else if (!snapshot.hasData ||
                      snapshot.data.isEmpty ||
                      snapshot.data.first.isGroupChat) {
                    return Container(
                        margin: const EdgeInsets.only(top: 10.0, bottom: 150),
                        child: SizedBox(
                          width: 150,
                          child: new Image.asset("assets/images/logo-chat.png"),
                        ));
                  } else {
                    return _conversationsSearchResult.isNotEmpty ||
                            controller.text.isNotEmpty
                        ? ListView.builder(
                            physics: ScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _conversationsSearchResult.length,
                            itemBuilder: (context, index) {
                              final homeConversationModel =
                                  _conversationsSearchResult[index];
                              if (!homeConversationModel.isGroupChat) {
                                return Container(
                                  child: _buildConversationRow(
                                      homeConversationModel),
                                );
                              } else {
                                return fireStoreUtils.validateIfUserBlocked(
                                        homeConversationModel
                                            .members.first.userID)
                                    ? Container(
                                        width: 0,
                                        height: 0,
                                      )
                                    : Container(
                                        child: _buildConversationRow(
                                            homeConversationModel),
                                      );
                              }
                            })
                        : ListView.builder(
                            physics: ScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: snapshot.data.length,
                            itemBuilder: (context, index) {
                              _conversations = snapshot.data;
                              final homeConversationModel =
                                  snapshot.data[index];
                              if (homeConversationModel.isGroupChat) {
                                return Container(
                                  child: _buildConversationRow(
                                      homeConversationModel),
                                );
                              } else {
                                return fireStoreUtils.validateIfUserBlocked(
                                        homeConversationModel
                                            .members.first.userID)
                                    ? Container(
                                        width: 0,
                                        height: 0,
                                      )
                                    : Container(
                                        child: _buildConversationRow(
                                            homeConversationModel),
                                      );
                              }
                            });
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildConversationRow(HomeConversationModel homeConversationModel) {
    String user1Image = '';
    String user2Image = '';
    if (homeConversationModel.members.length >= 2) {
      user1Image = homeConversationModel.members.first.profilePictureURL;
      user2Image = homeConversationModel.members.elementAt(1).profilePictureURL;
    }
    return homeConversationModel.isGroupChat
        ? ListTile(
            // onTap: () {
            //   push(context,
            //       ChatGroup(homeConversationModel: homeConversationModel));
            // },
            leading: Stack(
              //overflow: Overflow.visible,
              children: <Widget>[
                displayCircleImage(user1Image, 40, false),
                Positioned(
                    left: -8,
                    bottom: -8,
                    child: displayCircleImage(user2Image, 40, true))
              ],
            ),
            title: Text(
              '${homeConversationModel.conversationModel.name}',
              style: TextStyle(fontSize: 12),
            ),
            subtitle:
                Text('${homeConversationModel.conversationModel.lastMessage}'),
          )
        : Card(
            child: Column(
            children: <Widget>[
              ListTile(
                onTap: () {
                  push(context,
                      ChatScreen(homeConversationModel: homeConversationModel));
                },
                onLongPress: () {
                  deleteConversation(
                      homeConversationModel.conversationModel.id);
                },
                leading: displayCircleImage(
                    homeConversationModel.members.first.profilePictureURL,
                    44,
                    false),
                title: Text(
                  '${homeConversationModel.members.first.fullName()}',
                  style: TextStyle(fontSize: 15),
                ),
                subtitle: Text(
                    '${homeConversationModel.conversationModel.lastMessage}',
                    style: TextStyle(fontSize: 12)),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    (homeConversationModel.conversationModel.msgCount -
                                homeConversationModel.readCount) >
                            0
                        ? Container(
                            padding: EdgeInsets.only(
                                left: 8, right: 8, top: 4, bottom: 4),
                            margin: EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: Color(COLOR_SECONDARY),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${homeConversationModel.conversationModel.msgCount - homeConversationModel.readCount}",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        : Container(width: 0),
                  ],
                ),
              ),
            ],
          ));
  }

  _onSearch(String text) async {
    _friendsSearchResult.clear();
    _conversationsSearchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    _conversations.forEach((conversation) {
      if (conversation.members.first
          .fullName()
          .toLowerCase()
          .contains(text.toLowerCase())) {
        _conversationsSearchResult.add(conversation);
      }
    });
    setState(() {});
  }

  void deleteConversation(String id) {
    showDialog(
        context: context,
        builder: (context) {
          return Center(
              child: SingleChildScrollView(
                  child: Dialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 16,
                      child: Container(
                        height: 150,
                        width: 350,
                        child: Padding(
                            padding: const EdgeInsets.only(
                                top: 20.0, left: 16, right: 16, bottom: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "حذف الدردشة",
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('إلغاء')),
                                    TextButton(
                                        onPressed: () async {
                                          bool isSuccessful =
                                              await fireStoreUtils
                                                  .deleteConversation(id);
                                          _conversationsStream = fireStoreUtils
                                              .getConversations(user.userID);

                                          if (isSuccessful) {
                                            Navigator.pop(context);
                                            pushReplacement(
                                                context,
                                                new Home(
                                                    cameras: cameras,
                                                    user: user));
                                          }
                                        },
                                        child: Text('تأكيد',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ))),
                                  ],
                                )
                              ],
                            )),
                      ))));
        });
  }
}
