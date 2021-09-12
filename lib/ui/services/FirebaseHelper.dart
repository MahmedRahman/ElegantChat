import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/model/CallsModel.dart';
import 'package:elegant/model/MessageData1.dart';
import 'package:elegant/ui/chat/CallReceiverScreen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../constants.dart';
import '../../constants.dart' as Constants;
import '../../main.dart';
import '../../model/BlockUserModel.dart';
import '../../model/ChannelModel.dart';
import '../../model/ChannelParticipation.dart';
import '../../model/ChatModel.dart';
import '../../model/ChatVideoContainer.dart';
import '../../model/ContactModel.dart';
import '../../model/ConversationModel.dart';
import '../../model/Friendship.dart';
import '../../model/GroupModel.dart';
import '../../model/HomeConversationModel.dart';
import '../../model/MessageData.dart';
import '../../model/User.dart';
import '../../ui/utils/helper.dart';

class FireStoreUtils {
  static Firestore firestore = Firestore.instance;
  static DocumentReference currentUserDocRef =
      firestore.collection(USERS).document(MyAppState.currentUser.userID);
  StorageReference storage = FirebaseStorage.instance.ref();
  List<Friendship> friendshipList = [];
  List<Friendship> pendingList = [];
  List<Friendship> receivedRequests = [];
  List<ContactModel> contactsList = [];
  List<ContactModel> newContactsList = [];
  List<User> userList = [];
  List<GroupModel> groupList = [];
  List<BlockUserModel> blockList = [];
  StreamController<List<HomeConversationModel>> conversationsStream;
  StreamController<List<GroupModel>> groupStream;
  StreamController<List<ChannelModel>> channelStream;

  List<HomeConversationModel> homeConversations = [];

  List<GroupModel> homeChannels = [];
  List<ConversationModel> homeConversations2 = [];
  List<BlockUserModel> blockedList = [];
  List<User> friends = [];

  Future<User> getCurrentUser(String userID) async {
    DocumentSnapshot userDocument =
        await firestore.collection(USERS).document(userID).get();
    if (userDocument != null && userDocument.exists) {
      return User.fromJson(userDocument.data);
    } else {
      return null;
    }
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

  Stream<CallsModel> getCalls(BuildContext context, String userID) async* {
    StreamController<CallsModel> callsModelStreamController =
        StreamController();
    CallsModel callModel = CallsModel();
    List<CallsModel> listOfcalls = [];
    firestore
        .collection("calls")
        .where('user2', isEqualTo: userID)
        .snapshots()
        .listen((onData) {
      onData.documents.forEach((document) async {
        listOfcalls.add(CallsModel.fromJson(document.data));
        if (document.data.isNotEmpty) {
          if (document.data["status"] == "wait") {
            await firestore
                .collection(CALLS)
                .document(document.documentID)
                .updateData({'status': "read"});
            Navigator.of(context).push(new MaterialPageRoute(
                builder: (BuildContext context) => new CallReceiverScreen(
                    callModel: CallsModel.fromJson(document.data))));
            listOfcalls.clear();
          }
        }
      });

      callsModelStreamController.sink.add(callModel);
    });

    yield* callsModelStreamController.stream;
  }

  Future<User> updateCurrentUser(User user, BuildContext context) async {
    return await firestore
        .collection(USERS)
        .document(user.userID)
        .setData(user.toJson())
        .then((document) {
      return user;
    }, onError: (e) {
      print(e);
      showAlertDialog(context, 'Error', 'Failed to Update, Please try again.');
      return null;
    });
  }

  Future<String> uploadUserImageToFireStorage(File image, String userID) async {
    StorageReference upload = storage.child("images/$userID.png");
    StorageUploadTask uploadTask = upload.putFile(image);
    var downloadUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  Future<String> uploadAudioToStorage(String path) async {
    var uniqueID = Uuid().v4();
    StorageReference upload = storage.child("chatAudios/$uniqueID.wav");
    StorageUploadTask uploadTask = upload.putFile(File(path));
    //  Uri downloadUrl = (await uploadTask.onComplete).uploadSessionUri;
    var downloadUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  Future<UrlMessage> uploadChatImageToFireStorage(
      File image, BuildContext context) async {
    showProgress(context, 'Uploading image...', false);
    var uniqueID = Uuid().v4();
    StorageReference upload = storage.child("images/$uniqueID.png");
    StorageUploadTask uploadTask = upload.putFile(image);
    uploadTask.events.listen((event) {
      updateProgress(
          'Uploading image ${(event.snapshot.bytesTransferred.toDouble() / 1000).toStringAsFixed(2)} /'
          '${(event.snapshot.totalByteCount.toDouble() / 1000).toStringAsFixed(2)} '
          'KB');
    });
    uploadTask.onComplete.catchError((onError) {
      print((onError as PlatformException).message);
    });
    var storageRef = (await uploadTask.onComplete).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    hideProgress();
    return UrlMessage(mime: metaData.contentType, url: downloadUrl.toString());
  }

  Future<ChatVideoContainer> uploadChatVideoToFireStorage(
      File video, BuildContext context) async {
    showProgress(context, 'تحميل الفيديو ...', false);
    var uniqueID = Uuid().v4();
    StorageReference upload = storage.child("videos/$uniqueID.mp4");
    StorageMetadata metadata = StorageMetadata(contentType: 'video');
    StorageUploadTask uploadTask = upload.putFile(video, metadata);
    uploadTask.events.listen((event) {
      updateProgress(
          'Uploading video ${(event.snapshot.bytesTransferred.toDouble() / 1000).toStringAsFixed(2)} /'
          '${(event.snapshot.totalByteCount.toDouble() / 1000).toStringAsFixed(2)} '
          'KB');
    });
    var storageRef = (await uploadTask.onComplete).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    final uint8list = await VideoThumbnail.thumbnailFile(
        video: downloadUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.PNG);
    final file = File(uint8list);
    String thumbnailDownloadUrl = await uploadVideoThumbnailToFireStorage(file);
    hideProgress();
    return ChatVideoContainer(
        videoUrl: Url(url: downloadUrl.toString(), mime: metaData.contentType),
        thumbnailUrl: thumbnailDownloadUrl);
  }

  Future<String> uploadVideoThumbnailToFireStorage(File file) async {
    var uniqueID = Uuid().v4();
    StorageReference upload = storage.child("thumbnails/$uniqueID.png");
    StorageUploadTask uploadTask = upload.putFile(file);
    var downloadUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  Future<List<User>> getUserMerchant(String userID) async {
    List userMerchantList = List<User>();
    await firestore
        .collection("users")
        .where('merchantID', isEqualTo: userID)
        .getDocuments()
        .then((querysnapShot) {
      querysnapShot.documents.forEach((doc) {
        User user = User.fromJson(doc.data);
        if (user.userID.isEmpty) {
          user.userID = doc.documentID;
        }
        userMerchantList.add(user);
      });
    });

    return userMerchantList.toSet().toList();
  }


  Future<List<User>> getFriendshipRequests(
      String userID, bool searchScreen) async {
    //pendingList = await getPendingRequests(userID);

    await firestore
        .collection(PENDING_FRIENDSHIPS)
        .where('user2', isEqualTo: userID)
        .getDocuments()
        .then((querysnapShot) {
      querysnapShot.documents.forEach((doc) async {
        Friendship friendship = Friendship.fromJson(doc.data);
        print(friendship.id);
        if (friendship.id.isNotEmpty ) {
          User u1 = await getUser(friendship.user1);
          userList.add(u1);
          print(userList.length);
        }

      });
    });
    return userList.toSet().toList();
  }
  Future<List<ContactModel>> getContacts(
      String userID, bool searchScreen) async {
    friendshipList = await getFriends(userID);
    pendingList = await getPendingRequests(userID);
    receivedRequests = await getReceivedRequests(userID);

    contactsList = List();
    await firestore.collection(USERS).getDocuments().then((onValue) {
      onValue.documents.asMap().forEach((index, user) async {
        bool isUnknown = true;
        if (user.documentID != userID) {
          if (friendshipList.isNotEmpty) {
            for (final friend in friendshipList) {
              if (user.documentID == friend.user1 ||
                  user.documentID == friend.user2) {
                isUnknown = false;
                User contact = User.fromJson(user.data);
                if (contact.userID.isEmpty) contact.userID = user.documentID;
                bool blocked = validateIfUserBlocked(contact.userID);
                print("blocked");
                print(blocked);
                if (blocked) {
                  // contactsList.add(
                  //     ContactModel(type: ContactType.BLOCKED, user: contact));
                } else {
                  contactsList.add(
                      ContactModel(type: ContactType.FRIEND, user: contact));
                }
                break;
              }
            }
          }
          if (pendingList.isNotEmpty) {
            for (final pendingRequest in pendingList) {
              if (pendingRequest.user2 == user.documentID) {
                isUnknown = false;
                User contact = User.fromJson(user.data);
                if (contact.userID.isEmpty) contact.userID = user.documentID;
                contactsList.add(
                    ContactModel(type: ContactType.PENDING, user: contact));
                break;
              }
            }
          }
          if (receivedRequests.isNotEmpty) {
            for (final newFriendRequest in receivedRequests) {
              if (newFriendRequest.user1 == user.documentID) {
                isUnknown = false;
                User contact = User.fromJson(user.data);
                if (contact.userID.isEmpty) contact.userID = user.documentID;
                contactsList
                    .add(ContactModel(type: ContactType.ACCEPT, user: contact));
                break;
              }
            }
          }
          if (isUnknown && searchScreen) {
            User contact = User.fromJson(user.data);
            if (contact.userID.isEmpty) contact.userID = user.documentID;
            contactsList
                .add(ContactModel(type: ContactType.UNKNOWN, user: contact));
          }
        }
      });
    }, onError: (e) {
      print('error $e');
    });

    return contactsList.toSet().toList();
  }

  Future<List<ContactModel>> getContactsBlocked(String userID) async {
    contactsList = List();
    firestore
        .collection(REPORTS)
        .where('source', isEqualTo: MyAppState.currentUser.userID)
        .snapshots()
        .listen((onData) async {
      // List<BlockUserModel> list = [];
      for (DocumentSnapshot block in onData.documents) {
        print("block.documentID");
        print(block.data["dest"]);
        DocumentSnapshot userDocument = await firestore
            .collection(USERS)
            .document(block.data["dest"])
            .get();
        if (userDocument != null && userDocument.exists) {
          print("name");
          print(userDocument.data["name"]);
          contactsList.add(ContactModel(
              type: ContactType.BLOCKED,
              user: User.fromJson(userDocument.data)));
        }
      }
    });

    await firestore.collection(USERS).getDocuments().then((onValue) {
      onValue.documents.asMap().forEach((index, user) async {});
    }, onError: (e) {
      print('error $e');
    });

    return contactsList.toSet().toList();
  }

  Future<List<GroupModel>> searchGroup(String keyword) async {
    groupList = List();

    groupList.clear();
    await firestore
        .collection(CHANNELS)
        .orderBy('name')
        .startAt([keyword])
        .endAt([keyword + '\uf8ff'])
        .getDocuments()
        .then((onValue) {
          onValue.documents.asMap().forEach((index, group) async {
            print(group.documentID);
            GroupModel groupModel = new GroupModel();
            GroupModel g = GroupModel.fromJson(group.data);
            groupModel.currentNumberMembers = 0;
            groupModel.description = g.description;
            groupModel.creatorID = g.creatorID;
            groupModel.name = g.name;
            groupModel.distinguishedArrangement = g.distinguishedArrangement;
            groupModel.especially = g.especially;
            groupModel.lastMessage = g.lastMessage;
            groupModel.msgCount = g.msgCount;
            groupModel.id = g.id;
            groupModel.normalArrangement = g.normalArrangement;
            groupModel.numberOfMembers = g.numberOfMembers;
            groupModel.readCount = g.readCount;

            groupList.add(groupModel);
          });
        });
    return groupList.toSet().toList();
  }

  Future<List<ContactModel>> searchContacts(
      String userID, String keyword) async {
    friendshipList = await getFriends(userID);
    pendingList = await getPendingRequests(userID);
    receivedRequests = await getReceivedRequests(userID);
    contactsList = List();
    await firestore
        .collection(USERS)
        .orderBy('name')
        .startAt([keyword])
        .endAt([keyword + '\uf8ff'])
        .getDocuments()
        .then((onValue) {
          onValue.documents.asMap().forEach((index, user) async {
            bool isUnknown = true;
            if (user.documentID != userID) {
              if (friendshipList.isNotEmpty) {
                for (final friend in friendshipList) {
                  if (user.documentID == friend.user1 ||
                      user.documentID == friend.user2) {
                    isUnknown = false;
                    User contact = User.fromJson(user.data);
                    if (contact.userID.isEmpty)
                      contact.userID = user.documentID;

                    bool isBlocked = validateIfUserBlocked(contact.userID);
                    if (isBlocked) {
                    } else {
                      contactsList.add(ContactModel(
                          type: ContactType.FRIEND, user: contact));
                    }

                    break;
                  }
                }
              }
              if (pendingList.isNotEmpty) {
                for (final pendingRequest in pendingList) {
                  if (pendingRequest.user2 == user.documentID) {
                    isUnknown = false;
                    User contact = User.fromJson(user.data);
                    if (contact.userID.isEmpty)
                      contact.userID = user.documentID;
                    bool isBlocked = validateIfUserBlocked(contact.userID);
                    if (isBlocked) {
                    } else {
                      contactsList.add(ContactModel(
                          type: ContactType.PENDING, user: contact));
                    }
                    break;
                  }
                }
              }
              if (receivedRequests.isNotEmpty) {
                for (final newFriendRequest in receivedRequests) {
                  if (newFriendRequest.user1 == user.documentID) {
                    isUnknown = false;
                    User contact = User.fromJson(user.data);
                    if (contact.userID.isEmpty)
                      contact.userID = user.documentID;
                    bool isBlocked = validateIfUserBlocked(contact.userID);
                    if (isBlocked) {
                    } else {
                      contactsList.add(ContactModel(
                          type: ContactType.ACCEPT, user: contact));
                    }
                    break;
                  }
                }
              }
              if (isUnknown) {
                User contact = User.fromJson(user.data);
                if (contact.userID.isEmpty) contact.userID = user.documentID;
                bool isBlocked = validateIfUserBlocked(contact.userID);
                if (isBlocked) {
                } else {
                  contactsList.add(
                      ContactModel(type: ContactType.UNKNOWN, user: contact));
                }
              }
              // newContactsList=contactsList;
              // contactsList.removeWhere((ContactModelToDelete) {
              //   return newContactsList[index].user.userID  ==
              //       ContactModelToDelete.user.userID;
              // });
            }
          });
        }, onError: (e) {
          print('error $e');
        });
    return contactsList.toSet().toList();
  }

  Future<List<Friendship>> getFriends(String userID) async {
    List friendshipList = List<Friendship>();
    await firestore
        .collection(FRIENDSHIP)
        .where('user1', isEqualTo: userID)
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
    await firestore
        .collection(FRIENDSHIP)
        .where('user2', isEqualTo: userID)
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

    return friendshipList.toSet().toList();
  }

  Future<List<Friendship>> getPendingRequests(String userID) async {
    List pendingList = List<Friendship>();
    await firestore
        .collection(PENDING_FRIENDSHIPS)
        .where('user1', isEqualTo: userID)
        .getDocuments()
        .then((onValue) {
      onValue.documents.forEach((document) {
        Friendship friendship = Friendship.fromJson(document.data);
        if (friendship.id.isEmpty) {
          friendship.id = document.documentID;
        }
        pendingList.add(friendship);
      });
    });
    return pendingList.toSet().toList();
  }
  Future<List<Friendship>> getPendingRequests1(String userID) async {
    List pendingList = List<Friendship>();
    await firestore
        .collection(PENDING_FRIENDSHIPS)
        .where('user2', isEqualTo: userID)
        .getDocuments()
        .then((onValue) {
      onValue.documents.forEach((document) {
        Friendship friendship = Friendship.fromJson(document.data);
        if (friendship.id.isEmpty) {
          friendship.id = document.documentID;
        }
        pendingList.add(friendship);
      });
    });
    return pendingList.toSet().toList();
  }
  Future<List<Friendship>> getPendingRequests2(String userID) async {
    List pendingList = List<Friendship>();
    await firestore
        .collection(PENDING_FRIENDSHIPS)
        .where('user1', isEqualTo: userID)
        .getDocuments()
        .then((onValue) {
      onValue.documents.forEach((document) {
        Friendship friendship = Friendship.fromJson(document.data);
        if (friendship.id.isEmpty) {
          friendship.id = document.documentID;
        }
        pendingList.add(friendship);
      });
    });
    return pendingList.toSet().toList();
  }
  Future<List<Friendship>> getReceivedRequests(String userID) async {
    List<Friendship> receivedRequests = List<Friendship>();
    await firestore
        .collection(PENDING_FRIENDSHIPS)
        .where('user2', isEqualTo: userID)
        .getDocuments()
        .then((onValue) {
      onValue.documents.forEach((document) {
        Friendship friendship = Friendship.fromJson(document.data);
        if (friendship.id.isEmpty) {
          friendship.id = document.documentID;
        }
        receivedRequests.add(friendship);
      });
    });
    return receivedRequests.toSet().toList();
  }

  Future<bool> onFriendAccept(
      User pendingUser, String myID, bool searchScreen) async {
    receivedRequests = await getReceivedRequests(myID);
    sentNotification(pendingUser.userID, 'abc', "AcceptFriendRequest", 'abc');
    Friendship friendship = Friendship();
    friendship.user1 = pendingUser.userID;
    friendship.user2 = myID;
    friendship.createdAt = Timestamp.now();

    print(myID);
    print(pendingUser.userID);
    bool isSuccessful;
    for (final receivedRequest in receivedRequests) {
      if (receivedRequest.user1 == pendingUser.userID &&
          receivedRequest.user2 == myID) {
        isSuccessful =
            await removePending(receivedRequest.id, friendship, pendingUser);
        if (isSuccessful) {
          receivedRequests.remove(receivedRequest);
          friendshipList.add(friendship);
        }
        break;
      }
    }
    return isSuccessful;
  }

  Future<bool> removePending(
      String pendingID, Friendship friendship, User pendingUser) async {
    bool isSuccessful;
    await firestore
        .collection(PENDING_FRIENDSHIPS)
        .document(pendingID)
        .delete()
        .then((onValue) async {
      DocumentReference doc = firestore.collection(FRIENDSHIP).document();
      friendship.id = doc.documentID;
      await doc.setData(friendship.toJson()).then((onValue) {
        isSuccessful = true;
      }, onError: (e) {
        print('${e.toString()}');
        isSuccessful = false;
      });
    }, onError: (e) {
      print('${e.toString()}');
      isSuccessful = false;
    });
    return isSuccessful;
  }

  Future<bool> onUnFriend(User friend, String myID, bool searchScreen) async {
    bool isSuccessful=false;
    friendshipList = await getFriends(myID);
    for (final friendship in friendshipList) {
      if ((friendship.user1 == friend.userID && friendship.user2 == myID) ||
          (friendship.user2 == friend.userID && friendship.user1 == myID)) {
        isSuccessful = await removeFriend(friendship.id);
        if (isSuccessful) {
          friendshipList.remove(friendship);
          if (searchScreen) {
            userList
                .add( friend);
          }
        }
        break;
      }
    }
    return isSuccessful;
  }

  Future<bool> removeFriend(String id) async {
    bool isSuccessful;
    await firestore.collection(FRIENDSHIP).document(id).delete().then(
        (onValue) {
      isSuccessful = true;
    }, onError: (e) {
      print('${e.toString()}');
      isSuccessful = false;
    });
    return isSuccessful;
  }
  Future<bool> onCancelRequest(
      String contactID, String userID, bool searchScreen) async {
    bool isSuccessful;
    pendingList = await getPendingRequests1(userID);
    print(pendingList.length);

    for (Friendship request in pendingList) {
      print(request.user1);
      print(userID);
      print(request.user2);
      print(contactID);
      print(request.id);
      if (request.user1 == contactID && request.user2 == userID) {
        print("yessssssssss");
        await firestore
            .collection(PENDING_FRIENDSHIPS)
            .document(request.id)
            .delete()
            .then((onValue) {
          pendingList.remove(request);
          // if (searchScreen) {
          //   contactsList
          //       .add(ContactModel(type: ContactType.UNKNOWN, user: user));
          // }
          isSuccessful = true;
        }, onError: (e) {
          isSuccessful = false;
        });
        break;
      }

    }

    return isSuccessful;
  }

  Future<bool> onCancelRequestSend(
      String contactID, String userID, bool searchScreen) async {
    bool isSuccessful;
    pendingList = await getPendingRequests2(userID);
    print(pendingList.length);

    for (Friendship request in pendingList) {
      print(request.user1);
      print(userID);
      print(request.user2);
      print(contactID);
      print(request.id);
      if (request.user1 == userID && request.user2 == contactID) {
        print("yessssssssss");
        await firestore
            .collection(PENDING_FRIENDSHIPS)
            .document(request.id)
            .delete()
            .then((onValue) {
          pendingList.remove(request);
          // if (searchScreen) {
          //   contactsList
          //       .add(ContactModel(type: ContactType.UNKNOWN, user: user));
          // }
          isSuccessful = true;
        }, onError: (e) {
          isSuccessful = false;
        });
        break;
      }

    }

    return isSuccessful;
  }

  Future<bool> onUnBlock(User user, String userID, bool searchScreen) async {
    bool isSuccessful;
    await firestore
        .collection(REPORTS)
        .where("source", isEqualTo: userID)
        .where("dest", isEqualTo: user.userID)
        .getDocuments()
        .then((onValue) async {
      await firestore
          .collection(REPORTS)
          .document(onValue.documents.first.documentID)
          .delete()
          .then((onValue) {
        isSuccessful = true;
      }, onError: (e) {
        isSuccessful = false;
      });
    });
    return isSuccessful;
  }

  Future<bool> sendFriendRequest(User user, String myID) async {
    bool isSuccessful;
    sentNotification(user.userID, 'abc', "FriendRequest", 'abc');
    DocumentReference documentReference =
        firestore.collection(PENDING_FRIENDSHIPS).document();
    Friendship friendship = Friendship();
    friendship.id = documentReference.documentID;
    friendship.user1 = myID;
    friendship.user2 = user.userID;
    friendship.createdAt = Timestamp.now();
    await documentReference.setData(friendship.toJson()).then((onValue) {
      pendingList.add(friendship);
      isSuccessful = true;
    }, onError: (e) {
      isSuccessful = false;
    });
    return isSuccessful;
  }

  Future<List<User>> getFriendsUserObject(String userID) async {
    List<User> friendsObj = [];
    List<String> friendIDs = [];
    friendshipList.clear();
    friendshipList = await getFriends(userID);
    friendshipList.forEach((friendship) {
      if (friendship.user1 == userID) {
        friendIDs.add(friendship.user2);
      } else {
        friendIDs.add(friendship.user1);
      }
    });
    for (String id in friendIDs) {
      await firestore.collection(USERS).document(id).get().then((user) {
        friendsObj.add(User.fromJson(user.data));
      });
    }
    print(friendsObj);
    return friendsObj;
  }

  Future<List<User>> getFriendsUserObject2(
      String userID, String groupID) async {
    List<User> friendsObj2 = [];
    List<String> friendIDs2 = [];
    List<ChannelParticipation> channelParticipation = [];
    friendshipList.clear();
    friendshipList = await getFriends(userID);
    friendshipList.forEach((friendship) {
      if (friendship.user1 == userID) {
        friendIDs2.add(friendship.user2);
      } else {
        friendIDs2.add(friendship.user1);
      }
    });
    for (String id in friendIDs2) {
      print(id);
      await firestore
          .collection(CHANNEL_PARTICIPATION)
          .where('channel', isEqualTo: groupID)
          .where('user', isEqualTo: id)
          .getDocuments()
          .then((querysnapShot) async {
        if (querysnapShot.documents.isNotEmpty) {
        } else {
          await firestore.collection(USERS).document(id).get().then((user) {
            friendsObj2.add(User.fromJson(user.data));
          });
        }
      });
    }

    return friendsObj2;
  }

  Stream<List<HomeConversationModel>> getConversations2(String userID) async* {
    conversationsStream = StreamController<List<HomeConversationModel>>();
    HomeConversationModel newHomeConversation;

    firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('user', isEqualTo: userID)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.documents.isEmpty) {
        conversationsStream.sink.add(homeConversations);
      } else {
        homeConversations.clear();
        Future.forEach(querySnapshot.documents, (DocumentSnapshot document) {
          if (document != null && document.exists) {
            ChannelParticipation participation =
                ChannelParticipation.fromJson(document.data);
            firestore
                .collection(CHANNELS)
                .document(participation.channel)
                .snapshots()
                .listen((channel) async {
              if (channel != null && channel.exists) {
                bool isGroupChat = !channel.documentID.contains(userID);
                List<User> users = [];
                if (isGroupChat) {
                  getGroupMembers(channel.documentID).listen((listOfUsers) {
                    if (listOfUsers.isNotEmpty) {
                      users = listOfUsers;
                      newHomeConversation = HomeConversationModel(
                        conversationModel:
                            ConversationModel.fromJson(channel.data),
                        isGroupChat: isGroupChat,
                        members: users,
                        participentId: document.documentID,
                        readCount: participation.readCount,
                        role: participation.role,
                      );

                      if (newHomeConversation.conversationModel.id.isEmpty)
                        newHomeConversation.conversationModel.id =
                            channel.documentID;

                      homeConversations
                          .removeWhere((conversationModelToDelete) {
                        return newHomeConversation.conversationModel.id ==
                            conversationModelToDelete.conversationModel.id;
                      });
                      homeConversations.add(newHomeConversation);
                      homeConversations.sort((a, b) => a
                          .conversationModel.lastMessageDate
                          .compareTo(b.conversationModel.lastMessageDate));
                      conversationsStream.sink
                          .add(homeConversations.reversed.toList());
                    }
                  });
                } else {
                  getUserByID(channel.documentID.replaceAll(userID, ''))
                      .listen((user) {
                    users.clear();
                    users.add(user);
                    newHomeConversation = HomeConversationModel(
                      conversationModel:
                          ConversationModel.fromJson(channel.data),
                      isGroupChat: isGroupChat,
                      members: users,
                      participentId: document.documentID,
                      readCount: participation.readCount,
                      role: participation.role,
                    );

                    if (newHomeConversation.conversationModel.id.isEmpty)
                      newHomeConversation.conversationModel.id =
                          channel.documentID;

                    homeConversations.removeWhere((conversationModelToDelete) {
                      return newHomeConversation.conversationModel.id ==
                          conversationModelToDelete.conversationModel.id;
                    });

                    homeConversations.add(newHomeConversation);
                    homeConversations.sort((a, b) => a
                        .conversationModel.lastMessageDate
                        .compareTo(b.conversationModel.lastMessageDate));
                    conversationsStream.sink
                        .add(homeConversations.reversed.toList());
                  });
                }
              }
            });
          }
        });
      }
    });
    yield* conversationsStream.stream;
  }

  Stream<List<HomeConversationModel>> getConversations(String userID) async* {
    conversationsStream = StreamController<List<HomeConversationModel>>();
    HomeConversationModel newHomeConversation;

    firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('user', isEqualTo: userID)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.documents.isEmpty) {
        conversationsStream.sink.add(homeConversations);
      } else {
        homeConversations.clear();
        Future.forEach(querySnapshot.documents, (DocumentSnapshot document) {
          if (document != null && document.exists) {
            ChannelParticipation participation =
                ChannelParticipation.fromJson(document.data);
            firestore
                .collection(CHANNELS)
                .document(participation.channel)
                .snapshots()
                .listen((channel) async {
              if (channel != null && channel.exists) {
                bool isGroupChat = !channel.documentID.contains(userID);
                List<User> users = [];

                getUserByID(channel.documentID.replaceAll(userID, ''))
                    .listen((user) {
                  users.clear();
                  users.add(user);
                  if (!isGroupChat) {
                    newHomeConversation = HomeConversationModel(
                      conversationModel:
                          ConversationModel.fromJson(channel.data),
                      isGroupChat: isGroupChat,
                      members: users,
                      participentId: document.documentID,
                      readCount: participation.readCount,
                      role: participation.role,
                    );
                  }
                  if (newHomeConversation.conversationModel.id.isEmpty)
                    newHomeConversation.conversationModel.id =
                        channel.documentID;

                  homeConversations.removeWhere((conversationModelToDelete) {
                    return newHomeConversation.conversationModel.id ==
                        conversationModelToDelete.conversationModel.id;
                  });

                  homeConversations.add(newHomeConversation);
                  homeConversations.sort((a, b) => a
                      .conversationModel.lastMessageDate
                      .compareTo(b.conversationModel.lastMessageDate));
                  conversationsStream.sink
                      .add(homeConversations.reversed.toList());
                });
              }
            });
          }
        });
      }
    });
    yield* conversationsStream.stream;
  }

  Stream<List<GroupModel>> getConversations3() async* {
    groupStream = StreamController<List<GroupModel>>();

    firestore
        .collection(CHANNELS)
        .orderBy('paidArrangement', descending: true)
        .snapshots()
        .listen((channel) {
      // homeChannels.clear();
      channel.documents.forEach((document) async {
        QuerySnapshot qSnap = await Firestore.instance
            .collection(CHANNEL_PARTICIPATION)
            .where('channel', isEqualTo: document.documentID)
            .where('active', isEqualTo: true)
            .getDocuments();
        int documents = qSnap.documents.length;

        GroupModel g = GroupModel.fromJson(document.data);
        g.currentNumberMembers = documents;
        g.paidArrangement = g.paidArrangement != null
            ? g.paidArrangement
            : DateTime(2018, 01, 13);

        homeChannels.removeWhere((GroupModelToDelete) {
          return g.id == GroupModelToDelete.id;
        });
        homeChannels.add(g);
        homeChannels
            .sort((a, b) => a.paidArrangement.compareTo(b.paidArrangement));
        groupStream.sink.add(homeChannels.reversed.toSet().toList());
      });
    });
    print(Timestamp.now().toString());
    yield* groupStream.stream;
  }

  Stream<ChannelParticipation> getChannelParticipationByID(String id) async* {
    StreamController<ChannelParticipation> userStreamController =
        StreamController();
    firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: id)
        .where('active', isEqualTo: true)
        .snapshots()
        .listen((channelParticipation) {
      if (channelParticipation.documents != null)
        userStreamController.sink.add(ChannelParticipation.fromJson(
            channelParticipation.documents.first.data));
    });
    yield* userStreamController.stream;
  }

  Stream<List<ChannelModel>> getConversationsGroup2() async* {
    channelStream = StreamController<List<ChannelModel>>();
    List<ChannelModel> listOfcalls = [];
    firestore
        .collection(CHANNELS)
        .orderBy('paidArrangement', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.documents.isNotEmpty) {
        // ChannelModel channelStream.sink.add(homeChannels);
      }
    });
    yield* channelStream.stream;
  }

  Stream<List<User>> getGroupMembers(String channelID) async* {
    StreamController<List<User>> membersStreamController = StreamController();
    getGroupMembersIDs(channelID).listen((memberIDs) {
      if (memberIDs.isNotEmpty) {
        List<User> groupMembers = [];
        for (String id in memberIDs) {
          getUserByID(id).listen((user) {
            groupMembers.add(user);
            membersStreamController.sink.add(groupMembers);
          });
        }
      } else {
        membersStreamController.sink.add([]);
      }
    });
    yield* membersStreamController.stream;
  }

  Stream<List<String>> getGroupMembersIDs(String channelID) async* {
    StreamController<List<String>> membersIDsStreamController =
        StreamController();
    firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: channelID)
        .snapshots()
        .listen((participations) {
      List<String> uids = [];
      for (DocumentSnapshot document in participations.documents) {
        uids.add(document.data['user'] ?? '');
      }
      if (uids.contains(MyAppState.currentUser.userID)) {
        membersIDsStreamController.sink.add(uids);
      } else {
        membersIDsStreamController.sink.add([]);
      }
    });
    yield* membersIDsStreamController.stream;
  }

  Stream<User> getUserByID(String id) async* {
    StreamController<User> userStreamController = StreamController();
    firestore.collection(USERS).document(id).snapshots().listen((user) {
      if (user.data != null)
        userStreamController.sink.add(User.fromJson(user.data));
    });
    yield* userStreamController.stream;
  }

  Future<ConversationModel> getChannelByIdOrNull(String channelID) async {
    print('++++++++++++++++++++++++++++++++++++');
    print('channelID : ${channelID.toString()}');
    ConversationModel conversationModel;
    await firestore.collection(CHANNELS).document(channelID).get().then(
        (channel) {
      if (channel != null && channel.exists) {
        conversationModel = ConversationModel.fromJson(channel.data);
        // if(conversationModel.id != null){
        //
        // }else{
        //
        // }
      }
    }, onError: (e) {
      print((e as PlatformException).message);
    });

  //  print("test temp : ${conversationModel.id}");
    return conversationModel;
  }

  Stream<ChatModel> getChatMessages(
      HomeConversationModel homeConversationModel) async* {
    StreamController<ChatModel> chatModelStreamController = StreamController();
    ChatModel chatModel = ChatModel();
    List<MessageData> listOfMessages = [];
    List<User> listOfMembers = homeConversationModel.members;
    if (homeConversationModel.isGroupChat) {
      if (listOfMembers.isNotEmpty) {
        homeConversationModel.members.forEach((groupMember) {
          if (groupMember.userID != MyAppState.currentUser.userID) {
            getUserByID(groupMember.userID).listen((updatedUser) {
              for (int i = 0; i < listOfMembers.length; i++) {
                if (listOfMembers[i].userID == updatedUser.userID) {
                  listOfMembers[i] = updatedUser;
                }
              }
              chatModel.message = listOfMessages;
              chatModel.members = listOfMembers;
              chatModelStreamController.sink.add(chatModel);
            });
          }
        });
      }
    } else {
      User friend = homeConversationModel.members.first;
      getUserByID(friend.userID).listen((user) {
        listOfMembers.clear();
        listOfMembers.add(user);
        chatModel.message = listOfMessages;
        chatModel.members = listOfMembers;
        chatModelStreamController.sink.add(chatModel);
      });
    }
    if (homeConversationModel.conversationModel != null) {
      firestore
          .collection(CHANNELS)
          .document(homeConversationModel.conversationModel.id)
          .collection(THREAD)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((onData) {
        listOfMessages.clear();
        onData.documents.forEach((document) {
          listOfMessages.add(MessageData.fromJson(document.data));
        });
        chatModel.message = listOfMessages;
        chatModel.members = listOfMembers;
        chatModelStreamController.sink.add(chatModel);
      });
    }
    yield* chatModelStreamController.stream;
  }

  Stream<ChatModel> getChatGroupMessages(
      HomeConversationModel homeConversationModel) async* {
    StreamController<ChatModel> chatModelStreamController = StreamController();
    ChatModel chatModel = ChatModel();
    List<MessageData> listOfMessages = [];
    List<User> listOfMembers = homeConversationModel.members;
    getGroupMembers(homeConversationModel.conversationModel.id)
        .listen((listOfUsers) {
      if (listOfUsers.isNotEmpty) {
        listOfMembers = listOfUsers;
      }
    });
    if (homeConversationModel.isGroupChat) {
      if (listOfMembers.isNotEmpty) {
        homeConversationModel.members.forEach((groupMember) {
          if (groupMember.userID != MyAppState.currentUser.userID) {
            getUserByID(groupMember.userID).listen((updatedUser) {
              for (int i = 0; i < listOfMembers.length; i++) {
                if (listOfMembers[i].userID == updatedUser.userID) {
                  listOfMembers[i] = updatedUser;
                }
              }
              chatModel.message = listOfMessages;
              chatModel.members = listOfMembers;
              chatModelStreamController.sink.add(chatModel);
            });
          }
        });
      }
    }
    if (homeConversationModel.conversationModel != null &&
        homeConversationModel.members != null) {
      firestore
          .collection(CHANNELS)
          .document(homeConversationModel.conversationModel.id)
          .collection(THREAD)
          .where('createdAt', isGreaterThan: homeConversationModel.timeOfEntry)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((onData) {
        listOfMessages.clear();
        onData.documents.forEach((document) {
          listOfMessages.add(MessageData.fromJson(document.data));
        });
        chatModel.message = listOfMessages;
        chatModel.members = listOfMembers;
        chatModelStreamController.sink.add(chatModel);
      });
    }
    yield* chatModelStreamController.stream;
  }

  Future<void> sendMessage1(
      MessageData1 message, ConversationModel conversationModel) async {
    var ref = firestore
        .collection(CHANNELS)
        .document(conversationModel.id)
        .collection(THREAD)
        .document();
    message.messageID = ref.documentID;
    ref.setData(message.toJson());
  }

  Future<void> sendMessage(
      MessageData1 message, ConversationModel conversationModel) async {
    var ref = firestore
        .collection(CHANNELS)
        .document(conversationModel.id)
        .collection(THREAD)
        .document();
    message.messageID = ref.documentID;
    ref.setData(message.toJson());
  }

  Future<bool> createConversation(ConversationModel2 conversation) async {
    bool isSuccessful;
    await firestore
        .collection(CHANNELS)
        .document(conversation.id)
        .setData(conversation.toJson())
        .then((onValue) async {
      ChannelParticipation2 myChannelParticipation = ChannelParticipation2(
        user: MyAppState.currentUser.userID,
        channel: conversation.id,
        readCount: 0,
      );
      ChannelParticipation2 myFriendParticipation = ChannelParticipation2(
        user: conversation.id.replaceAll(MyAppState.currentUser.userID, ''),
        channel: conversation.id,
        readCount: 0,
      );
      await createChannelParticipation(myChannelParticipation);
      await createChannelParticipation(myFriendParticipation);
      //homeConversationModel.conversationModel = conversation;
      // Firestore.instance.collection('CHANNELS').document(conversation.id).snapshots().listen((c) {
      //   if (c.data != null)
      //     // conversationModel = ConversationModel.fromJson(c.data);
      //   // homeConversationModel.conversationModel.lastMessageDate = conversationModel.;
      //
      // });
      isSuccessful = true;
    }, onError: (e) {
      print((e as PlatformException).message);
      isSuccessful = false;
    });
    return isSuccessful;
  }
  Future<bool> createConversation2(ConversationModel  conversation) async {
    bool isSuccessful;
    await firestore
        .collection(CHANNELS)
        .document(conversation.id)
        .setData(conversation.toJson())
        .then((onValue) async {
      ChannelParticipation2 myChannelParticipation = ChannelParticipation2(
        user: MyAppState.currentUser.userID,
        channel: conversation.id,
        readCount: 0,
      );
      ChannelParticipation2 myFriendParticipation = ChannelParticipation2(
        user: conversation.id.replaceAll(MyAppState.currentUser.userID, ''),
        channel: conversation.id,
        readCount: 0,
      );
      await createChannelParticipation(myChannelParticipation);
      await createChannelParticipation(myFriendParticipation);
      //homeConversationModel.conversationModel = conversation;
      // Firestore.instance.collection('CHANNELS').document(conversation.id).snapshots().listen((c) {
      //   if (c.data != null)
      //     // conversationModel = ConversationModel.fromJson(c.data);
      //   // homeConversationModel.conversationModel.lastMessageDate = conversationModel.;
      //
      // });
      isSuccessful = true;
    }, onError: (e) {
      print((e as PlatformException).message);
      isSuccessful = false;
    });
    return isSuccessful;
  }

  Future<void> updateReadCount(id, readCount) async {
    print(id);
    print(readCount);
    if (readCount != null && id != null) {
      await firestore
          .collection(CHANNEL_PARTICIPATION)
          .document(id)
          .updateData({'readCount': readCount});
    }
  }

  Future<void> updateChannelName(
      ConversationModel conversationModel, String oldName) async {
    HomeConversationModel homeConversationModel;
    List<DocumentSnapshot> documentList;
    documentList = (await Firestore.instance
            .collection(CHANNELS)
            .where("name", isEqualTo: oldName)
            .getDocuments())
        .documents;

    if (documentList.length == 0) {
      await firestore
          .collection(CHANNELS)
          .document(conversationModel.id)
          .updateData(conversationModel.toJson());
    }
  }

  Future<void> updateChannel(ConversationModel2 conversationModel) async {
    await firestore
        .collection(CHANNELS)
        .document(conversationModel.id)
        .updateData(conversationModel.toJson());
  }

  Future<void> updateGroup(String groupID) async {
    await firestore.collection(CHANNELS).document(groupID).updateData({
      'normalArrangement': true,
      'paidArrangement': FieldValue.serverTimestamp()
    });
  }

  Future<void> updateUser(bool active, String userID) async {
    await firestore.collection(USERS).document(userID).updateData({
      'active': active,
      'lastOnlineTimestamp': FieldValue.serverTimestamp()
    });
  }

  Future<void> updateDateGroup(String userID) async {
    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .document(userID)
        .updateData({'timeOfEntry': Timestamp.now()});
  }

  Future<void> createChannelParticipation(
      ChannelParticipation2 channelParticipation) async {
    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .add(channelParticipation.toJson());
  }

  Future<void> updateChannelParticipation(String userID) async {
    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('user', isEqualTo: userID)
        .getDocuments()
        .then((onValue) {
      Future.forEach(onValue.documents, (DocumentSnapshot document) {
        firestore
            .collection(CHANNEL_PARTICIPATION)
            .document(document.documentID)
            .updateData({'active': false, 'expulsion': false});
        print(document.documentID);
      });
    });
  }

  Future<bool> leavingChannelParticipation(
      String userID, String channelId) async {
    bool isSuccessful;
    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('user', isEqualTo: userID)
        .where('channel', isEqualTo: channelId)
        .getDocuments()
        .then((onValue) {
      Future.forEach(onValue.documents, (DocumentSnapshot document) {
        firestore
            .collection(CHANNEL_PARTICIPATION)
            .document(document.documentID)
            .updateData({'active': false});
        isSuccessful = true;
      });
    });
    return isSuccessful;
  }

  Future<bool> unBlockParticipation(String userID, String channelId) async {
    bool isSuccessful;
    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('user', isEqualTo: userID)
        .where('channel', isEqualTo: channelId)
        .getDocuments()
        .then((onValue) {
      Future.forEach(onValue.documents, (DocumentSnapshot document) {
        firestore
            .collection(CHANNEL_PARTICIPATION)
            .document(document.documentID)
            .updateData({'block': false});
        isSuccessful = true;
      });
    });
    return isSuccessful;
  }

  Future<List<User>> getAllUsers() async {
    List<User> users = [];
    await firestore.collection(USERS).getDocuments().then((onValue) {
      Future.forEach(onValue.documents, (DocumentSnapshot document) {
        users.add(User.fromJson(document.data));
      });
    });
    return users;
  }

  Future<HomeConversationModel> createGroupChat(
      List<User> selectedUsers, String groupName, String description) async {
    HomeConversationModel groupConversationModel;
    DocumentReference channelDoc = firestore.collection(CHANNELS).document();
    ConversationModel2 conversationModel = ConversationModel2();
    conversationModel.id = channelDoc.documentID;
    conversationModel.creatorId = MyAppState.currentUser.userID;
    conversationModel.name = groupName;
    conversationModel.description = description;
    conversationModel.lastMessage =
        "${MyAppState.currentUser.fullName()} أنشئ هذه الغرفة";
    conversationModel.lastMessageDate = FieldValue.serverTimestamp();
    await channelDoc.setData(conversationModel.toJson()).then((onValue) async {
      selectedUsers.add(MyAppState.currentUser);
      for (User user in selectedUsers) {
        ChannelParticipation2 channelParticipation;
        if (user.userID == MyAppState.currentUser.userID) {
          channelParticipation = ChannelParticipation2(
              channel: conversationModel.id,
              user: user.userID,
              readCount: 0,
              role: "admin",
              timeOfEntry: FieldValue.serverTimestamp());
        } else {
          channelParticipation = ChannelParticipation2(
              channel: conversationModel.id,
              user: user.userID,
              readCount: 0,
              role: "member",
              timeOfEntry: FieldValue.serverTimestamp());
        }
        await createChannelParticipation(channelParticipation);
      }
      // groupConversationModel = HomeConversationModel(
      //     isGroupChat: true,
      //     members: selectedUsers,
      //     conversationModel: conversationModel );
    });
    return groupConversationModel;
  }

  Future<HomeConversationModel> joinGroupChat(User user, String groupID) async {
    List<User> users = [];
    getGroupMembers(groupID).listen((listOfUsers) {
      if (listOfUsers.isNotEmpty) {
        users = listOfUsers;
      }
    });
    HomeConversationModel groupConversationModel1;
    await firestore
        .collection(CHANNELS)
        .where('id', isEqualTo: groupID)
        .getDocuments()
        .then((value1) async {
      if (value1.documents.isNotEmpty) {
        ConversationModel conversationModel =
            ConversationModel.fromJson(value1.documents.first.data);

        ChannelParticipation2 channelParticipation;
        channelParticipation = ChannelParticipation2(
            channel: groupID,
            user: user.userID,
            readCount: 0,
            role: "member",
            block: false,
            timeOfEntry: FieldValue.serverTimestamp(),
            active: true);
        await createChannelParticipation(channelParticipation);
        await firestore
            .collection(CHANNEL_PARTICIPATION)
            .where('channel', isEqualTo: groupID)
            .where('user', isEqualTo: user.userID)
            .getDocuments()
            .then((onValue) {
          onValue.documents.forEach((document) {
            ChannelParticipation channelParticipation =
                ChannelParticipation.fromJson(document.data);
            groupConversationModel1 = HomeConversationModel(
              isGroupChat: true,
              members: users,
              conversationModel: conversationModel,
              readCount: channelParticipation.readCount,
              role: channelParticipation.role,
              timeOfEntry: channelParticipation.timeOfEntry,
              active: channelParticipation.active,
            );
          });
        });
      }
    });
    return groupConversationModel1;
  }

  Future<HomeConversationModel> enterGroupChat(
      User user, String groupID) async {
    List<User> users = [];
    ChannelParticipation participation = new ChannelParticipation();
    getGroupMembers(groupID).listen((listOfUsers) {
      if (listOfUsers.isNotEmpty) {
        users = listOfUsers;
      }
    });
    HomeConversationModel groupConversationModel1;
    await firestore
        .collection(CHANNELS)
        .where('id', isEqualTo: groupID)
        .getDocuments()
        .then((value1) async {
      if (value1.documents.isNotEmpty) {
        await firestore
            .collection(CHANNEL_PARTICIPATION)
            .where('channel', isEqualTo: groupID)
            .where('user', isEqualTo: MyAppState.currentUser.userID)
            .getDocuments()
            .then((querysnapShot) {
          querysnapShot.documents.forEach((doc) async {
            participation = ChannelParticipation.fromJson(doc.data);
            if (participation.active == false) {
              // await firestore.collection(CHANNELS).document(groupID).updateData(
              //     {'currentNumberMembers': FieldValue.increment(1) });
              firestore
                  .collection(CHANNEL_PARTICIPATION)
                  .document(querysnapShot.documents.first.documentID)
                  .updateData(
                      {'timeOfEntry': Timestamp.now(), 'expulsion': false});
            }
          });
        });

        ConversationModel conversationModel =
            ConversationModel.fromJson(value1.documents.first.data);

        groupConversationModel1 = HomeConversationModel(
          isGroupChat: true,
          members: users,
          conversationModel: conversationModel,
          readCount: participation.readCount,
          role: participation.role,
          timeOfEntry: (participation.active == true)
              ? participation.timeOfEntry
              : Timestamp.now(),
          active: participation.active,
        );
      }
    });
    return groupConversationModel1;
  }

  Future<HomeConversationModel> createGroupChatWithoutFriends(
      User user, String groupName, String description) async {
    List<User> selectedUsers;

    HomeConversationModel groupConversationModel;
    DocumentReference channelDoc = firestore.collection(CHANNELS).document();
    ConversationModel conversationModel = ConversationModel();
    conversationModel.id = channelDoc.documentID;
    conversationModel.creatorId = user.userID;
    conversationModel.name = groupName;
    conversationModel.currentNumberMembers = 0;
    conversationModel.description = description;

    conversationModel.lastMessage =
        "${MyAppState.currentUser.name} أنشئ هذه الغرفة";
    // conversationModel.paidArrangement=  DateTime(2018, 01, 13);
    //conversationModel.lastMessageDate = Timestamp.now();
    await channelDoc.setData(conversationModel.toJson()).then((onValue) async {
      ChannelParticipation2 channelParticipation;
      channelParticipation = ChannelParticipation2(
          channel: conversationModel.id,
          user: user.userID,
          readCount: 0,
          role: "admin",
          timeOfEntry: FieldValue.serverTimestamp());
      await createChannelParticipation(channelParticipation);
      await firestore
          .collection(CHANNELS)
          .document(conversationModel.id)
          .updateData({
        'paidArrangement': DateTime(2018, 01, 13),
        'especially': false,
        'numberOfMembers': 50,
        'currentNumberMembers': 1,
        'normalArrangement': false,
      });
      groupConversationModel = HomeConversationModel(
          isGroupChat: true,
          members: selectedUsers,
          conversationModel: conversationModel);
    });
    return groupConversationModel;
  }

  Future<HomeConversationModel> inviteGroupChat(
      List<User> selectedUsers, String userID, String groupID) async {}

  Future<bool> deleteChat(ConversationModel conversationModel) async {
    bool isSuccessful = false;
    firestore
        .collection(CHANNELS)
        .document(conversationModel.id)
        .collection(THREAD)
        .getDocuments()
        .then((onValue) async {
      if (onValue.documents.isNotEmpty) {
        onValue.documents.forEach((document) async {
          if (document.documentID.isNotEmpty) {
            await firestore
                .collection(CHANNELS)
                .document(conversationModel.id)
                .collection(THREAD)
                .document(document.documentID)
                .delete();
          }
        });
        isSuccessful = true;
      } else {}
    });

    return isSuccessful;
  }

  Future<bool> deleteConversation(String id) async {
    bool isSuccessful = false;
    await firestore.collection(CHANNELS).document(id).delete().then((onValue) {
      isSuccessful = true;
    }, onError: (e) {
      isSuccessful = false;
    });

    return isSuccessful;
  }

  Future<bool> blockUser(User blockedUser, String type) async {
    bool isSuccessful = false;
    BlockUserModel blockUserModel = BlockUserModel(
        type: type,
        source: MyAppState.currentUser.userID,
        dest: blockedUser.userID,
        createdAt: Timestamp.now());
    await firestore
        .collection(REPORTS)
        .add(blockUserModel.toJson())
        .then((onValue) {
      isSuccessful = true;
    });
    return isSuccessful;
  }

  Stream<bool> getStatus(String channelID) async* {
    StreamController<bool> refreshStreamController = StreamController();

    firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('user', isEqualTo: MyAppState.currentUser.userID)
        .where('channel', isEqualTo: channelID)
        .snapshots()
        .listen((onData) {
      onData.documents.forEach((document) async {
        if (document.data.isNotEmpty) {
          if (document.data["expulsion"] == true) {
            refreshStreamController.sink.add(true);
          }
        }
      });
    });
    yield* refreshStreamController.stream;
  }

  Stream<bool> getBlocks() async* {
    StreamController<bool> refreshStreamController = StreamController();
    firestore
        .collection(REPORTS)
        .where('source', isEqualTo: MyAppState.currentUser.userID)
        .snapshots()
        .listen((onData) {
      List<BlockUserModel> list = [];
      for (DocumentSnapshot block in onData.documents) {
        list.add(BlockUserModel.fromJson(block.data));
      }
      blockedList = list;

      if (homeConversations.isNotEmpty || friends.isNotEmpty) {
        refreshStreamController.sink.add(true);
      }
    });
    yield* refreshStreamController.stream;
  }

  Stream<bool> getBlocks2() async* {
    StreamController<bool> refreshStreamController = StreamController();
    firestore
        .collection(REPORTS)
        .where('dest', isEqualTo: MyAppState.currentUser.userID)
        .snapshots()
        .listen((onData) {
      List<BlockUserModel> list = [];
      for (DocumentSnapshot block in onData.documents) {
        list.add(BlockUserModel.fromJson(block.data));
      }
      blockedList = list;

      if (homeConversations.isNotEmpty || friends.isNotEmpty) {
        refreshStreamController.sink.add(true);
      }
    });
    yield* refreshStreamController.stream;
  }

  bool validateIfUserBlocked(String userID) {
    for (BlockUserModel blockedUser in blockedList) {
      if (userID == blockedUser.dest) {
        return true;
      }
    }
    return false;
  }

  Future<void> sentNotification(
      String userID2, String nameSender, String type, String message) async {
    await http.post(Constants.URL_HOSTING_API + Constants.URL_PUSH_NOTIFICATION,
        body: {
          "userID2": userID2,
          "nameSender": nameSender,
          "type": type,
          "message": message
        });
  }
}
