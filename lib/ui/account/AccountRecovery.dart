import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/model/User.dart';
import 'package:elegant/ui/services/ChatHelper.dart';
import 'package:elegant/ui/services/FirebaseHelper.dart';
import 'package:elegant/ui/utils/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

import '../../constants.dart' as Constants;
import '../../constants.dart';
import '../../home.dart';
import '../../main.dart';

class AccountRecovery extends StatefulWidget {
  final String email;

  const AccountRecovery({Key key, this.email}) : super(key: key);

  @override
  _AccountRecoveryState createState() => _AccountRecoveryState();
}

class _AccountRecoveryState extends State<AccountRecovery> {
  static Firestore firestore = Firestore.instance;
  Future<List<User>> _future;
  ChatHelper chatHelper = new ChatHelper();
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();

  @override
  void initState() {
    super.initState();
    _future = getAccounts(widget.email);
    print(_future);
  }

  Future<List<User>> getAccounts(String email) async {
    await FirebaseAuth.instance.signInAnonymously();

    List<User> accounts = List<User>();

    await firestore
        .collection(USERS)
        .where('associatedEmail', isEqualTo: email)
        .getDocuments()
        .then((querysnapShot) async {
      querysnapShot.documents.forEach((doc) async {
        User user = User.fromJson(doc.data);
        if (user.userID != null) {
          setState(() {
            accounts.add((user));
          });
        }
      });
    });

    return accounts;
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
                'الحسابات المرتبطة',
                style: TextStyle(fontSize: 13),
              ),
            ]),
      ),
      body: FutureBuilder<List<User>>(
          future: _future,
          initialData: [],
          builder: (context, snapshot) {
            print(snapshot.data.length);
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.data.isEmpty &&
                snapshot.connectionState == ConnectionState.done) {
              return Center(
                child: Text(
                  'الرجاء الانتظار',
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              snapshot.data.remove(MyAppState.currentUser);
              return snapshot.data.length != 0
                  ? ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) {
                        User account = snapshot.data[index];
                        return ListTile(
                          leading: Image.network(
                            account.profilePictureURL,
                            width: 30,
                          ),
                          title: Text(account.name),
                          // subtitle: Text('${user.about}'),
                          onTap: () => showDialog(
                              context: context,
                              builder: (context) {
                                return Center(
                                    child: SingleChildScrollView(
                                        child: Dialog(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            elevation: 16,
                                            child: Container(
                                              height: 125,
                                              width: 350,
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 20.0,
                                                          left: 16,
                                                          right: 16,
                                                          bottom: 16),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      Text(
                                                        "استعادة هذا الحساب",
                                                      ),
                                                      SizedBox(height: 16),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: <Widget>[
                                                          FlatButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                              child: Text(
                                                                  'إلغاء')),
                                                          FlatButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);

                                                                _resetPassword(
                                                                    context,
                                                                    account);
                                                              },
                                                              child: Text('نعم',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ))),
                                                        ],
                                                      )
                                                    ],
                                                  )),
                                            ))));
                              }),
                        );
                      },
                    )
                  : Container();
            }
          }),
    );
  }

  _resetPassword(BuildContext context, User user) {
    String password, confirmPassword;
    TextEditingController _passwordController = new TextEditingController();
    TextEditingController _confirmController = new TextEditingController();
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
                        height: 350,
                        width: 350,
                        child: Padding(
                            padding: const EdgeInsets.only(
                                top: 20.0, left: 16, right: 16, bottom: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "تعيين كلمة مرور جديدة :",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 16),
                                Padding(
                                    padding: const EdgeInsets.only(
                                        top: 10.0,
                                        left: 16,
                                        right: 16,
                                        bottom: 16)),
                                ConstrainedBox(
                                    constraints: BoxConstraints(
                                        minWidth: double.infinity),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 16.0, right: 8.0, left: 8.0),
                                      child: TextFormField(
                                          style: TextStyle(
                                              fontSize:
                                                  Constants.FONT_SIZE_MEDIUM),
                                          obscureText: true,
                                          textInputAction: TextInputAction.next,
                                          onFieldSubmitted: (_) =>
                                              FocusScope.of(context)
                                                  .nextFocus(),
                                          controller: _passwordController,
                                          cursorColor:
                                              Color(Constants.COLOR_PRIMARY),
                                          decoration: InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 16),
                                              fillColor: Colors.white,
                                              hintText: 'كلمة المرور',
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          4.0),
                                                  borderSide: BorderSide(
                                                      color: Color(Constants
                                                          .COLOR_PRIMARY),
                                                      width: 2.0)),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ))),
                                    )),
                                ConstrainedBox(
                                  constraints:
                                      BoxConstraints(minWidth: double.infinity),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 16.0, right: 8.0, left: 8.0),
                                    child: TextFormField(
                                        style: TextStyle(
                                            fontSize:
                                                Constants.FONT_SIZE_MEDIUM),
                                        textInputAction: TextInputAction.done,
                                        controller: _confirmController,
                                        obscureText: true,
                                        cursorColor:
                                            Color(Constants.COLOR_PRIMARY),
                                        decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 16),
                                            fillColor: Colors.white,
                                            hintText: 'تأكيد كلمة المرور',
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                                borderSide: BorderSide(
                                                    color: Color(Constants
                                                        .COLOR_PRIMARY),
                                                    width: 2.0)),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                            ))),
                                  ),
                                ),
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
                                          if (_passwordController
                                                  .text.isNotEmpty &&
                                              _passwordController.text ==
                                                  _confirmController.text &&
                                              _passwordController.text.length >
                                                  5) {
                                            if (_passwordController
                                                .text.isNotEmpty) {
                                              final FirebaseAuth auth =
                                                  FirebaseAuth.instance;
                                              FirebaseUser userAuth =
                                                  await auth.currentUser();
                                              final uid = userAuth.uid;
                                              await firestore
                                                  .collection(USERS)
                                                  .document(user.userID)
                                                  .updateData({
                                                'password':
                                                    _passwordController.text
                                              });
                                              setState(() {
                                                MyAppState.currentUser = user;
                                              });

                                              SharedPreferences shard =
                                                  await SharedPreferences
                                                      .getInstance();
                                              shard.setString(
                                                  "userID", user.userID);
                                              await Firestore.instance
                                                  .collection(USERS)
                                                  .document(user.userID)
                                                  .updateData({
                                                'active': true,
                                                'lastOnlineTimestamp':
                                                    Timestamp.now(),
                                                'anonymouslyID': uid
                                              });
                                              pushAndRemoveUntil(context,
                                                  Home(user: user), false);
                                            }
                                          } else {
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
}
