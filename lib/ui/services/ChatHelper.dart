import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/model/MessageData1.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart' as Constants;
import '../../constants.dart';
import '../../main.dart';
import '../../model/BlockUserModel.dart';
import '../../model/ContactModel.dart';
import '../../model/ConversationModel.dart';
import '../../model/Friendship.dart';
import '../../model/HomeConversationModel.dart';
import '../../model/User.dart';
import 'FirebaseHelper.dart';

class ChatHelper {
  static Firestore firestore = Firestore.instance;
  static DocumentReference currentUserDocRef =
      firestore.collection(USERS).document(MyAppState.currentUser.userID);
  StorageReference storage = FirebaseStorage.instance.ref();
  List<Friendship> friendshipList = [];
  List<Friendship> pendingList = [];
  List<Friendship> receivedRequests = [];
  List<ContactModel> contactsList = [];
  StreamController<List<HomeConversationModel>> conversationsStream;
  List<HomeConversationModel> homeConversations = [];
  List<BlockUserModel> blockedList = [];
  List<User> friends = [];
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();

  Future<void> updateRoleMember(String membrerID, String name,
      HomeConversationModel homeConversationModel, String role) async {
    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: homeConversationModel.conversationModel.id)
        .where('user', isEqualTo: membrerID)
        .getDocuments()
        .then((onValue) async {
      print(onValue.documents.first.documentID);
      await firestore
          .collection(CHANNEL_PARTICIPATION)
          .document(onValue.documents.first.documentID)
          .updateData({'role': role}).then((onValue) {});
    });
    String message;
    switch (role) {
      case "member":
        message = "تم ارجاع " + name + "كعضو عادي في الغرفة";
        break;
      case "owner":
        message = "تم تعيين " + name + "كأونر  في الغرفة";
        break;
      case "supervisor":
        message = "تم تعيين" + name + " كمشرف لهذه الغرفة ";
    }
    sendMessage(message, UrlMessage(mime: '', url: ''), '', '', 'notify',
        homeConversationModel);
  }

  sendMessage(
      String content,
      UrlMessage url,
      String videoThumbnail,
      String voiceUrl,
      String notify,
      HomeConversationModel homeConversationModel) async {
    MessageData1 message;
    if (homeConversationModel.isGroupChat) {
      message = MessageData1(
          content: content,
          created: FieldValue.serverTimestamp(),
          senderFirstName: MyAppState.currentUser.name,
          senderID: MyAppState.currentUser.userID,
          nameColor: MyAppState.currentUser.color,
          senderProfilePictureURL: MyAppState.currentUser.profilePictureURL,
          url: url,
          videoThumbnail: videoThumbnail,
          voiceUrl: voiceUrl,
          notify: notify);
    }

    if (url != null) {
      if (url.mime.contains('image')) {
        message.content = '${MyAppState.currentUser.name} sent an image';
      } else if (url.mime.contains('video')) {
        message.content = '${MyAppState.currentUser.name} sent a video';
      }
    }
    if (await _checkChannelNullability(homeConversationModel)) {
      await _fireStoreUtils.sendMessage(
          message, homeConversationModel.conversationModel);
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

      //homeConversationModel.conversationModel.lastMessageDate =FieldValue.serverTimestamp();
      homeConversationModel.conversationModel.lastMessage = message.content;

      await _fireStoreUtils.updateChannel(conversationModel2);
    } else {}
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
          await _fireStoreUtils.createConversation(conversation);
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

  Future<bool> leaveGroup(String userID, String name,
      HomeConversationModel homeConversationModel) async {
    bool isSuccessful = false;

    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: homeConversationModel.conversationModel.id)
        .where('user', isEqualTo: userID)
        .getDocuments()
        .then((onValue) async {
      await firestore
          .collection(CHANNEL_PARTICIPATION)
          .document(onValue.documents.first.documentID)
          .updateData({'active': false, 'expulsion': true});

      isSuccessful = true;
    });
    String message = "تم طرد " + name;
    sendMessage(message, UrlMessage(mime: '', url: ''), '', '', 'notify',
        homeConversationModel);
    _sendNotification(
        userID, "leaveGroup", homeConversationModel.conversationModel.name);

    return isSuccessful;
  }

  Future<bool> blockGroup(String userID, String name,
      HomeConversationModel homeConversationModel) async {
    bool isSuccessful = false;

    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: homeConversationModel.conversationModel.id)
        .where('user', isEqualTo: userID)
        .getDocuments()
        .then((onValue) async {
      await firestore
          .collection(CHANNEL_PARTICIPATION)
          .document(onValue.documents.first.documentID)
          .updateData({'active': false, 'expulsion': true, 'block': true});

      isSuccessful = true;
    });
    String message = "تم حظر " + name;
    sendMessage(message, UrlMessage(mime: '', url: ''), '', '', 'notify',
        homeConversationModel);
    _sendNotification(
        userID, "leaveGroup", homeConversationModel.conversationModel.name);

    return isSuccessful;
  }

  Future<void> updateGroupDescription(String groupID, String description,
      HomeConversationModel homeConversationModel) async {
    await firestore
        .collection(CHANNELS)
        .document(groupID)
        .updateData({'description': description});
    homeConversationModel.conversationModel.description = description;
    sendMessage("قام بتعديل وصف الغرفة", UrlMessage(mime: '', url: ''), '', '',
        'notify', homeConversationModel);
  }

  Future<void> sendNotifyMessage(
      HomeConversationModel homeConversationModel, String message) async {
    sendMessage(message, UrlMessage(mime: '', url: ''), '', '', 'notify',
        homeConversationModel);
  }

  Future<void> _sendNotification(
      String userID, String action, String nameGroup) async {
    await http.post(Constants.URL_HOSTING_API + Constants.URL_ACTIONS, body: {
      "userID": userID,
      "action": action,
      "nameGroup": nameGroup,
    });
  }

  Future<void> updateCallStatus(String callID, String status) async {
    await firestore
        .collection(CALLS)
        .document(callID)
        .updateData({'status': status});
  }
}
