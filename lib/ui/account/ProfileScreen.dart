import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_list_pick/country_list_pick.dart';
import 'package:elegant/model/ConversationModel.dart';
import 'package:elegant/model/Friendship.dart';
import 'package:elegant/model/HomeConversationModel.dart';
import 'package:elegant/ui/chat/ChatScreen.dart';
import 'package:elegant/ui/services/UserHelper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:toast/toast.dart';

import '../../constants.dart';
import '../../main.dart';
import '../../model/User.dart';
import '../../ui/services/FirebaseHelper.dart';
import '../../ui/utils/helper.dart';
import 'FullScreenImage.dart';

class ProfileScreen extends StatefulWidget {
  final User user1;
  User user2;

  ProfileScreen({Key key, @required this.user1, this.user2}) : super(key: key);

  @override
  _ProfileScreenState createState() {
    return _ProfileScreenState(user2);
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    getFriends(widget.user2.userID);
    if (widget.user1.userID == widget.user2.userID) {
      setState(() {
        _visible = false;
      });
    }
    if (MyAppState.currentUser.typeUser == "merchant" &&
        MyAppState.currentUser.userID != widget.user2.userID) {
      setState(() {
        _transferPoints = true;
      });
    }
  }
  ConversationModel  c;
  UserHelper _userHelper = new UserHelper();
  User user;
  bool _transferPoints = false;
  bool _markMerchant = false;
  static Firestore firestore = Firestore.instance;
  GlobalKey<FormState> _key = GlobalKey();
  bool _validate = false;
  String name,
      email,
      phone,
      about,
      gender,
      country,
      merchantID,
      getCountry,
      friends = "0",
      textType,
      urlIcon;
  BuildContext context1;

  FireStoreUtils _fireStoreUtils = FireStoreUtils();

  _ProfileScreenState(this.user);

  @override
  Widget build(BuildContext context) {
    String stringColor = "Color(${widget.user2.color})";
    String valueString =
        stringColor.split('(0x')[1].split(')')[0]; // kind of hacky..
    print(valueString);
    int value = int.parse(valueString, radix: 16);

    Color otherColor = new Color(value);
    if (!_validate) {
      name = user.name;
      gender = user.gender;
      merchantID = user.merchantID;
      country = user.country.toString();
      textType = user.typeUser;
      about = user.about;
      phone = user.phone;

      switch (textType) {
        case "user":
          textType = "مستخدم عادي";
          urlIcon = "assets/images/icon_user.png";
          break;
        case "admin":
          textType = "حساب مسؤول موثق";
          urlIcon = "assets/images/icon_admin.png";
          break;
        case "merchant":
          textType = "حساب تاجر - مارشنت";
          urlIcon = "assets/images/icon_merchant.png";
          _markMerchant = true;

          break;
        default:
          textType = "مستخدم ";
          urlIcon = "assets/images/icon_user.png";
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(COLOR_PRIMARY),
        title: Text(
          ' الملف الشخصي',
          style: TextStyle(fontSize: 17),
        ),
      ),
      body: Builder(
        builder: (buildContext) => SingleChildScrollView(
          child: Form(
            key: _key,
            autovalidate: _validate,
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 32.0, left: 32, right: 32),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          Center(
                            child: GestureDetector(
                                onTap: () {
                                  print(user.profilePictureURL);
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (_) {
                                    return FullScreenImage(
                                      imageUrl: user.profilePictureURL,
                                      tag: "generate_a_unique_tag",
                                    );
                                  }));
                                },
                                child: displayCircleImage(
                                    user.profilePictureURL, 130, false)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Center(
                      child: new Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            urlIcon,
                            width: 45,
                            height: 45,
                          ),
                          Text(
                            name,
                            style: TextStyle(fontSize: 20, color: otherColor),
                          ),
                          Text(
                            textType,
                            style: TextStyle(fontSize: 10, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Center(
                          child: new Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                              ),
                              SizedBox(
                                width: 100,
                                height: 30,
                                child: new Text("عدد الأصدقاء"),
                              ),
                              Container(
                                margin: const EdgeInsets.all(5.0),
                                child: new Text(
                                  widget.user2.hideFriends == true
                                      ? "خاص"
                                      : friends,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: new Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                              ),
                              SizedBox(
                                width: 100,
                                height: 30,
                                child: new Text(
                                  "أنشئ في",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(5.0),
                                child: new Text(
                                    user.createdAt.toDate().year.toString()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: Visibility(
                        visible: _visible,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            RaisedButton(
                              color: Color(COLOR_PRIMARY),
                              textColor: Colors.white,
                              child: Text("طلب صداقة"),
                              onPressed: () async {
                                _fireStoreUtils.sendFriendRequest(
                                    user, widget.user1.userID);
                                Toast.show("تم ارسال الطلب", context,
                                    duration: Toast.LENGTH_LONG,
                                    gravity: Toast.CENTER);
                              },
                            ),
                            Padding(padding: const EdgeInsets.all(10)),
                            RaisedButton(
                              color: Color(COLOR_ACCENT),
                              textColor: Colors.white,
                              child: Text("دردشـة"),
                              onPressed: () async {
                                if (widget.user2.privateLock == null ||
                                    widget.user2.privateLock == false) {
                                  String channelID;

                                  if (widget.user2.userID.compareTo(widget.user1.userID) <
                                      0) {
                                    channelID = widget.user2.userID +
                                        widget.user1.userID;
                                  } else {
                                    channelID = widget.user1.userID +
                                        widget.user2.userID;
                                  }

                                  ConversationModel conversationModel ;
                                  if (await _checkChannelNullability(conversationModel)) {
                                  push(
                                    context,
                                    ChatScreen(
                                      homeConversationModel:
                                          HomeConversationModel(
                                              isGroupChat: false,
                                              members: [widget.user2],
                                              conversationModel:
                                                  c),
                                    ),
                                  );}
                                //}
                                } else {
                                  Toast.show("الدردشة الخاصة مقفلة", context,
                                      duration: Toast.LENGTH_LONG,
                                      gravity: Toast.CENTER);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                      visible: _markMerchant,
                      child: Center(
                        child: Container(
                            width: 250,
                            child:
                                Image.asset("assets/images/mark_merchant.png")),
                      ),
                    ),
                    Visibility(
                      visible: _transferPoints,
                      child: Center(
                        child: Container(
                          width: 250,
                          child: RaisedButton(
                            color: Color(COLOR_ACCENT),
                            textColor: Colors.white,
                            child: Text("شحن نقاط"),
                            onPressed: () async {
                              _alert();
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    SizedBox(height: 16.0),
                    Text(
                      "الحالة",
                      style: TextStyle(fontSize: 11),
                    ),
                    Text(user.about),
                    SizedBox(height: 16.0),
                    SizedBox(height: 16.0),
                    Text(
                      "الجنس",
                      style: TextStyle(fontSize: 11),
                    ),
                    Text(user.gender),
                    SizedBox(height: 16.0),
                    SizedBox(height: 16.0),
                    Text(
                      "العمر",
                      style: TextStyle(fontSize: 11),
                    ),
                    Text(user.age),
                    SizedBox(height: 16.0),
                    Text(
                      "البلد",
                      style: TextStyle(fontSize: 11),
                    ),
                    AbsorbPointer(
                      absorbing: true,
                      child: CountryListPick(
                        initialSelection: country,
                        useUiOverlay: false,
                        useSafeArea: false,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    SizedBox(height: 16.0),
                    Text(
                      "تاريخ انشاء الحساب",
                    ),
                    SizedBox(height: 8.0),
                    Text(user.createdAt.toDate().toString()),
                    SizedBox(height: 8.0),
                    SizedBox(height: 14),
                  ]),
            ),
          ),
        ),
      ),
    );
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
    if (friendshipList.length > 0) {
      setState(() {
        friends = friendshipList.length.toString();
      });
    }
  }

  _alert() {
    TextEditingController _pointController = TextEditingController();
    return showDialog(
        context: context,
        builder: (context) {
          return Center(
              child: SingleChildScrollView(
                  child: Dialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 16,
                      child: Container(
                        height: 250,
                        width: 350,
                        child: Padding(
                            padding: const EdgeInsets.only(
                                top: 20.0, left: 16, right: 16, bottom: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "ادخل عدد النقاط :",
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
                                  keyboardType: TextInputType.number,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLines: 1,
                                  controller: _pointController,
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
                                    labelText: 'عدد النقاط :',
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
                                    FlatButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('إلغاء')),
                                    FlatButton(
                                        onPressed: () async {
                                          int point = int.parse(
                                              _pointController.text.trim());
                                          int pointMerchant =
                                              MyAppState.currentUser.points;
                                          if (point > 0 &&
                                              point < 25000 &&
                                              point <= pointMerchant) {
                                            bool isSuccessful =
                                                await _userHelper
                                                    .transferPoints(
                                                        point,
                                                        pointMerchant,
                                                        user.points,
                                                        user.userID);
                                            if (isSuccessful) {
                                              Toast.show(
                                                  "تم تحويل النقاط بنجاح",
                                                  context,
                                                  duration: Toast.LENGTH_LONG,
                                                  gravity: Toast.BOTTOM);

                                              Navigator.pop(context);
                                            } else {
                                              Toast.show("رصيد نقاطك غير كافي",
                                                  context,
                                                  duration: Toast.LENGTH_LONG,
                                                  gravity: Toast.CENTER);
                                            }
                                          } else {
                                            hideProgress();
                                            Toast.show("ادخال خاطئ", context,
                                                duration: Toast.LENGTH_LONG,
                                                gravity: Toast.CENTER);
                                          }
                                        },
                                        child: Text('تأكيد',
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

  Widget mm() {
    print("mm");
    return Hero(
      tag: "customTag",
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          user.profilePictureURL,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Future<bool> _checkChannelNullability(
      ConversationModel conversationModel) async {
    if (conversationModel != null) {
      return true;
    } else {
      String channelID;
      User friend =  widget.user2;
      User user = MyAppState.currentUser;
      if (friend.userID.compareTo(user.userID) < 0) {
        channelID = friend.userID + user.userID;
      } else {
        channelID = user.userID + friend.userID;
      }

      ConversationModel  conversation = ConversationModel (
          creatorId: user.userID,
          id: channelID,
          lastMessageDate:  Timestamp.now(),
          lastMessage: ''
              '${user.fullName()} sent a message');
      bool isSuccessful =
      await _fireStoreUtils.createConversation2(conversation);
      if (isSuccessful) {
           c = conversation;

        setState(() {});
      }
      return isSuccessful;
    }
  }
}
