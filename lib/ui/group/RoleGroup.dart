import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/main.dart';
import 'package:elegant/model/ChannelParticipation.dart';
import 'package:elegant/model/HomeConversationModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../constants.dart';
import '../../model/MemberModel.dart';
import '../../model/User.dart';
import '../../ui/services/ChatHelper.dart';

class RoleGroup extends StatefulWidget {
  final HomeConversationModel homeConversationModel;

  const RoleGroup({Key key, this.homeConversationModel}) : super(key: key);

  @override
  _RoleGroupState createState() => _RoleGroupState();
}

class _RoleGroupState extends State<RoleGroup> {
  static Firestore firestore = Firestore.instance;
  Future<List<MemberModel>> _futureFriends;
  List<MemberModel> members = [];
  ChatHelper chatHelper = new ChatHelper();
  String icon = "assets/images/icon_user.png";
  String roleInGroup = "member";

  @override
  void initState() {
    super.initState();
    _futureFriends =
        getAllRoleGroup(widget.homeConversationModel.conversationModel.id);
  }

  Future<List<MemberModel>> getAllRoleGroup(String groupID) async {
    await firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('channel', isEqualTo: groupID)
        .getDocuments()
        .then((querysnapShot) {
      querysnapShot.documents.forEach((doc) {
        ChannelParticipation channelParticipation =
            ChannelParticipation.fromJson(doc.data);

        if (channelParticipation.role != "member") {
          firestore
              .collection(USERS)
              .document(channelParticipation.user)
              .get()
              .then((d) {
            User user = User.fromJson(d.data);
            MemberModel memberModel = new MemberModel();
            memberModel.userID = channelParticipation.user;
            memberModel.name = user.name;
            memberModel.role = channelParticipation.role;
            memberModel.channelParticipationID = channelParticipation.channel;

            setState(() {
              members.add(memberModel);
            });

            print(channelParticipation.role);
            print(user.name);
            print(channelParticipation.channel);
            print(channelParticipation.user);
          });
        }
        if (channelParticipation.role == "admin" &&
            channelParticipation.user == MyAppState.currentUser.userID) {
          setState(() {
            roleInGroup = "admin";
          });
        }
        if (channelParticipation.role == "owner" &&
            channelParticipation.user == MyAppState.currentUser.userID) {
          setState(() {
            roleInGroup = "owner";
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
                'مشرفي الغرفة',
                style: TextStyle(fontSize: 13),
              ),
            ]),
      ),
      body: FutureBuilder<List<MemberModel>>(
          future: _futureFriends,
          initialData: [],
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.data.isEmpty &&
                snapshot.connectionState == ConnectionState.done) {
              return Center(
                child: Text('يرجى المحاولة لاحقاً '),
              );
            } else {
              return snapshot.data.length != 0
                  ? ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) {
                        MemberModel memberModel = snapshot.data[index];
                        if (memberModel.role == "admin") {
                          icon = "assets/images/icon_admin.png";
                        }
                        if (memberModel.role == "owner") {
                          icon = "assets/images/icon_owner.png";
                        }
                        if (memberModel.role == "supervisor") {
                          icon = "assets/images/icon_supervisor.png";
                        }
                        return ListTile(
                          leading: Image.asset(
                            icon,
                            width: 30,
                          ),
                          title: Text('${memberModel.name}'),
                          subtitle: Text('${memberModel.role}'),
                          trailing:
                              roleInGroup == "admin" || roleInGroup == "owner"
                                  ? option(memberModel.userID, memberModel.name,
                                      memberModel.role)
                                  : option2(memberModel.userID,
                                      memberModel.name, memberModel.role),
                        );
                      },
                    )
                  : Container();
            }
          }),
    );
  }

  Widget option(String userID, String name, String memberRole) {
    switch (memberRole) {
      case "supervisor":
        return PopupMenuButton(
          itemBuilder: (BuildContext bc) => [
            PopupMenuItem(
                child: Text(
                  "ازالة",
                  style: TextStyle(fontSize: 12),
                ),
                value: "remove"),
          ],
          onSelected: (route) {
            switch (route) {
              case "remove":
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
                                    height: 125,
                                    width: 350,
                                    child: Padding(
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
                                              "ازالة من الادارة",
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
                                                          "member");
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
                                        )),
                                  ))));
                    });
                break;
            }
          },
        );
        break;
      case "owner":
        return PopupMenuButton(
          itemBuilder: (BuildContext bc) => [
            PopupMenuItem(
                child: Text(
                  "ازالة",
                  style: TextStyle(fontSize: 12),
                ),
                value: "remove"),
          ],
          onSelected: (route) {
            switch (route) {
              case "remove":
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
                                    height: 125,
                                    width: 350,
                                    child: Padding(
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
                                              "ازالة من الادارة",
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
                                                          "member");
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
                                        )),
                                  ))));
                    });
                break;
            }
          },
        );
        break;
    }
  }

  Widget option2(String userID, String name, String memberRole) {}
}
