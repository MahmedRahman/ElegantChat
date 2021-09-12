import 'dart:async';
import 'dart:io' as io;

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/model/MessageData1.dart';
import 'package:elegant/ui/account/ProfileScreen.dart';
import 'package:elegant/ui/group/MembersActive.dart';
import 'package:elegant/ui/widget/emoji_picker_widget.dart';
import 'package:elegant/ui/widget/input_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:toast/toast.dart';

import '../../constants.dart';
import '../../constants.dart' as Constants;
import '../../main.dart';
import '../../model/ChatModel.dart';
import '../../model/ConversationModel.dart';
import '../../model/HomeConversationModel.dart';
import '../../model/MessageData.dart';
import '../../model/MessageData1.dart';
import '../../model/User.dart';
import '../../ui/Group/InviteFriendsToGroup.dart';
import '../../ui/Group/MembersGroup.dart';
import '../../ui/Group/MembersGroupBlock.dart';
import '../../ui/Group/RoleGroup.dart';
import '../../ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import '../../ui/fullScreenVideoViewer/FullScreenVideoViewer.dart';
import '../../ui/services/FirebaseHelper.dart';
import '../../ui/services/SoundHelper.dart';
import '../../ui/utils/helper.dart';
import '../services/ChatHelper.dart';
import '../services/UserHelper.dart';

class ChatGroup extends StatefulWidget {
  final HomeConversationModel homeConversationModel;

  const ChatGroup({Key key, @required this.homeConversationModel})
      : super(key: key);

  _ChatGroupState createState() => _ChatGroupState(homeConversationModel);
}

class _ChatGroupState extends State<ChatGroup> with WidgetsBindingObserver {
  LinearPercentIndicator linearPercentIndicator;
  final messages = <String>[];
  bool isEmojiVisible = false;
  FocusNode focusNode = FocusNode();
  bool isSendButtonVisible = false;
  bool isKeyboardVisible = false;
  ChatHelper _chatHelper = new ChatHelper();
  int _totalDuration;
  FocusNode myFocusNode;
  int _currentDuration;
  double _completedPercentage = 0.0;
  final HomeConversationModel homeConversationModel;
  TextEditingController _messageController = TextEditingController();
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();
  TextEditingController _groupNameController = TextEditingController();
  bool editDescription = false;
  String _description = "دردشة خاصة";
  UserHelper _userHelper = UserHelper();
  final ScrollController scrollController = new ScrollController();
  bool scrollVisibility = true;
  FlutterAudioRecorder _recorder;

  _ChatGroupState(this.homeConversationModel);

  static Firestore fireStore = Firestore.instance;
  Stream<ChatModel> chatStream;
  int totalMessages = 0;
  SoundHelper helper = new SoundHelper();
  String roleUser;
  final fireStoreUtils = FireStoreUtils();

  @override
  void initState() {
    super.initState();

    _messageController.addListener(toggleButtonKeyboard);
    WidgetsBinding.instance.addObserver(this);
    KeyboardVisibility.onChange.listen((bool isKeyboardVisible) {
      if (this.mounted) {
        setState(() {
          this.isKeyboardVisible = isKeyboardVisible;
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 3000), () {
      setState(() {
        scrollVisibility = false;
      });
    });
    scrollController.addListener(() {
      if (scrollController.position.pixels > 0)
        scrollVisibility = true;
      else
        scrollVisibility = false;

      setState(() {});
    });

    fireStore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: homeConversationModel.conversationModel.id)
        .where('user', isEqualTo: MyAppState.currentUser.userID)
        .getDocuments()
        .then((querySnapShot) {
      querySnapShot.documents.forEach((doc) {
        fireStore
            .collection(CHANNEL_PARTICIPATION)
            .document(querySnapShot.documents.first.documentID)
            .updateData({'active': true, 'expulsion': false});
      });
    });

    fireStoreUtils
        .getStatus(homeConversationModel.conversationModel.id)
        .listen((shouldRefresh) async {
      if (shouldRefresh) {
        Navigator.pop(context);
      }
    });
    _description = homeConversationModel.conversationModel.description;
    if (homeConversationModel.conversationModel.id.isNotEmpty) {}
    _groupNameController.text = homeConversationModel.conversationModel.name;

    setupStream();
  }

  setupStream() {
    chatStream = _fireStoreUtils
        .getChatGroupMessages(homeConversationModel)
        .asBroadcastStream();

    chatStream.listen((chatModel) {
      if (chatModel.message != null) {
        if (homeConversationModel.members != chatModel.members) {
          homeConversationModel.members = chatModel.members;
        }
      }
    });
    if (homeConversationModel.conversationModel != null) {
      if (homeConversationModel.conversationModel.msgCount != null) {
        _fireStoreUtils.updateReadCount(homeConversationModel.participentId,
            homeConversationModel.conversationModel.msgCount);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.arrow_circle_up),
              onPressed: () {
                alertUpdateGroup(
                    context, homeConversationModel.conversationModel.id);
              },
            ),
            IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () {
                _onGroupChatSettingsClick(MyAppState.currentUser.userID);
              },
            )
          ],
          backgroundColor: Color(COLOR_PRIMARY),
          title: Text(homeConversationModel.conversationModel.name)),
      body: Container(
        color: Color(COLOR_BACKGROUND),
        child: Padding(
          padding: const EdgeInsets.only(left: 0.0, right: 0, bottom: 0),
          child: Column(
            children: <Widget>[
              Visibility(
                visible: scrollVisibility,
                child: SizedBox(
                  child: Container(
                    color: Colors.amberAccent,
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text(_description),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: StreamBuilder<ChatModel>(
                      stream: homeConversationModel.conversationModel != null
                          ? chatStream
                          : null,
                      initialData: ChatModel(),
                      builder: (context, snapshot) {
                        totalMessages = snapshot.data.message.length != 0
                            ? snapshot.data.message.length
                            : 1;

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        } else {
                          if (snapshot.hasData &&
                              snapshot.data.message.isEmpty) {
                            return Center(child: Text(''));
                          } else {
                            return ListView.builder(
                                shrinkWrap: true,
                                controller: scrollController,
                                reverse: true,
                                itemCount: snapshot.data.message.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return buildMessage(
                                      snapshot.data.message[index],
                                      snapshot.data.members);
                                });
                          }
                        }
                      }),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 4.0),
              ),
              Container(
                margin: EdgeInsets.only(top: 13),
                color: Colors.white60,
                child: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.only(left: 0.0, right: 0),
                            child: WillPopScope(
                              onWillPop: onBackPress,
                              child: Column(
                                children: <Widget>[
                                  InputWidget(
                                    onBlurred: toggleEmojiKeyboard,
                                    onBlurred2: toggleText,
                                    focusNode: focusNode,
                                    controller: _messageController,
                                    isEmojiVisible: isEmojiVisible,
                                    isSendButtonVisible: isSendButtonVisible,
                                    homeConversationModel:
                                        homeConversationModel,
                                    isKeyboardVisible: isKeyboardVisible,
                                    onSentMessage: (message) => setState(
                                        () => messages.insert(0, message)),
                                  ),
                                  Offstage(
                                    child: EmojiPickerWidget(
                                        onEmojiSelected: onEmojiSelected),
                                    offstage: !isEmojiVisible,
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _onGroupChatSettingsClick(String userID) {
    showModalBottomSheet(
        context: context,
        builder: (bc) {
          return Container(
            child: Wrap(
              children: [
                ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: -8.0, horizontal: 10.0),
                  dense: true,
                  leading: Icon(Icons.star_border),
                  title: Text(
                    "سجل الغرفة",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Visibility(
                  visible: homeConversationModel.role == "admin" ||
                          homeConversationModel.role == "owner"
                      ? true
                      : false,
                  child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          vertical: -8.0, horizontal: 10.0),
                      dense: true,
                      leading: Icon(Icons.edit),
                      title: Text(
                        "تغيير الوصف  ",
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: () async {
                        editGroupDescription(context);
                      }),
                ),
                ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: -8.0, horizontal: 10.0),
                  dense: true,
                  leading: Icon(Icons.exit_to_app),
                  title: Text(
                    "مغادرة الغرفة",
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: () async {
                    // showProgress(context, 'مغادرة الغرفة', false);

                    bool isSuccessful =
                        await _fireStoreUtils.leavingChannelParticipation(
                            userID, homeConversationModel.conversationModel.id);

                    //Navigator.pop(context);
                    if (isSuccessful) {
                      ChatHelper _chatHelper = new ChatHelper();
                      _chatHelper.sendNotifyMessage(
                          homeConversationModel, "غادر");

                      //hideProgress();
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: -8.0, horizontal: 10.0),
                  leading: Icon(Icons.settings),
                  title: Text(
                    "الأدوار والصلاحيات",
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.of(context).push(new MaterialPageRoute(
                        builder: (BuildContext context) => new RoleGroup(
                            homeConversationModel: homeConversationModel)));
                  },
                ),
                ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: -8.0, horizontal: 10.0),
                  leading: Icon(Icons.person_add),
                  title: Text(
                    "اضافة اصدقاء",
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.of(context).push(new MaterialPageRoute(
                        builder: (BuildContext context) =>
                            new InviteFriendsToGroup(
                                userID: userID,
                                groupID: homeConversationModel
                                    .conversationModel.id)));
                  },
                ),
                ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: -8.0, horizontal: 10.0),
                  leading: Icon(Icons.group),
                  title: Text(
                    "أعضاء الغرفة",
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.of(context).push(new MaterialPageRoute(
                        builder: (BuildContext context) => new MembersGroup(
                            homeConversationModel: homeConversationModel)));
                  },
                ),
                ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: -8.0, horizontal: 10.0),
                  leading: Icon(Icons.group),
                  title: Text(
                    "المتواجدون في الغرفة",
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.of(context).push(new MaterialPageRoute(
                        builder: (BuildContext context) => new MembersActive(
                            homeConversationModel: homeConversationModel)));
                  },
                ),
                Visibility(
                  visible: homeConversationModel.role == "admin" ||
                          homeConversationModel.role == "owner"
                      ? true
                      : false,
                  child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          vertical: -8.0, horizontal: 10.0),
                      leading: Icon(Icons.block),
                      title: Text(
                        "قائمة الحظر  ",
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        Navigator.of(context).push(new MaterialPageRoute(
                            builder: (BuildContext context) =>
                                new MembersGroupBlock(
                                    homeConversationModel:
                                        homeConversationModel)));
                      }),
                ),
                ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: -8.0, horizontal: 10.0),
                    leading: Icon(Icons.cancel),
                    title: Text(
                      "إلغاء",
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                    })
              ],
            ),
          );
        });
  }

  Widget buildMessage(MessageData messageData, List<User> members) {
    if (messageData.senderID == MyAppState.currentUser.userID) {
      return myMessageView(messageData);
    } else {
      try {
        return remoteMessageView(
            messageData,
            members.where((user) {
              return user.userID == messageData.senderID;
            }).first);
      } on Exception catch (_) {
        return null;
      }
    }
  }

  Widget myMessageView(MessageData messageData) {
    var mediaUrl = '';
    if (messageData.url != null && messageData.url.url.isNotEmpty) {
      if (messageData.url.mime.contains('image')) {
        mediaUrl = messageData.url.url;
      } else if (messageData.url.mime.contains('video')) {
        mediaUrl = messageData.videoThumbnail;
      }
    }

    return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: messageData.notify.isEmpty
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  messageData.notify.isEmpty
                      ? Stack(alignment: Alignment.topLeft, children: <Widget>[
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      new ProfileScreen(
                                          user1: MyAppState.currentUser,
                                          user2: MyAppState.currentUser)));
                            },
                            child: Padding(
                              padding: EdgeInsets.only(left: 2, right: 2),
                              child: displayCircleImage(
                                  messageData.senderProfilePictureURL,
                                  40,
                                  false),
                            ),
                          ),
                          Positioned(
                              bottom: 1,
                              child: Container(
                                width: 20,
                                height: 20,
                                child: Image.asset(
                                    "assets/images/icon_${messageData.role != null ? messageData.role : 'user'}.png"),
                              )),
                        ])
                      : Container(),
                  Padding(
                      padding: const EdgeInsets.only(right: 2.0, left: 2.0),
                      child: mediaUrl.isNotEmpty
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                //minWidth: 100,
                                maxWidth: 320,
                                // maxHeight: 150,
                              ),
                              child: ClipRRect(

                                borderRadius: BorderRadius.circular(10),
                                child: Stack(

                                    alignment: Alignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (messageData
                                              .videoThumbnail.isEmpty) {
                                            push(
                                                context,
                                                FullScreenImageViewer(
                                                  imageUrl: mediaUrl,
                                                ));
                                          }
                                        },
                                        child: Hero(

                                          tag: mediaUrl,
                                          child:
                                          Column(

                                            children: <Widget>[
                                              Container(
                                                width:300,
                                                decoration: BoxDecoration(color: Colors.white),
                                                padding:
                                                const EdgeInsets.only(
                                                    top: 0,
                                                    bottom: 2,
                                                    right: 6,
                                                    left: 6),
                                                child: SelectableText(
                                                    messageData
                                                        .senderFirstName,
                                                    textAlign:
                                                    TextAlign.start,
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      color: Color(int
                                                          .parse(messageData
                                                          .nameColor)),
                                                    )),
                                              ),
                                          CachedNetworkImage(
                                            width: 300,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            imageUrl: mediaUrl,
                                            placeholder: (context, url) =>
                                                Image.asset(
                                                    'assets/images/img_placeholder'
                                                    '.png'),
                                            errorWidget: (context, url,
                                                    error) =>
                                                Image.asset(
                                                    'assets/images/error_image'
                                                    '.png'),
                                          ),
                                        ]),
                                        ),
                                      ),

                                    ]),
                              ))
                          : messageData.voiceUrl.isNotEmpty
                              ? ConstrainedBox(
                                  constraints: BoxConstraints(),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          messageData.voiceUrl.isNotEmpty
                                              ? Card(
                                                  child: new Row(
                                                      children: <Widget>[
                                                      SizedBox(
                                                        height: 40,
                                                      ),
                                                      IconButton(
                                                          onPressed: () {
                                                            AudioPlayer
                                                                audioPlayer =
                                                                AudioPlayer();
                                                            audioPlayer.play(
                                                                messageData
                                                                    .voiceUrl);
                                                            setState(() {});
                                                            // Build a MaterialApp with the testKey.

                                                            audioPlayer
                                                                .onPlayerCompletion
                                                                .listen((_) {
                                                              setState(() {
                                                                // _isPlaying = false;
                                                                _completedPercentage =
                                                                    0.0;
                                                                // Navigator.pop(context);
                                                              });
                                                            });
                                                            audioPlayer
                                                                .onDurationChanged
                                                                .listen(
                                                                    (duration) {
                                                              setState(() {
                                                                _totalDuration =
                                                                    duration
                                                                        .inMicroseconds;
                                                              });
                                                            });

                                                            audioPlayer
                                                                .onAudioPositionChanged
                                                                .listen(
                                                                    (duration) {
                                                              setState(() {
                                                                _currentDuration =
                                                                    duration
                                                                        .inMicroseconds;
                                                                _completedPercentage =
                                                                    _currentDuration
                                                                            .toDouble() /
                                                                        _totalDuration
                                                                            .toDouble();
                                                              });
                                                            });

                                                            setState(() {});
                                                          },
                                                          icon: Icon(
                                                            Icons.play_arrow,
                                                          )),
                                                      _setWidget(),
                                                    ]))
                                              : Container(
                                                  width: 0,
                                                  height: 0,
                                                )
                                        ]),
                                  ))

                              //================== my message ==========================================================================
                              : ConstrainedBox(
                                  constraints: BoxConstraints(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      // minWidth: 50,
                                      maxWidth: 300,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8))),
                                      child: Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: Stack(
                                            alignment: Alignment.center,
                                            children: <Widget>[
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 0,
                                                            bottom: 2,
                                                            right: 6,
                                                            left: 6),
                                                    child: SelectableText(
                                                        messageData
                                                            .senderFirstName,
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: TextStyle(
                                                          fontSize: 13.5,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(int
                                                              .parse(messageData
                                                                  .nameColor)),
                                                        )),
                                                  ),
                                                  Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: <Widget>[
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  top: 4,
                                                                  bottom: 1,
                                                                  right: 2,
                                                                  left: 2),
                                                          child: SelectableText(
                                                            mediaUrl.isEmpty
                                                                ? messageData
                                                                        .content ??
                                                                    'deleted message'
                                                                : '',
                                                            textAlign:
                                                                TextAlign.start,
                                                            //textDirection: TextDirection.ltr,
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .black),
                                                          ),
                                                        ),
                                                      ]),
                                                ],
                                              ),
                                              Positioned(
                                                left: 0,
                                                right: 0,
                                                // bottom: 20,
                                                top: 15,
                                                child: Divider(
                                                  thickness: 1.5,
                                                ),
                                              ),
                                            ]),
                                      ),
                                    ),
                                  ))),
                ],
              )
            : messageData.notify.isNotEmpty
                ? ConstrainedBox(
                    constraints: BoxConstraints(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // minWidth: 50,
                        maxWidth: 300,
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 0, bottom: 0, right: 6, left: 6),
                                    ),
                                    Stack(
                                        alignment: Alignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 2,
                                                bottom: 1,
                                                right: 2,
                                                left: 2),
                                            child: Text(
                                              mediaUrl.isEmpty
                                                  ? messageData
                                                              .senderFirstName +
                                                          ' : ' +
                                                          messageData.content ??
                                                      'deleted message'
                                                  : '',
                                              textAlign: TextAlign.center,
                                              //textDirection: TextDirection.ltr,
                                              style: TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ]),
                                  ],
                                ),
                              ]),
                        ),
                      ),
                    ))
                : Container());
  }

  Widget remoteMessageView(MessageData messageData, User sender) {
    var mediaUrl = '';
    if (messageData.url != null && messageData.url.url.isNotEmpty) {
      if (messageData.url.mime.contains('image')) {
        mediaUrl = messageData.url.url;
      } else if (messageData.url.mime.contains('video')) {
        mediaUrl = messageData.videoThumbnail;
      }
    }
    return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: messageData.notify.isEmpty
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    child: mediaUrl.isNotEmpty
                        ? ConstrainedBox(
                            constraints: BoxConstraints(
                              //  minWidth: 50,
                              maxWidth: 290,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  Stack(alignment: Alignment.center, children: [
                                GestureDetector(
                                  onTap: () {
                                    if (messageData.videoThumbnail.isEmpty) {
                                      push(
                                          context,
                                          FullScreenImageViewer(
                                            imageUrl: mediaUrl,
                                          ));
                                    }
                                  },
                                  child: Hero(
                                    tag: mediaUrl,
                                    child: Column(children: <Widget>[
                                      Container(
                                        decoration:
                                            BoxDecoration(color: Colors.white),
                                        width: 300,
                                        child: SelectableText(
                                          messageData.senderFirstName,
                                          textAlign: TextAlign.end,
                                          //textDirection: TextDirection.ltr,

                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: Color(int.parse(
                                                  messageData.nameColor))),
                                        ),
                                      ),
                                      CachedNetworkImage(
                                        width: 300,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        imageUrl: mediaUrl,
                                        placeholder: (context, url) =>
                                            Image.asset(
                                                'assets/images/img_placeholder'
                                                '.png'),
                                        errorWidget: (context, url, error) =>
                                            Image.asset(
                                                'assets/images/error_image'
                                                '.png'),
                                      )
                                    ]),
                                  ),
                                ),
                                messageData.voiceUrl.isNotEmpty
                                    ? FloatingActionButton(
                                        mini: true,
                                        heroTag: messageData.messageID,
                                        backgroundColor: Color(COLOR_PRIMARY),
                                        onPressed: () {
                                          push(
                                              context,
                                              FullScreenVideoViewer(
                                                heroTag: messageData.messageID,
                                                videoUrl: messageData.url.url,
                                              ));
                                        },
                                        child: Icon(
                                          Icons.play_arrow,
                                        ),
                                      )
                                    : Container(
                                        width: 0,
                                        height: 0,
                                      )
                              ]),
                            ))
                        : messageData.voiceUrl.isNotEmpty
                            ? Card(
                                child: new Row(children: <Widget>[
                                SizedBox(
                                  height: 40,
                                ),
                                IconButton(
                                    onPressed: () {
                                      AudioPlayer audioPlayer = AudioPlayer();
                                      audioPlayer.play(messageData.voiceUrl);
                                      setState(() {});
                                      // Build a MaterialApp with the testKey.

                                      audioPlayer.onPlayerCompletion
                                          .listen((_) {
                                        setState(() {
                                          // _isPlaying = false;
                                          _completedPercentage = 0.0;
                                          // Navigator.pop(context);
                                        });
                                      });
                                      audioPlayer.onDurationChanged
                                          .listen((duration) {
                                        setState(() {
                                          _totalDuration =
                                              duration.inMicroseconds;
                                        });
                                      });

                                      audioPlayer.onAudioPositionChanged
                                          .listen((duration) {
                                        setState(() {
                                          _currentDuration =
                                              duration.inMicroseconds;
                                          _completedPercentage =
                                              _currentDuration.toDouble() /
                                                  _totalDuration.toDouble();
                                        });
                                      });

                                      setState(() {});
                                    },
                                    icon: Icon(
                                      Icons.play_arrow,
                                    )),
                                _setWidget(),
                              ]))
                            :
                            //==================== remote message view ===================================================
                            Stack(
                                //overflow: Overflow.clip,
                                alignment: Alignment.bottomLeft,
                                children: <Widget>[
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        //minWidth: 50,
                                        maxWidth: 300,
                                      ),
                                      child: Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: <Widget>[
                                            Container(
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.rectangle,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(8))),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: <Widget>[
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 2,
                                                              bottom: 0,
                                                              right: 6,
                                                              left: 6),
                                                      child: SelectableText(
                                                        messageData
                                                            .senderFirstName,
                                                        textAlign:
                                                            TextAlign.start,
                                                        //textDirection: TextDirection.ltr,

                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13.5,
                                                            color:
                                                                //Colors.black38,
                                                                Color(int.parse(
                                                                    messageData
                                                                        .nameColor))),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5,
                                                              bottom: 1.5,
                                                              right: 3,
                                                              left: 3),
                                                      child: SelectableText(
                                                        mediaUrl.isEmpty
                                                            ? messageData
                                                                    .content ??
                                                                'deleted message'
                                                            : '',
                                                        textAlign:
                                                            TextAlign.start,

                                                        // textDirection: TextDirection.ltr,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ]),
                                            ),
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              //bottom: 25,
                                              top: 14,
                                              child: Divider(
                                                thickness: 1.5,
                                              ),
                                            ),
                                          ]),
                                    )
                                  ]),
                  ),
                  messageData.notify.isEmpty
                      ? Stack(
                          alignment: Alignment.topLeft,
                          children: <Widget>[
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        new ProfileScreen(
                                            user1: MyAppState.currentUser,
                                            user2: sender)));
                              },
                              child: displayCircleImage(
                                  sender.profilePictureURL, 40, false),
                            ),
                            Positioned(
                                bottom: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  child: Image.asset(
                                      "assets/images/icon_${messageData.role != null ? messageData.role : 'user'}.png"),
                                )),
                          ],
                        )
                      : Container()
                ],
              )
            : messageData.notify.isNotEmpty
                ? ConstrainedBox(
                    constraints: BoxConstraints(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        //  minWidth: 50,
                        maxWidth: 300,
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            //color: Color(COLOR_PRIMARY),
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 2, bottom: 2, right: 6, left: 6),
                                      child: Text(
                                        '',
                                        textAlign: TextAlign.center,
                                        //textDirection: TextDirection.ltr,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Stack(
                                        alignment: Alignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 0,
                                                bottom: 1,
                                                right: 2,
                                                left: 2),
                                            child: Text(
                                              mediaUrl.isEmpty
                                                  ? messageData
                                                              .senderFirstName +
                                                          " : " +
                                                          messageData.content ??
                                                      'deleted message'
                                                  : '',
                                              textAlign: TextAlign.center,
                                              //textDirection: TextDirection.ltr,
                                              style: TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ]),
                                  ],
                                ),
                              ]),
                        ),
                      ),
                    ))
                : Container());
  }

  Future<bool> _checkChannelNullability(
      ConversationModel conversationModel) async {
    if (conversationModel != null) {
      return true;
    } else {
      String channelID;
      User friend = homeConversationModel.members.first;
      User user = MyAppState.currentUser;
      if (friend.userID.compareTo(user.userID) < 0) {
        channelID = friend.userID + user.userID;
      } else {
        channelID = user.userID + friend.userID;
      }

      ConversationModel2 conversation = ConversationModel2(
          creatorId: user.userID,
          id: channelID,
          lastMessageDate: FieldValue.serverTimestamp(),
          lastMessage: ''
              '${user.fullName()} sent a message');
      bool isSuccessful =
          await _fireStoreUtils.createConversation(conversation);
      if (isSuccessful) {
        // homeConversationModel.conversationModel = conversation;
        Firestore.instance
            .collection('CHANNELS')
            .document(homeConversationModel.conversationModel.id)
            .snapshots()
            .listen((c) {
          if (c.data != null)
            homeConversationModel.conversationModel =
                ConversationModel.fromJson(c.data);
          // homeConversationModel.conversationModel.lastMessageDate = conversationModel.;
        });
        setupStream();
        setState(() {});
      }
      return isSuccessful;
    }
  }

  sendMessage(String content, UrlMessage url, String videoThumbnail,
      String voiceUrl) async {
    MessageData1 message;
    if (homeConversationModel.isGroupChat) {
      message = MessageData1(
          content: content,
          created: FieldValue.serverTimestamp(),
          senderFirstName: MyAppState.currentUser.name,
          nameColor: MyAppState.currentUser.color,
          role: homeConversationModel.role != null
              ? homeConversationModel.role
              : "user",
          senderID: MyAppState.currentUser.userID,
          senderProfilePictureURL: MyAppState.currentUser.profilePictureURL,
          url: url,
          videoThumbnail: videoThumbnail,
          voiceUrl: voiceUrl);
    }
    if (url != null) {
      if (url.mime.contains('image')) {
        message.content = '${MyAppState.currentUser.name} sent an image';
      } else if (url.mime.contains('video')) {
        message.content = '${MyAppState.currentUser.name} sent a video';
      }
    }
    if (await _checkChannelNullability(
        homeConversationModel.conversationModel)) {
      await _fireStoreUtils.sendMessage1(
          message, homeConversationModel.conversationModel);
      ConversationModel2 conversationModel2 = new ConversationModel2();
      conversationModel2.id = homeConversationModel.conversationModel.id;
      conversationModel2.creatorId =
          homeConversationModel.conversationModel.creatorId;
      conversationModel2.lastMessage =
          homeConversationModel.conversationModel.lastMessage;
      conversationModel2.name = homeConversationModel.conversationModel.name;
      conversationModel2.description =
          homeConversationModel.conversationModel.description;
      conversationModel2.lastMessageDate = FieldValue.serverTimestamp();
      conversationModel2.msgCount =
          homeConversationModel.conversationModel.msgCount;
      conversationModel2.currentNumberMembers =
          homeConversationModel.conversationModel.currentNumberMembers;

      //homeConversationModel.conversationModel.lastMessage = message.content.substring(0,40);
      homeConversationModel.conversationModel.msgCount = totalMessages;

      await _fireStoreUtils.updateChannel(conversationModel2);
      await _fireStoreUtils.updateReadCount(
          homeConversationModel.participentId, totalMessages);
    } else {
      showAlertDialog(context, 'فشل الارسال', 'يرجى المحاولة مرة أخرى');
    }
  }

  _setWidget() {
    return LinearPercentIndicator(
      width: 200.0,
      lineHeight: 2.0,
      percent: _completedPercentage,
      linearStrokeCap: LinearStrokeCap.roundAll,
      backgroundColor: Colors.grey,
      progressColor: Colors.orangeAccent,
    );
  }

  editGroupDescription(BuildContext context) {
    TextEditingController _groupDescriptionController =
        new TextEditingController();
    _groupDescriptionController.text =
        widget.homeConversationModel.conversationModel.description;
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
                        height: 375,
                        width: 350,
                        child: Padding(
                            padding: const EdgeInsets.only(
                                top: 20.0, left: 16, right: 16, bottom: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "تعديل وصف الغرفة",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 16),
                                Padding(
                                    padding: const EdgeInsets.only(
                                        top: 10.0,
                                        left: 16,
                                        right: 16,
                                        bottom: 16)),
                                TextField(
                                  textInputAction: TextInputAction.done,
                                  keyboardType: TextInputType.text,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLines: 7,
                                  controller: _groupDescriptionController,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.only(
                                        left: 8.0, top: 2.0, bottom: 2.0),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide(
                                            color: Color(COLOR_ACCENT),
                                            width: 2.0)),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0)),
                                    labelText: 'الوصف',
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.only(
                                        top: 10.0,
                                        left: 16,
                                        right: 16,
                                        bottom: 16)),
                                SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('إلغاء')),
                                    TextButton(
                                        onPressed: () async {
                                          if (_groupDescriptionController
                                              .text.isNotEmpty) {
                                            _chatHelper.updateGroupDescription(
                                                homeConversationModel
                                                    .conversationModel.id,
                                                _groupDescriptionController
                                                    .text,
                                                homeConversationModel);
                                            setState(() {
                                              _description =
                                                  _groupDescriptionController
                                                      .text;
                                            });
                                            sendMessage(
                                                _groupDescriptionController
                                                    .text,
                                                UrlMessage(mime: '', url: ''),
                                                '',
                                                '');
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: Text('حفظ',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(COLOR_ACCENT)))),
                                  ],
                                )
                              ],
                            )),
                      ))));
        });
  }

  Future<void> alertUpdateGroup(BuildContext context, String groupID) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Align(
            alignment: Alignment.center,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 25),
                ),
                SizedBox(
                  width: 150,
                  child: new Image.asset("assets/images/mony.png"),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 15),
                ),
                Text(
                  "تكلفة رفع ترتيب الغرفة",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 15),
                ),
                SizedBox(
                  width: 150,
                  child: new Text("1500 نقطة", textAlign: TextAlign.center),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        TextButton(
                          child: Text('تأكيد',
                              style: TextStyle(
                                  fontSize: Constants.FONT_SIZE_MEDIUM,
                                  color: Colors.green)),
                          onPressed: () async {
                            bool isSuccessful =
                                await _userHelper.paymentPoints(1500);
                            if (isSuccessful) {
                              hideProgress();
                              Toast.show("تم خصم 1500 نقطة بنجاح", context,
                                  duration: Toast.LENGTH_LONG,
                                  gravity: Toast.BOTTOM);
                              showProgress(
                                  context,
                                  ' جاري رفع الغرفة ، الرجاء الانتظار ...',
                                  false);

                              await _fireStoreUtils.updateGroup(groupID);
                              hideProgress();
                              Navigator.pop(context);
                            } else {
                              hideProgress();
                              Toast.show("رصيد نقاطك غير كافي", context,
                                  duration: Toast.LENGTH_LONG,
                                  gravity: Toast.CENTER);
                            }
                          },
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        TextButton(
                          child: Text(
                            'رجوع',
                            style: TextStyle(
                                fontSize: Constants.FONT_SIZE_MEDIUM,
                                color: Colors.black38),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ]),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void onEmojiSelected(String emoji) => setState(() {
        _messageController.text = _messageController.text + emoji;

        _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length));
      });

  Future toggleText() async {
    if (isEmojiVisible)
      setState(() {
        isEmojiVisible = !isEmojiVisible;
      });
  }

  Future toggleEmojiKeyboard() async {
    if (isKeyboardVisible) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      isEmojiVisible = !isEmojiVisible;
    });
  }

  Future toggleButtonKeyboard() async {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        isSendButtonVisible = true;
      });
    } else {
      setState(() {
        isSendButtonVisible = false;
      });
    }
  }

  Future<bool> onBackPress() {
    if (isEmojiVisible) {
      toggleEmojiKeyboard();
    } else {
      _init();
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  nun() {}

  _init() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/flutter_audio_recorder_';

        io.Directory appDocDirectory = await getApplicationDocumentsDirectory();
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath = appDocDirectory.path +
            customPath +
            DateTime.now().millisecondsSinceEpoch.toString();

        // .wav <---> AudioFormat.WAV
        // .mp4 .m4a .aac <---> AudioFormat.AAC
        // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
        _recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await _recorder.initialized;
        // after initialization
        var current = await _recorder.current(channel: 0);

        print(current);
        // should be "Initialized", if all working fine

      } else {
        Toast.show("الأذونات مطلوبة", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
      }
    } catch (e) {
      print(e);
    }
  }

  void mm() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        isSendButtonVisible = true;
      });
    } else {
      isSendButtonVisible = false;
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      //setState(() {
      _init();
      // });

      print("paused");
    } else if (state == AppLifecycleState.inactive) {
      _init();
      print("inactive");
    }
    // else
    if (state == AppLifecycleState.resumed) {
      print("resumed");
    }
  }
}
