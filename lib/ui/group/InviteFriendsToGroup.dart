import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../constants.dart';
import '../../main.dart';
import '../../model/HomeConversationModel.dart';
import '../../model/User.dart';
import '../../ui/services/FirebaseHelper.dart';
import '../../ui/utils/helper.dart';

class InviteFriendsToGroup extends StatefulWidget {
  final String userID;
  final String groupID;

  const InviteFriendsToGroup({Key key, @required this.userID, this.groupID})
      : super(key: key);

  @override
  _InviteFriendsToGroupState createState() => _InviteFriendsToGroupState();
}

class _InviteFriendsToGroupState extends State<InviteFriendsToGroup> {
  List<User> _selectedUsers = [];
  Future<List<User>> _futureFriends;
  FireStoreUtils _fireStoreUtils = FireStoreUtils();
  TextEditingController _groupNameController = TextEditingController();
  TextEditingController _groupDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureFriends =
        _fireStoreUtils.getFriendsUserObject2(widget.userID, widget.groupID);
    print(_futureFriends);
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
              Text('اضافة اصدقاء للغرفة'),
              _selectedUsers.length != 0 ? SizedBox(height: 4) : Container(),
              _selectedUsers.length != 0
                  ? Text(
                      "${_selectedUsers.length} الأعضاء",
                      style: TextStyle(fontSize: 12),
                    )
                  : Container()
            ]),
      ),
      body: FutureBuilder<List<User>>(
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
                  'جميع الأصدقاء منضمون إلى الغرفة أو أنه ليس لديك أصدقاء بعد',
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              snapshot.data.remove(MyAppState.currentUser);
              return snapshot.data.length != 0
                  ? ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) {
                        User user = snapshot.data[index];
                        return ListTile(
                          onTap: () {
                            if (!user.selected) {
                              user.selected = true;
                              _selectedUsers.add(user);
                            } else {
                              user.selected = false;
                              _selectedUsers.remove(user);
                            }
                            setState(() {});
                          },
                          leading: displayCircleImage(
                              user.profilePictureURL, 44, false),
                          title: Text('${user.fullName()}'),
                          subtitle: Text('${user.about}'),
                          trailing: user.selected
                              ? Icon(Icons.check_circle,
                                  color: Colors.orangeAccent)
                              : Container(width: 0, height: 0),
                        );
                      },
                    )
                  : Container();
            }
          }),
      floatingActionButton: _selectedUsers.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
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
                                    height: 100,
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
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: <Widget>[
                                                FlatButton(
                                                    onPressed: () async {
                                                      showProgress(
                                                          context,
                                                          ' جاري اضافة الاصدقاء ، الرجاء الانتظار ...',
                                                          false);
                                                      HomeConversationModel
                                                          groupChatConversationModel =
                                                          await _fireStoreUtils
                                                              .inviteGroupChat(
                                                                  _selectedUsers,
                                                                  widget.userID,
                                                                  widget
                                                                      .groupID);
                                                      hideProgress();
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text('اضافة للغرفة',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Color(
                                                                COLOR_ACCENT)))),
                                              ],
                                            )
                                          ],
                                        )),
                                  ))));
                    });
              },
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.arrow_forward),
            )
          : Container(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _groupNameController.dispose();
  }
}
