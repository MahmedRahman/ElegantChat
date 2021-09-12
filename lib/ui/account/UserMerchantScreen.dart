import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../constants.dart' as Constants;
import '../../model/User.dart';
import '../../ui/services/FirebaseHelper.dart';
import '../../ui/utils/helper.dart';

class UserMerchantScreen extends StatefulWidget {
  final User user;

  const UserMerchantScreen({Key key, @required this.user}) : super(key: key);

  @override
  _UserMerchantScreenState createState() => _UserMerchantScreenState(user);
}

class _UserMerchantScreenState extends State<UserMerchantScreen> {
  final User user;
  bool showSearchBar = false;
  TextEditingController controller = TextEditingController();
  final fireStoreUtils = FireStoreUtils();

  _UserMerchantScreenState(this.user);

  Future<List<User>> _future;

  @override
  void initState() {
    super.initState();
    this.refresh();
  }

  refresh() {
    _future = fireStoreUtils.getUserMerchant(user.userID);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "سجل الحسابات",
          style: TextStyle(fontSize: Constants.FONT_SIZE_MEDIUM),
        ),
        backgroundColor: Color(Constants.COLOR_PRIMARY),
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
                child: Text('لم تقم بإنشاء أي حساب'),
              );
            } else {
              //snapshot.data.remove(MyAppState.currentUser);
              return snapshot.data.length != 0
                  ? ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) {
                        User user = snapshot.data[index];
                        return ListTile(
                          leading: displayCircleImage(
                              user.profilePictureURL, 44, false),
                          title: Text('${user.fullName()}'),
                          subtitle: Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Text(
                                "***************",
                              )),
                          trailing:
                              Icon(Icons.copy, color: Colors.orangeAccent),
                          onLongPress: () {
                            Clipboard.setData(
                                new ClipboardData(text: '${user.fullName()}'));
                            Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text(
                              'تم النسخ',
                              style: TextStyle(fontSize: 17),
                            )));
                          },
                        );
                      },
                    )
                  : Container();
            }
          }),
    );
  }
}
