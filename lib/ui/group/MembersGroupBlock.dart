import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/model/ChannelParticipation.dart';
import 'package:elegant/model/HomeConversationModel.dart';
import 'package:elegant/model/MemberModel.dart';
import 'package:elegant/ui/services/ChatHelper.dart';
import 'package:elegant/ui/services/FirebaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:toast/toast.dart';

import '../../constants.dart';
import '../../main.dart';

class MembersGroupBlock extends StatefulWidget {
  final HomeConversationModel homeConversationModel;

  const MembersGroupBlock({Key key, this.homeConversationModel})
      : super(key: key);

  @override
  _MembersGroupBlockState createState() => _MembersGroupBlockState();
}

class _MembersGroupBlockState extends State<MembersGroupBlock> {
  static Firestore firestore = Firestore.instance;
  Future<List<MemberModel>> _futureFriends;
  ChatHelper chatHelper = new ChatHelper();
  String roleInGroup = "member";
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();

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
        .where('block', isEqualTo: true)
        .getDocuments()
        .then((querysnapShot) async {
      querysnapShot.documents.forEach((doc) async {
        ChannelParticipation channelParticipation =
            ChannelParticipation.fromJson(doc.data);
        if (channelParticipation.channel != null) {
          await firestore
              .collection(USERS)
              .document(channelParticipation.user)
              .get()
              .then((user) {
            MemberModel memberModel = new MemberModel();
            memberModel.userID = channelParticipation.user;
            memberModel.name = user.data["name"];
            print(channelParticipation.user);
            memberModel.role = channelParticipation.role;
            memberModel.channelParticipationID = channelParticipation.channel;
            setState(() {
              members.add((memberModel));
            });
          });
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
                '  قائمة الحظر',
                style: TextStyle(fontSize: 13),
              ),
            ]),
      ),
      body: FutureBuilder<List<MemberModel>>(
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
                          leading: Image.asset(
                            "assets/images/icon.png",
                            width: 30,
                          ),
                          title: Text(memberModel.name),
                          trailing: IconButton(
                            icon: new Icon(Icons.clear),
                            highlightColor: Colors.red,
                            onPressed: () async {
                              bool isSuccessful =
                                  await _fireStoreUtils.unBlockParticipation(
                                      memberModel.userID,
                                      widget.homeConversationModel
                                          .conversationModel.id);

                              //Navigator.pop(context);
                              if (isSuccessful) {
                                Toast.show("تم إلغاء الحظر", context,
                                    duration: Toast.LENGTH_SHORT,
                                    gravity: Toast.CENTER);

                                Navigator.pop(context);
                              }
                            },
                          ),
                        );
                      },
                    )
                  : Container();
            }
          }),
    );
  }
}
