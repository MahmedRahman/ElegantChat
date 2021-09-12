import 'package:avatar_letter/avatar_letter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/model/GroupModel.dart';
import 'package:elegant/model/HomeConversationModel.dart';
import 'package:elegant/ui/chat/ChatGroup.dart';
import 'package:elegant/ui/services/ChatHelper.dart';
import 'package:elegant/ui/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

import '../../constants.dart' as Constants;
import '../../constants.dart';
import '../../main.dart';
import '../../model/User.dart';
import '../../ui/services/FirebaseHelper.dart';

List<GroupModel> _searchResult = [];

class SearchGroupScreen extends StatefulWidget {
  final User user;

  const SearchGroupScreen({Key key, @required this.user}) : super(key: key);

  @override
  _SearchGroupScreenState createState() => _SearchGroupScreenState(user);
}

class _SearchGroupScreenState extends State<SearchGroupScreen> {
  final User user;
  TextEditingController controller = TextEditingController();
  final fireStoreUtils = FireStoreUtils();
  bool isSearching = false;
  FireStoreUtils _fireStoreUtils = FireStoreUtils();

  _SearchGroupScreenState(this.user);

  Firestore firestore = Firestore.instance;
  ChatHelper _chatHelper = new ChatHelper();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 4),
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
                  hintText: 'البحث',
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
          ),
          Expanded(
            child: _searchResult.length != 0
                ? ListView.builder(
                    itemCount: _searchResult.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: AvatarLetter(
                          size: 50,
                          backgroundColor: Color(Constants.COLOR_PRIMARY),
                          textColor: Colors.white,
                          fontSize: 20,
                          upperCase: true,
                          numberLetters: 1,
                          letterType: LetterType.Circular,
                          text: _searchResult[index].name != null
                              ? _searchResult[index].name
                              : "e",
                        ),
                        onTap: () async {
                          String id = MyAppState.currentUser.userID;
                          bool isBocked =
                              await isBlocked(id, _searchResult[index].id);
                          if (!isBocked) {
                            int documents;
                            QuerySnapshot qSnap = await firestore
                                .collection(CHANNEL_PARTICIPATION)
                                .where('channel',
                                    isEqualTo: _searchResult[index].id)
                                .where('active', isEqualTo: true)
                                .getDocuments();

                            documents = qSnap.documents.length;

                            documents != null
                                ? showDialog(
                                    context: context,
                                    builder: (context) {
                                      return Center(
                                          child: SingleChildScrollView(
                                              child: Dialog(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                  elevation: 16,
                                                  child: Container(
                                                    height: 150,
                                                    width: 350,
                                                    child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                top: 20.0,
                                                                left: 16,
                                                                right: 16,
                                                                bottom: 16),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: <Widget>[
                                                            Text(
                                                              _searchResult[
                                                                      index]
                                                                  .name,
                                                              style: TextStyle(
                                                                  fontSize: 16),
                                                            ),
                                                            Text(
                                                              "(" +
                                                                  _searchResult[
                                                                          index]
                                                                      .numberOfMembers
                                                                      .toString() +
                                                                  "/" +
                                                                  documents
                                                                      .toString() +
                                                                  ")",
                                                              style: TextStyle(
                                                                  fontSize: 12),
                                                            ),
                                                            SizedBox(
                                                                height: 16),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceEvenly,
                                                              children: <
                                                                  Widget>[
                                                                TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                            context),
                                                                    child: Text(
                                                                        'إلغاء')),
                                                                TextButton(
                                                                    onPressed:
                                                                        () async {
                                                                      showProgress(
                                                                          context,
                                                                          'الرجاء الانتظار',
                                                                          false);
                                                                      String id = MyAppState
                                                                          .currentUser
                                                                          .userID;

                                                                      bool s = await cc(
                                                                          id,
                                                                          _searchResult[index]
                                                                              .id);
                                                                      if (s) {
                                                                        HomeConversationModel
                                                                            groupChatConversationModel =
                                                                            await _fireStoreUtils.enterGroupChat(user,
                                                                                _searchResult[index].id);
                                                                        hideProgress();
                                                                        push(
                                                                            context,
                                                                            ChatGroup(homeConversationModel: groupChatConversationModel));
                                                                        if (groupChatConversationModel.active ==
                                                                            false) {
                                                                          _chatHelper.sendNotifyMessage(
                                                                              groupChatConversationModel,
                                                                              "انضم الى الغرفة");
                                                                        }

                                                                        print(
                                                                            "YES");
                                                                      } else {
                                                                        HomeConversationModel
                                                                            groupChatConversationModel =
                                                                            await _fireStoreUtils.joinGroupChat(user,
                                                                                _searchResult[index].id);
                                                                        hideProgress();
                                                                        push(
                                                                            context,
                                                                            ChatGroup(homeConversationModel: groupChatConversationModel));
                                                                        _chatHelper.sendNotifyMessage(
                                                                            groupChatConversationModel,
                                                                            "انضم الى الغرفة");

                                                                        print(
                                                                            "NO");
                                                                      }
                                                                    },
                                                                    child: Text(
                                                                        'انضمام',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ))),
                                                              ],
                                                            )
                                                          ],
                                                        )),
                                                  ))));
                                    })
                                : Container();
                          } else {
                            //hideProgress();
                            Toast.show("تم حظر دخولك لهذه الغرفة", context,
                                duration: Toast.LENGTH_SHORT,
                                gravity: Toast.CENTER);
                          }
                        },
                        title: Text(_searchResult[index].name),
                        subtitle: Text(
                          _searchResult[index].description.length > 50
                              ? _searchResult[index]
                                  .description
                                  .substring(0, 50)
                              : _searchResult[index].description,
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: Icon(Icons.saved_search),
                      );
                    })
                : Container(
                    child: Center(
                      child: isSearching
                          ? CircularProgressIndicator()
                          : Container(
                              child: controller.text.length != 0
                                  ? Text(" لا توجد نتائج ${controller.text}")
                                  : Text("ابدأ بالبحث"),
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<bool> cc(String userID, String channelID) async {
    bool isSuccessful;

    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: channelID)
        .where('user', isEqualTo: userID)
        .getDocuments()
        .then((querysnapShot) async {
      if (querysnapShot.documents.isNotEmpty) {
        isSuccessful = true;
      } else {
        isSuccessful = false;
      }
    });

    return isSuccessful;
  }

  Future<bool> isBlocked(String userID, String channelID) async {
    bool isSuccessful;

    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: channelID)
        .where('user', isEqualTo: userID)
        .getDocuments()
        .then((querysnapShot) async {
      if (querysnapShot.documents.isNotEmpty &&
          querysnapShot.documents.first.data['block'] == true) {
        isSuccessful = true;
      } else {
        isSuccessful = false;
      }
    });

    return isSuccessful;
  }

  _onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    setState(() => isSearching = true);

    fireStoreUtils.searchGroup(text).then((contact) {
      if (contact.length > 0) {
        contact.forEach((element) async {
          _searchResult.add(element);
        });
        setState(() {
          _searchResult = _searchResult;
          isSearching = false;
        });
      } else {
        setState(() {
          _searchResult = [];
          isSearching = false;
        });
      }
    }).catchError((e) {
      print(e);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _searchResult.clear();
    super.dispose();
  }
}
