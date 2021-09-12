import 'dart:async';
import 'dart:io' as io;

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/home.dart';
import 'package:elegant/model/Friendship.dart';
import 'package:elegant/model/MessageData1.dart';
import 'package:elegant/ui/account/ProfileScreen.dart';
import 'package:elegant/ui/services/UserHelper.dart';
import 'package:elegant/ui/widget/emoji_picker_widget.dart';
import 'package:elegant/ui/widget/input_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:toast/toast.dart';

import '../../constants.dart';
import '../../main.dart';
import '../../model/ChatModel.dart';
import '../../model/ConversationModel.dart';
import '../../model/HomeConversationModel.dart';
import '../../model/MessageData.dart';
import '../../model/User.dart';
import '../../ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import '../../ui/fullScreenVideoViewer/FullScreenVideoViewer.dart';
import '../../ui/services/FirebaseHelper.dart';
import '../../ui/services/SoundHelper.dart';
import '../../ui/utils/helper.dart';
import 'TypeCall.dart';

class ChatScreen extends StatefulWidget {
  final HomeConversationModel homeConversationModel;

  const ChatScreen({Key key, @required this.homeConversationModel})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState(homeConversationModel);
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  LinearPercentIndicator linearPercentIndicator;
  int _totalDuration;
  AudioPlayer audioPlayer = AudioPlayer();
  int _currentDuration;
  double _completedPercentage = 0.0;
  IconData _recordIcon = Icons.mic;
  final controller = TextEditingController();
  bool isEmojiVisible = false;
  bool isSendButtonVisible = false;
  bool isKeyboardVisible = false;
  FlutterAudioRecorder _recorder;
  Recording _current;
  String voicePath;
  RecordingStatus _currentStatus = RecordingStatus.Initialized;
  final HomeConversationModel homeConversationModel;
  TextEditingController _messageController = TextEditingController();
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();
  TextEditingController _groupNameController = TextEditingController();
  bool visibilityCancelRecord = false;
  bool editDescription = false;
  bool isFriend = false;
  List<CameraDescription> cameras;

  _ChatScreenState(this.homeConversationModel);

  static Firestore fireStore = Firestore.instance;
  Stream<ChatModel> chatStream;
  int totalMessages = 0;
  final messages = <String>[];
  SoundHelper helper = new SoundHelper();
  String roleUser;
  final fireStoreUtils = FireStoreUtils();
  UserHelper _userHelper = new UserHelper();

  @override
  void initState() {
    super.initState();
    _userHelper.notification(context, 'chat');
    _messageController.addListener(toggleButtonKeyboard);
    KeyboardVisibility.onChange.listen((bool isKeyboardVisible) {
      if (mounted) {
        setState(() {
          this.isKeyboardVisible = isKeyboardVisible;
        });
      }
    });
    WidgetsBinding.instance.addObserver(this);
    getBlocks().listen((shouldRefresh) {
      if (shouldRefresh) {
        setState(() {
          isFriend = true;
        });
      } else {
        setState(() {
          isFriend = false;
        });
      }
    });
    _init();
    setupStream();
  }

  setupStream() {
    chatStream = _fireStoreUtils
        .getChatMessages(homeConversationModel)
        .asBroadcastStream();
    chatStream.listen((chatModel) {
      if (chatModel.message != null) {
        if (homeConversationModel.members != chatModel.members) {
          homeConversationModel.members = chatModel.members;
          setState(() {});
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
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () async {
              if (isFriend)
                _callType();
              else
                Toast.show("متاح للأصدقاء فقط", context,
                    duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
            },
          ),
          PopupMenuButton(
            elevation: 3.2,
            onCanceled: () {
              print('You have not chossed anything');
            },
            onSelected: (index) async {
              if (index == 1) {

 Navigator.pop(context);
          showProgress(context, 'جار الحظر', false);
          bool isSuccessful = await _fireStoreUtils.blockUser(
              homeConversationModel.members.first, 'block');
          hideProgress();
          if (isSuccessful) {
            pushAndRemoveUntil(
                context, Home(user: MyAppState.currentUser), false);
            _showAlertDialog(context, 'الحظر',
                '${homeConversationModel.members.first.fullName()} تم حظره بنجاح ');
          } else {
            _showAlertDialog(
                context,
                'Block',
                'Couldn'
                    '\'t block ${homeConversationModel.members.first.fullName()}, يرجى المحاولة لاحقاً ');
          }

              }
              if (index == 2) {
                sendMessage(
                    "تم مسح الدردشة", UrlMessage(mime: '', url: ''), '', '');
                Toast.show("جار حذف الدردشة", context,
                    duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
                bool isSuccessful = await _fireStoreUtils
                    .deleteChat(homeConversationModel.conversationModel);
                sendMessage(
                    "تم مسح الدردشة", UrlMessage(mime: '', url: ''), '', '');
                print("isSuccessful1");
                print(isSuccessful);
                bool isSuccessful2 = await fireStoreUtils.deleteConversation(
                    homeConversationModel.conversationModel.id);

                if (isSuccessful2) {
                  Navigator.pop(context);
                  pushReplacement(context,
                      new Home(cameras: cameras, user: MyAppState.currentUser));
                }
                hideProgress();
                if (isSuccessful) {
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context);
                }
              }
              if (index == 3) {
                Navigator.pop(context);
              }
              print(index.toString());
            },
            tooltip: 'This is tooltip',
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 1,
                  child: Text("حظر المستخدم"),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Text("حذف الدردشة للجميع"),
                ),
                PopupMenuItem(
                  value: 3,
                  child: Text("إلغاء"),
                )
              ];
            },
          )
        ],
        backgroundColor: Color(COLOR_PRIMARY),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              homeConversationModel.members.first.fullName(),
              style: TextStyle(fontSize: 13),
            ),
            homeConversationModel.members.first.lastOnlineTimestamp != null
                ? Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: buildSubTitle(homeConversationModel.members.first),
                  )
                : Container(
                    width: 0,
                    height: 0,
                  )
          ],
        ),
      ),
      body: Container(
        // decoration: BoxDecoration(
        //   image: DecorationImage(
        //     image: AssetImage("assets/images/bg_chat.png"),
        //     fit: BoxFit.cover,
        //   ),
        // ),
        color: Color(COLOR_BACKGROUND),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Column(
            children: <Widget>[
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
                              snapshot.data.message.isEmpty &&
                              snapshot.data.members.isEmpty) {
                            return Center(child: Text(' '));
                          } else {
                            return ListView.builder(
                                reverse: true,
                                itemCount: snapshot.data.message.length,
                                itemBuilder: (BuildContext context, int index) {
                                  print(snapshot.data.message.toString());
                                  return buildMessage(
                                      snapshot.data.message[index],
                                      snapshot.data.members);
                                });
                          }
                        }
                      }),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 13),
                color: Colors.white60,
                child: Padding(
                  padding: const EdgeInsets.only(top: 0.0),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.only(top: 0.0, right: 0),
                            child: WillPopScope(
                              onWillPop: onBackPress,
                              child: Column(
                                children: <Widget>[
                                  InputWidget(
                                    onBlurred: toggleEmojiKeyboard,
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

  Widget buildSubTitle(User friend) {
    if (isFriend) {
      final text = friend.active
          ? 'نشط'
          : 'آخر ظهور '
              '${setLastSeen(friend.lastOnlineTimestamp?.seconds ?? 0)}';
      return Text(text,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade200));
    } else {
      // final text = 'آخر ظهور '
      //     '${setLastSeen(friend.lastOnlineTimestamp?.seconds ?? 0)}';
      // return Text(text,
      //     style: TextStyle(fontSize: 14, color: Colors.grey.shade200));
      final text = 'لستما صديقين';
      return Text(text,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade200));
    }
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
        print('never reached');
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
      padding: const EdgeInsets.only(top: 1, bottom: 4),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Stack(alignment: Alignment.topLeft, children: <Widget>[
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) => new ProfileScreen(
                            user1: MyAppState.currentUser,
                            user2: MyAppState.currentUser)));
                  },
                  child: displayCircleImage(
                      messageData.senderProfilePictureURL, 35, false),
                ),
                Positioned(
                    bottom: 1,
                    child: Container(
                      width: 20,
                      height: 20,
                      // child:   Image.asset("assets/images/icon_${messageData.role != null ?messageData.role : "user"}.png"),
                    )),
              ]),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: mediaUrl.isNotEmpty
                        ? ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: 50,
                              maxWidth: 300,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(alignment: Alignment.center, children: [
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
                                    child: CachedNetworkImage(
                                      width: 300,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      imageUrl: mediaUrl,
                                      placeholder: (context, url) =>
                                          Image.asset('assets/images/img_placeholder'
                                              '.png'),
                                      errorWidget: (context, url, error) =>
                                          Image.asset('assets/images/error_image'
                                              '.png'),
                                    ),
                                  ),
                                ),
                                messageData.videoThumbnail.isNotEmpty
                                    ? FloatingActionButton(
                                        mini: true,
                                        heroTag: messageData.messageID,
                                        backgroundColor: Color(COLOR_ACCENT),
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
                            ? ConstrainedBox(
                                constraints: BoxConstraints(),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(alignment: Alignment.center, children: [
                                    messageData.voiceUrl.isNotEmpty
                                        ? Card(
                                            child: new Row(children: <Widget>[
                                            SizedBox(
                                              height: 40,
                                            ),
                                            IconButton(
                                                onPressed: () {
                                                  AudioPlayer audioPlayer =
                                                      AudioPlayer();
                                                  audioPlayer
                                                      .play(messageData.voiceUrl);
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
                                        : Container(
                                            width: 0,
                                            height: 0,
                                          )
                                  ]),
                                ))
                            : messageData.notify.isNotEmpty
                                ? ConstrainedBox(
                                    constraints: BoxConstraints(),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: 50,
                                        maxWidth: 200,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: Color(COLOR_PRIMARY),
                                            borderRadius:
                                                BorderRadius.all(Radius.circular(8))),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Stack(
                                              alignment: Alignment.center,
                                              overflow: Overflow.clip,
                                              children: <Widget>[
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                      top: 6,
                                                      bottom: 6,
                                                      right: 4,
                                                      left: 4),
                                                  child: Text(
                                                    mediaUrl.isEmpty
                                                        ? messageData.content ??
                                                            'deleted message'
                                                        : '',
                                                    textAlign: TextAlign.start,
                                                    //textDirection: TextDirection.ltr,
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ]),
                                        ),
                                      ),
                                    ))
                                : Stack(
                                    overflow: Overflow.visible,
                                    alignment: Alignment.bottomRight,
                                    children: <Widget>[
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: 50,
                                            maxWidth: 200,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.white70,
                                                shape: BoxShape.rectangle,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(8))),
                                            child: Column(
                                              children: <Widget>[
                                                // SelectableText(
                                                //   messageData.senderFirstName,
                                                //   textAlign: TextAlign.start,
                                                //   //textDirection: TextDirection.ltr,
                                                //   style: TextStyle(
                                                //       fontSize: 14, color: otherColor),
                                                // ),
                                                Padding(
                                                  padding: const EdgeInsets.all(4.0),
                                                  child: Stack(
                                                      alignment: Alignment.center,
                                                      overflow: Overflow.clip,
                                                      children: <Widget>[
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                  top: 6,
                                                                  bottom: 6,
                                                                  right: 4,
                                                                  left: 4),
                                                          child: SelectableText(
                                                            mediaUrl.isEmpty
                                                                ? messageData.content ??
                                                                    'deleted message'
                                                                : '',
                                                            textAlign: TextAlign.start,
                                                            //textDirection: TextDirection.ltr,
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors.black),
                                                          ),
                                                        ),
                                                      ]),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ]),
                  ),
                
                  Text(DateFormat("hh:mm").format(messageData.created.toDate()).toString())
                ],
              ),
              
            ],
          ),
     
      
      
        ],
      ),
    );
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
      padding: const EdgeInsets.only(top: 1.0, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: mediaUrl.isNotEmpty
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 50,
                      maxWidth: 300,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(alignment: Alignment.center, children: [
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
                            child: CachedNetworkImage(
                              width: 300,
                              height: 200,
                              fit: BoxFit.cover,
                              imageUrl: mediaUrl,
                              placeholder: (context, url) =>
                                  Image.asset('assets/images/img_placeholder'
                                      '.png'),
                              errorWidget: (context, url, error) =>
                                  Image.asset('assets/images/error_image'
                                      '.png'),
                            ),
                          ),
                        ),
                        messageData.videoThumbnail.isNotEmpty
                            ? FloatingActionButton(
                                mini: true,
                                heroTag: messageData.messageID,
                                backgroundColor: Color(COLOR_ACCENT),
                                onPressed: () {
                                  push(
                                      context,
                                      FullScreenVideoViewer(
                                        heroTag: messageData.messageID,
                                        videoUrl: messageData.url.url,
                                      ));
                                },
                                child: Icon(Icons.play_arrow),
                              )
                            : Container(
                                width: 0,
                                height: 0,
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

                              audioPlayer.onPlayerCompletion.listen((_) {
                                setState(() {
                                  // _isPlaying = false;
                                  _completedPercentage = 0.0;
                                  // Navigator.pop(context);
                                });
                              });
                              audioPlayer.onDurationChanged.listen((duration) {
                                setState(() {
                                  _totalDuration = duration.inMicroseconds;
                                });
                              });

                              audioPlayer.onAudioPositionChanged
                                  .listen((duration) {
                                setState(() {
                                  _currentDuration = duration.inMicroseconds;
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
                    : messageData.notify.isNotEmpty
                        ? ConstrainedBox(
                            constraints: BoxConstraints(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: 50,
                                maxWidth: 200,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Color(COLOR_PRIMARY),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8))),
                                child: Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: Stack(
                                      alignment: Alignment.center,
                                      overflow: Overflow.clip,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 1,
                                              bottom: 1,
                                              right: 4,
                                              left: 4),
                                          child: Text(
                                            mediaUrl.isEmpty
                                                ? messageData.content ??
                                                    'deleted message'
                                                : '',
                                            textAlign: TextAlign.start,
                                            //textDirection: TextDirection.ltr,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ]),
                                ),
                              ),
                            ))
                        : Stack(
                            overflow: Overflow.visible,
                            alignment: Alignment.bottomLeft,
                            children: <Widget>[
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: 50,
                                  maxWidth: 200,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.white10,
                                      shape: BoxShape.rectangle,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8))),
                                  child: Padding(
                                      padding: const EdgeInsets.all(1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.rectangle,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(8))),
                                        child: Column(children: <Widget>[
                                          // SelectableText(
                                          //     messageData.senderFirstName,
                                          //     textAlign: TextAlign.start,
                                          //     //textDirection: TextDirection.ltr,
                                          //     style: TextStyle(
                                          //         fontSize: 14,
                                          //         color: Color(int.parse(
                                          //             messageData.nameColor))),
                                          //   ),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 6,
                                                bottom: 6,
                                                right: 4,
                                                left: 4),
                                            child: SelectableText(
                                              mediaUrl.isEmpty
                                                  ? messageData.content ??
                                                      'deleted message'
                                                  : '',
                                              textAlign: TextAlign.start,
                                              // textDirection: TextDirection.ltr,
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ]),
                                      )),
                                ),
                              ),
                            ],
                          ),
          ),
          Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[
              InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => new ProfileScreen(
                          user1: MyAppState.currentUser, user2: sender)));
                },
                child: displayCircleImage(sender.profilePictureURL, 35, false),
              ),
              Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: homeConversationModel.members.first.active
                            ? Colors.green
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(width: 1)),
                  )),
              Positioned(
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    // child:   Image.asset("assets/images/icon_${messageData.role != null ?messageData.role : "user"}.png"),
                  )),
            ],
          ),
        ],
      ),
    );
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
        setupStream();
        setState(() {});
      }
      return isSuccessful;
    }
  }

  sendMessage(String content, UrlMessage url, String videoThumbnail,
      String voiceUrl) async {
    MessageData1 message;
    message = MessageData1(
        content: content,
        created: FieldValue.serverTimestamp(),
        recipientFirstName: homeConversationModel.members.first.name,
        recipientID: homeConversationModel.members.first.userID,
        recipientProfilePictureURL:
            homeConversationModel.members.first.profilePictureURL,
        senderFirstName: MyAppState.currentUser.name,
        nameColor: MyAppState.currentUser.color,
        senderID: MyAppState.currentUser.userID,
        senderProfilePictureURL: MyAppState.currentUser.profilePictureURL,
        url: url,
        videoThumbnail: videoThumbnail,
        voiceUrl: voiceUrl);

    if (url != null) {
      if (url.mime.contains('image')) {
        message.content = '${MyAppState.currentUser.name} sent an image';
      } else if (url.mime.contains('video')) {
        message.content = '${MyAppState.currentUser.name} sent a video';
      }
    }
    if (await _checkChannelNullability(
        homeConversationModel.conversationModel)) {
      await _fireStoreUtils.sendMessage(
          message, homeConversationModel.conversationModel);
      // homeConversationModel.conversationModel.lastMessageDate = FieldValue.serverTimestamp();
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

      message.content.length > 40
          ? homeConversationModel.conversationModel.lastMessage =
              message.content.substring(0, 40)
          : homeConversationModel.conversationModel.lastMessage =
              message.content;
      homeConversationModel.conversationModel.msgCount = totalMessages;

      await _fireStoreUtils.updateChannel(conversationModel2);
      await _fireStoreUtils.updateReadCount(
          homeConversationModel.participentId, totalMessages);
    } else {
      showAlertDialog(context, 'فشل الارسال', 'يرجى المحاولة مرة أخرى');
    }
  }

  _callType() async {
    User user2 = homeConversationModel.members.first;
    push(context, IndexPage(user2: user2));
  }

  @override
  void dispose() {
    super.dispose();

    _currentStatus != RecordingStatus.Unset ? _init() : null;

    _recordIcon = Icons.mic;
    visibilityCancelRecord = false;
    _messageController.dispose();
    _groupNameController.dispose();
  }

  _onPrivateChatSettingsClick() {
    PopupMenuButton(
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            value: 1,
            child: Text('choice.title'),
          )
        ];
      },
    );
  }

  _showAlertDialog(BuildContext context, String title, String message) {
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(message),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

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
        voicePath = customPath;
        print(current);
        // should be "Initialized", if all working fine
        setState(() {
          _current = current;
          _currentStatus = current.status;
          print(_currentStatus);
        });
      } else {
        Scaffold.of(context).showSnackBar(
            new SnackBar(content: new Text("You must accept permissions")));
      }
    } catch (e) {
      print(e);
    }
  }

  _start() async {
    await Future.delayed(const Duration(milliseconds: 900));

    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);
      setState(() {
        _current = recording;
      });

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer t) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = await _recorder.current(channel: 0);
        // print(current.status);

        _current = current;
        _currentStatus = _current.status;
      });
    } catch (e) {
      print(e);
    }
  }

  _resume() async {
    await _recorder.resume();
    setState(() {});
  }

  _pause() async {
    await _recorder.pause();
    setState(() {});
  }

  _stop() async {
    var result = await _recorder.stop();
    print("Stop recording: ${result.path}");
    print("Stop recording: ${result.duration}");
    print("Path: " + voicePath);

    if (result.path != null) {
      String urlVoice =
          (await _fireStoreUtils.uploadAudioToStorage(result.path));
      print(urlVoice);
      sendMessage("رسالة صوتية", UrlMessage(mime: '', url: ''), '', urlVoice);
    }

    setState(() {
      _current = result;
      _currentStatus = _current.status;
    });
  }

  String _getDateFromFilePatah({@required String filePath}) {
    String fromEpoch = filePath.substring(
        filePath.lastIndexOf('/') + 1, filePath.lastIndexOf('.'));

    DateTime recordedDate =
        DateTime.fromMillisecondsSinceEpoch(int.parse(fromEpoch));
    int year = recordedDate.year;
    int month = recordedDate.month;
    int day = recordedDate.day;

    return ('$year-$month-$day');
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

  Stream<bool> getBlocks() async* {
    StreamController<bool> refreshStreamController = StreamController();
    List friendshipList = List<Friendship>();
    await fireStore
        .collection(FRIENDSHIP)
        .where('user1', isEqualTo: MyAppState.currentUser.userID)
        .where('user2', isEqualTo: homeConversationModel.members.first.userID)
        .getDocuments()
        .then((querysnapShot) {
      querysnapShot.documents.forEach((doc) {
        Friendship friendship = Friendship.fromJson(doc.data);
        if (friendship.id.isEmpty) {
          friendship.id = doc.documentID;
        }
        friendshipList.add(friendship);
      });
    });
    setState(() {});
    await fireStore
        .collection(FRIENDSHIP)
        .where('user1', isEqualTo: homeConversationModel.members.first.userID)
        .where('user2', isEqualTo: MyAppState.currentUser.userID)
        .getDocuments()
        .then((onValue) {
      onValue.documents.forEach((doc) {
        Friendship friendship = Friendship.fromJson(doc.data);
        if (friendship.id.isEmpty) {
          friendship.id = doc.documentID;
        }
        friendshipList.add(friendship);
      });
    });
    if (friendshipList.length > 0) {
      setState(() {
        refreshStreamController.sink.add(true);
      });
    }
    yield* refreshStreamController.stream;
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      _currentStatus != RecordingStatus.Unset ? _init() : null;

      _recordIcon = Icons.mic;
      visibilityCancelRecord = false;
      print("paused");
    } else if (state == AppLifecycleState.inactive) {
      //setState(() {
      _currentStatus != RecordingStatus.Unset ? _init() : null;
      // });

      _recordIcon = Icons.mic;
      visibilityCancelRecord = false;
      print("inactive");
    }

    if (state == AppLifecycleState.resumed) {
      print("resumed");
    }
  }

  Future toggleEmojiKeyboard() async {
    if (isKeyboardVisible) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      isEmojiVisible = !isEmojiVisible;
    });
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

  @override
  void onEmojiSelected(String emoji) => setState(() {
        _messageController.text = _messageController.text + emoji;
      });

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
}
