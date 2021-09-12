import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/model/ChannelParticipation.dart';
import 'package:elegant/model/HomeConversationModel.dart';
import 'package:elegant/model/MemberModel.dart';
import 'package:elegant/model/User.dart';
import 'package:elegant/ui/account/ProfileScreen.dart';
import 'package:elegant/ui/services/ChatHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../constants.dart';
import '../../main.dart';

class MembersGroupActive extends StatefulWidget {
  final HomeConversationModel homeConversationModel;

  const MembersGroupActive({Key key, this.homeConversationModel}) : super(key: key);

  @override
  _MembersGroupActiveState createState() => _MembersGroupActiveState();
}

class _MembersGroupActiveState extends State<MembersGroupActive> {
  static Firestore firestore = Firestore.instance;
  Future<List<MemberModel>> _futureFriends;
  ChatHelper chatHelper = new ChatHelper();
  String roleInGroup = "member";
   User user2 = new User();
  @override
  void initState() {
    super.initState();
    _futureFriends =
        getMembers(widget.homeConversationModel.conversationModel.id);
    print(_futureFriends);
  }

  Future<List<MemberModel>> getMembers(String groupID) async {
    List<MemberModel> members = List<MemberModel>();

    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: groupID)
        .getDocuments()
        .then((querysnapShot) async {
      querysnapShot.documents.forEach((doc) async {
        ChannelParticipation channelParticipation =
            ChannelParticipation.fromJson(doc.data);
        if (channelParticipation.channel != null) {
          if (channelParticipation.active == true) {
            await firestore
                .collection(USERS)
                .document(channelParticipation.user)
                .get()
                .then((user) {
              MemberModel memberModel = new MemberModel();
              memberModel.userID = channelParticipation.user;
              memberModel.name = user.data["name"];
              memberModel.role = channelParticipation.role;
              memberModel.channelParticipationID = channelParticipation.channel;
              memberModel.user2 = User.fromJson(user.data);
              setState(() {

                members.add((memberModel));
              });
            });
          }
        }
      });
    });
    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel',
            isEqualTo: widget.homeConversationModel.conversationModel.id)
        .where('user', isEqualTo: MyAppState.currentUser.userID)
        .getDocuments()
        .then((querysnapShot) async {
      querysnapShot.documents.forEach((doc) async {
        ChannelParticipation channelParticipation =
            ChannelParticipation.fromJson(doc.data);
        if (channelParticipation.role != null) {
          setState(() {
            roleInGroup = channelParticipation.role;
          });
        }
      });
    });

    return members;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(COLOR_PRIMARY),
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'المتواجدون في الغرفة',
                style: TextStyle(fontSize: 13),
              ),
            ]),
      ),
      body:
      FutureBuilder<List<MemberModel>>(
          future: _futureFriends,
          initialData: [],
          builder: (context, snapshot) {
            print(snapshot.data.length);
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.data.isEmpty &&
                snapshot.connectionState == ConnectionState.done) {
              return Center(
                child: Text(
                  'لا توجد بيانات',
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              snapshot.data.remove(MyAppState.currentUser);
              return snapshot.data.length != 0
                  ? ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) {
                        MemberModel memberModel = snapshot.data[index];
                        return ListTile(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) => new ProfileScreen(
                                    user1: MyAppState.currentUser,
                                    user2: memberModel.user2)));
                          },
                          leading: Image.asset(
                            "assets/images/icon.png",
                            width: 30,
                          ),
                          title: Text(snapshot.data[index].name),
                          // subtitle: Text('${user.about}'),
                          // trailing:
                          // option(memberModel.userID, memberModel.name),
                        );
                      },
                    )
                  : Container();
            }
          }),
    );
  }
  Widget option(String userID, String name) {
    switch (roleInGroup) {
      case "member":
        break;

      case "admin":
      case "owner":

        return PopupMenuButton(
          itemBuilder: (BuildContext bc) => [
            PopupMenuItem(
                child: Text(
                  "طرد",
                  style: TextStyle(fontSize: 12),
                ),
                value: "leave"),
            PopupMenuItem(
                child: Text(
                  "حظر",
                  style: TextStyle(fontSize: 12),
                ),

                value: "block"),
            PopupMenuItem(
                child: Text(
                  "تعيين كمشرف",
                  style: TextStyle(fontSize: 12),
                ),
                value: "addSupervisor"),
            PopupMenuItem(
                child: Text("تعيين كـ أونر",
                  style: TextStyle(fontSize: 12),
                ),
                value: "addOwner"),

          ],
          onSelected: (route) {
            switch (route) {
              case "addOwner":
                showDialog(
                    context: context,
                    builder: (context) {
                      return Center(
                          child: SingleChildScrollView(
                              child: Dialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  elevation: 16,
                                  child: Wrap(
                                    children: <Widget>[ Padding(
                                        padding: const EdgeInsets.only(
                                            top: 20.0,
                                            left: 16,
                                            right: 16,
                                            bottom: 16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              "الاضافة كـ أونر للغرفة",
                                            ),
                                            SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                              children: <Widget>[
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: Text('إلغاء')),
                                                TextButton(
                                                    onPressed: () async {
                                                      chatHelper.updateRoleMember(
                                                          userID,
                                                          name,
                                                          widget
                                                              .homeConversationModel,
                                                          "owner");
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text('تأكيد',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                        ))),
                                              ],
                                            )
                                          ],
                                        ))],
                                  ))));
                    });
                break;
              case "addSupervisor":
                showDialog(
                    context: context,
                    builder: (context) {
                      return Center(
                          child: SingleChildScrollView(
                              child: Dialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  elevation: 16,
                                  child: Wrap(
                                    children: <Widget>[Padding(
                                        padding: const EdgeInsets.only(
                                            top: 20.0,
                                            left: 16,
                                            right: 16,
                                            bottom: 16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              "الاضافة كمشرف للغرفة",
                                            ),
                                            SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                              children: <Widget>[
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: Text('إلغاء')),
                                                TextButton(
                                                    onPressed: () async {
                                                      chatHelper.updateRoleMember(
                                                          userID,
                                                          name,
                                                          widget
                                                              .homeConversationModel,
                                                          "supervisor");
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text('تأكيد',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                        ))),
                                              ],
                                            )
                                          ],
                                        ))],
                                  ))));
                    });
                break;

              case "leave":
                chatHelper.leaveGroup(
                    userID, name, widget.homeConversationModel);

                Navigator.pop(context);
                break;
              case "block":
                chatHelper.blockGroup(
                    userID, name, widget.homeConversationModel);

                Navigator.pop(context);
                break;
            // case "leave":
            //   chatHelper.leaveGroup(
            //       userID, name, widget.homeConversationModel);
            //   Navigator.pop(context);
            //   Navigator.pop(context);
            //   break;
            }
          },
        );
        break;

      case "supervisor":

        return PopupMenuButton(
          itemBuilder: (BuildContext bc) => [
            PopupMenuItem(
                child: Text(
                  "طـرد",
                  style: TextStyle(fontSize: 12),
                ),
                value: "leave"),
            PopupMenuItem(
                child: Text(
                  "حظر",
                  style: TextStyle(fontSize: 12),
                ),
                value: "block"),
          ],
          onSelected: (route) {
            switch (route) {
              case "addSupervisor":
                showDialog(
                    context: context,
                    builder: (context) {
                      return Center(
                          child: SingleChildScrollView(
                              child: Dialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
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
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                "الاضافة كمشرف للغرفة",
                                              ),
                                              SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                                children: <Widget>[
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(context),
                                                      child: Text('إلغاء')),
                                                  TextButton(
                                                      onPressed: () async {
                                                        chatHelper.updateRoleMember(
                                                            userID,
                                                            name,
                                                            widget
                                                                .homeConversationModel,
                                                            "supervisor");
                                                        Navigator.pop(context);
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text('تأكيد',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                            FontWeight.bold,
                                                          ))),
                                                ],
                                              )
                                            ],
                                          ))],
                                  ))));
                    });
                break;
              case "block":
                chatHelper.blockGroup(
                    userID, name, widget.homeConversationModel);

                Navigator.pop(context);
                break;
              case "leave":
                chatHelper.leaveGroup(
                    userID, name, widget.homeConversationModel);

                Navigator.pop(context);
            }
          },
        );
        break;
    }
  }

}
