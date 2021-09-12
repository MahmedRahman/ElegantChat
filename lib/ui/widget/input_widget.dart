import 'dart:async';
import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/model/ConversationModel.dart';
import 'package:elegant/model/HomeConversationModel.dart';
import 'package:elegant/model/MessageData1.dart';
import 'package:elegant/model/User.dart';
import 'package:elegant/ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import 'package:elegant/ui/fullScreenImageViewer/FullScreenImageViewer2.dart';
import 'package:elegant/ui/services/FirebaseHelper.dart';
import 'package:elegant/ui/services/SoundHelper.dart';
import 'package:elegant/ui/utils/helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

import '../../main.dart';

class InputWidget extends StatefulWidget {
  RecordingStatus _currentStatus = RecordingStatus.Unset;
  final TextEditingController controller;
  final HomeConversationModel homeConversationModel;
  bool isEmojiVisible;
  bool isSendButtonVisible;
  bool isKeyboardVisible;

  final Function onBlurred;
  final Function onBlurred2;
   final ValueChanged<String> onSentMessage;
  final FocusNode focusNode;
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();
  ConversationModel conversationModel = new ConversationModel();

  @override
  InputWidget({
    @required this.focusNode,
    @required this.controller,
    @required this.homeConversationModel,
    @required this.isEmojiVisible,
    @required this.isSendButtonVisible,
    @required this.isKeyboardVisible,
    @required this.onSentMessage,
    @required this.onBlurred,
    @required this.onBlurred2,
     Key key,
  }) : super(key: key);

  SoundHelper helper = new SoundHelper();
  FlutterAudioRecorder _recorder;
  String voicePath;
  Recording _current;

  @override
  _InputWidgetState createState() => _InputWidgetState(
      focusNode,
      controller,
      homeConversationModel,
      isEmojiVisible,
      isSendButtonVisible,
      isKeyboardVisible,
      onSentMessage,
      onBlurred

  );
}

class _InputWidgetState extends State<InputWidget> {
  _InputWidgetState(
      FocusNode focusNode,
      TextEditingController controller,
      HomeConversationModel homeConversationModel,
      bool isEmojiVisible,
      bool isSendButtonVisible,
      bool isKeyboardVisible,
      ValueChanged<String> onSentMessage,
      Function onBlurred,
    );

  bool visibleClear = false;

  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(width: 0.5)),
          color: Colors.white,
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.camera_alt_outlined,
              ),
              onPressed: onClickedCamera,
            ),
            buildEmoji(),
            Expanded(child: buildTextField()),
            buildButton(),
            Visibility(
              visible: visibleClear,
              child: Row(children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.red,
                  ),
                  onPressed: onClickedClear,
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Colors.green,
                  ),
                  onPressed: onClickedSendVoice,
                ),
              ]),
            )
            //buildSend(),
          ],
        ),
      );

  Widget buildEmoji() => Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        child: IconButton(
          icon: Icon(
            widget.isEmojiVisible
                ? Icons.keyboard_rounded
                : Icons.emoji_emotions_outlined,
          ),
          onPressed: onClickedEmoji,
        ),
      );

  Widget buildButton() => Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        child: IconButton(
            icon: Icon(
              widget.isSendButtonVisible ? Icons.send : Icons.mic,
            ),
            onPressed: () {
              onClickedButton();
            }),
      );

  Widget buildTextField() => TextField(
       // focusNode:  widget.focusNode,
        controller: widget.controller,
        onTap: widget.onBlurred2,
        style: TextStyle(fontSize: 16),

        decoration: InputDecoration(

          contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          hintText: 'اكتب رسالة ...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
              borderSide: BorderSide(style: BorderStyle.none)),
        ),

      );

  void onClickedEmoji() async {
    if (widget.isEmojiVisible) {
      widget.focusNode.requestFocus();
      await SystemChannels.textInput.invokeMethod('TextInput.show');
    } else if (widget.isKeyboardVisible) {
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      await Future.delayed(Duration(milliseconds: 100));
    }
    widget.onBlurred();
  }

  void onClickedClear() async {
    setState(() {
      visibleClear = false;
      widget.helper.soundPlay("assets/sounds/s4.mp3");

      setState(() {
        widget._currentStatus = RecordingStatus.Stopped;
        widget._currentStatus != RecordingStatus.Unset ? _init() : nun();
      });
    });
  }

  void onClickedSendVoice() async {
    setState(() {
      visibleClear = false;
    });
    _stop();
    _init();
    //         }
  }

  Future<void> onClickedCamera() async {
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
    await Future.delayed(Duration(milliseconds: 100));
    setState(() {});
    showModalBottomSheet(
        context: context,
        builder: (bc) {
          return Container(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text("التقاط صورة"),
                  onTap: () async {
                    Navigator.pop(context);
                    var image =
                        await ImagePicker.pickImage(source: ImageSource.camera);
                    if (image != null) {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return Center(
                                child: SingleChildScrollView(
                                    child: Dialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        elevation: 16,
                                        child: Wrap(
                                          children: <Widget>[
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 20.0,
                                                    left: 16,
                                                    right: 16,
                                                    bottom: 16),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      "تأكيد إرسال الصورة",
                                                    ),
                                                    SizedBox(height: 16),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: <Widget>[
                                                        TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context),
                                                            child:
                                                                Text('إلغاء')),
                                                        TextButton(
                                                            onPressed:
                                                                () async {
                                                              UrlMessage url = await widget
                                                                  ._fireStoreUtils
                                                                  .uploadChatImageToFireStorage(
                                                                      image,
                                                                      context);
                                                              sendTextMessage(
                                                                  widget
                                                                      .controller
                                                                      .text
                                                                      .trim(),
                                                                  widget
                                                                      .homeConversationModel,
                                                                  url,
                                                                  '');
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Text('تأكيد',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ))),
                                                      ],
                                                    )
                                                  ],
                                                ))
                                          ],
                                        ))));
                          });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_album),
                  title: Text("صورة من المعرض"),
                  onTap: () async {
                    Navigator.pop(context);
                    var image = await ImagePicker.pickImage(
                        source: ImageSource.gallery);


                    if (image != null) {
                      push(
                          context,
                          FullScreenImageViewer2(
                            image : image,
                          ));
                      showDialog(
                          context: context,
                          builder: (context) {
                            return Align(
                              alignment: Alignment.bottomCenter,

                                child: SingleChildScrollView(
                                    child: Dialog(

                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        elevation: 16,
                                        child: Wrap(

                                          children: <Widget>[
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 20.0,
                                                    left: 16,
                                                    right: 16,
                                                    bottom: 16),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      "تأكيد إرسال الصورة",
                                                    ),
                                                    SizedBox(height: 16),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: <Widget>[
                                                        TextButton(
                                                            onPressed: ()
                                        {
                                                                Navigator.pop(context);
                                                                Navigator.pop(context);},
                                                            child:
                                                                Text('إلغاء')),
                                                        TextButton(
                                                            onPressed:
                                                                () async {
                                                              UrlMessage url = await widget
                                                                  ._fireStoreUtils
                                                                  .uploadChatImageToFireStorage(
                                                                      image,
                                                                      context);
                                                              sendTextMessage(
                                                                  widget
                                                                      .controller
                                                                      .text
                                                                      .trim(),
                                                                  widget
                                                                      .homeConversationModel,
                                                                  url,
                                                                  '');
                                                              Navigator.pop(context);
                                                              Navigator.pop(context);
                                                            },
                                                            child: Text('تأكيد',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ))),
                                                      ],
                                                    )
                                                  ],
                                                ))
                                          ],
                                        ))));
                          });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.cancel),
                  title: Text("إلغاء"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        });
  }

  void onClickedButton() async {
    if (widget.isSendButtonVisible) {
      //  focusNode.requestFocus();
      if (widget.controller.text.trim().isNotEmpty) {
        sendTextMessage(widget.controller.text.trim(),
            widget.homeConversationModel, UrlMessage(mime: '', url: ''), '');
      }

      widget.onSentMessage(widget.controller.text);
      widget.controller.clear();
    } else {
      _init();
      if (widget._currentStatus == RecordingStatus.Initialized) {
        widget.helper.soundPlay("assets/sounds/s2.mp3");
        _start();
        setState(() {
          visibleClear = true;
          //widget._currentStatus = RecordingStatus.Stopped;
        });
      }
      if (widget._currentStatus == RecordingStatus.Unset) {
        widget.helper.soundPlay("assets/sounds/s2.mp3");
        _start();
        setState(() {
          visibleClear = true;
          //widget._currentStatus = RecordingStatus.Stopped;
          print(widget._currentStatus);
          // visibilityCancelRecord = true;
        });
      }
      if (widget._currentStatus == RecordingStatus.Recording) {
        visibleClear = true;
        widget.helper.soundPlay("assets/sounds/s4.mp3");
        setState(() {
          widget._currentStatus = RecordingStatus.Stopped;
          widget._currentStatus != RecordingStatus.Unset ? _init() : nun();
        });
      }
      print("widget._currentStatus");
      print(widget._currentStatus.toString());
    }
  }

  sendTextMessage(String content, HomeConversationModel homeConversationModel,
      UrlMessage url, String voiceUrl) async {
    String videoThumbnail;

    MessageData1 message;
    message = MessageData1(
      content: content,
      created: FieldValue.serverTimestamp(),
      senderFirstName: MyAppState.currentUser.name,
      nameColor: MyAppState.currentUser.color,
      role: homeConversationModel.role != null
          ? homeConversationModel.role
          : "user",
      url: url,
      videoThumbnail: videoThumbnail,
      voiceUrl: voiceUrl,
      senderID: MyAppState.currentUser.userID,
      senderProfilePictureURL: MyAppState.currentUser.profilePictureURL,
    );

    if (await _checkChannelNullability(homeConversationModel)) {
      await widget._fireStoreUtils
          .sendMessage1(message, homeConversationModel.conversationModel);

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
    } else {
      //showAlertDialog(context, 'فشل الارسال', 'يرجى المحاولة مرة أخرى');
    }
  }

  Future<bool> _checkChannelNullability(
      HomeConversationModel homeConversationModel) async {
    if (homeConversationModel.conversationModel != null) {
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
          await widget._fireStoreUtils.createConversation(conversation);
      if (isSuccessful) {
        Firestore.instance
            .collection('CHANNELS')
            .document(conversation.id)
            .snapshots()
            .listen((c) {
          if (c.data != null)
            homeConversationModel.conversationModel =
                ConversationModel.fromJson(c.data);
        });
      }
      return isSuccessful;
    }
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
        widget._recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await widget._recorder.initialized;
        // after initialization
        var current = await widget._recorder.current(channel: 0);
        widget.voicePath = customPath;
        print(current);
        // should be "Initialized", if all working fine
        setState(() {
          widget._current = current;
          widget._currentStatus = current.status;
          print(widget._currentStatus);
        });
      } else {

      }
    } catch (e) {
      print(e);
    }
  }

  _start() async {
    await Future.delayed(const Duration(milliseconds: 900));

    try {
      await widget._recorder.start();
      var recording = await widget._recorder.current(channel: 0);
      setState(() {
        widget._current = recording;
      });

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer t) async {
        if (widget._currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = await widget._recorder.current(channel: 0);
        // print(current.status);
        if (current != null) {
          widget._current = current;
          widget._currentStatus = widget._current.status;
        }
      });
    } catch (e) {
      print(e);
    }
  }

  nun() {}

  _stop() async {
    var result = await widget._recorder.stop();

    if (result.path != null) {
      String urlVoice =
          (await widget._fireStoreUtils.uploadAudioToStorage(result.path));
      print(urlVoice);
      sendTextMessage('رسالة صوتية', widget.homeConversationModel,
          UrlMessage(mime: '', url: ''), urlVoice);
      setState(() {
        widget._current = result;
        widget._currentStatus = widget._current.status;
      });
    }
  }

  setButtonIcon() {
    if (widget.controller.text.trim().isNotEmpty) {
      widget.isSendButtonVisible = true;
    } else
      widget.isSendButtonVisible = false;
  }

  Future<bool> onBackPress() {
    setState(() {
      visibleClear = false;
      widget.helper.soundPlay("assets/sounds/s4.mp3");

      setState(() {
        widget._currentStatus = RecordingStatus.Stopped;
        widget._currentStatus != RecordingStatus.Unset ? _init() : nun();
      });
    });
    return Future.value(false);
  }
}
