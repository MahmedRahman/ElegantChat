import 'package:elegant/home.dart';
import 'package:elegant/ui/services/UserHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:toast/toast.dart';

import '../../constants.dart';
import '../../constants.dart' as Constants;
import '../../model/ContactModel.dart';
import '../../model/HomeConversationModel.dart';
import '../../model/User.dart';
import '../../ui/services/FirebaseHelper.dart';
import '../../ui/utils/helper.dart';

List<ContactModel> _searchResult = [];

List<ContactModel> _contacts = [];

class ContactsScreen extends StatefulWidget {
  final User user;

  const ContactsScreen({Key key, @required this.user}) : super(key: key);

  @override
  _ContactsScreenState createState() => _ContactsScreenState(user);
}

class _ContactsScreenState extends State<ContactsScreen> {
  final User user;
  bool showSearchBar = false;
  TextEditingController controller = TextEditingController();
  final fireStoreUtils = FireStoreUtils();
  bool visibile = true;
  FireStoreUtils _fireStoreUtils = FireStoreUtils();
  UserHelper _userHelper = UserHelper();
  TextEditingController _groupNameController = TextEditingController();
  TextEditingController _groupDescriptionController = TextEditingController();

  _ContactsScreenState(this.user);

  Future<List<ContactModel>> _future;

  @override
  void initState() {
    super.initState();
    _userHelper.notification(context, '');
    this.refresh();
    _userHelper.getPointsUser(widget.user.userID);
  }

  refresh() {
    _future = fireStoreUtils.getContacts(user.userID, false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("الغرف"),
        backgroundColor: Color(Constants.COLOR_PRIMARY),
        actions: [],
      ),
      body: Column(
        children: <Widget>[
          showSearchBar
              ? Padding(
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 8, bottom: 4),
                  child: TextField(
                    controller: controller,
                    onChanged: _onSearchTextChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(0),
                        isDense: true,
                        fillColor: Colors.grey[200],
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(360),
                            ),
                            borderSide: BorderSide(style: BorderStyle.none)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(360),
                            ),
                            borderSide: BorderSide(style: BorderStyle.none)),
                        hintText: 'ابحث ضمن اصدقاءك',
                        suffixIcon: IconButton(
                          iconSize: 20,
                          icon: Icon(Icons.close),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            controller.clear();
                            _onSearchTextChanged('');
                          },
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                        )),
                  ),
                )
              : Container(),
          ListTile(
            leading: Icon(Icons.people),
            title: Text("انشاء غرفة"),
            onTap: () => showDialog(
                context: context,
                builder: (context) {
                  return Center(
                      child: SingleChildScrollView(
                          child: Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 16,
                              child: Container(
                                height: 300,
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
                                          "إنشاء غرفة",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 16),
                                        TextField(
                                          textInputAction: TextInputAction.done,
                                          keyboardType: TextInputType.text,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          controller: _groupNameController,
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.only(
                                                left: 8.0,
                                                top: 2.0,
                                                bottom: 2.0),
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                borderSide: BorderSide(
                                                    color: Color(COLOR_ACCENT),
                                                    width: 2.0)),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0)),
                                            labelText: 'اسم الغرفة',
                                            labelStyle: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                top: 10.0,
                                                left: 16,
                                                right: 16,
                                                bottom: 16)),
                                        TextField(
                                          textInputAction: TextInputAction.done,
                                          keyboardType: TextInputType.text,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          controller:
                                              _groupDescriptionController,
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.only(
                                                left: 8.0,
                                                top: 2.0,
                                                bottom: 2.0),
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                borderSide: BorderSide(
                                                    color: Color(COLOR_ACCENT),
                                                    width: 2.0)),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0)),
                                            labelText: 'الوصف',
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
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text('إلغاء')),
                                            FlatButton(
                                                onPressed: () async {
                                                  if (_groupNameController
                                                          .text.isNotEmpty &&
                                                      _groupDescriptionController
                                                          .text.isNotEmpty) {
                                                    bool isSuccessful =
                                                        await _userHelper
                                                            .checkNameGroup(
                                                                _groupNameController
                                                                    .text);
                                                    if (isSuccessful) {
                                                      alert(context);
                                                    } else {
                                                      Toast.show(
                                                          "اسم الغرفة محجوز مسبقاً",
                                                          context,
                                                          duration:
                                                              Toast.LENGTH_LONG,
                                                          gravity:
                                                              Toast.CENTER);
                                                    }
                                                  } else {
                                                    Toast.show(
                                                        "يرجى ملئ جميع الحقول",
                                                        context,
                                                        duration:
                                                            Toast.LENGTH_LONG,
                                                        gravity: Toast.CENTER);
                                                  }
                                                },
                                                child: Text('إنشاء',
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
                }),
          ),
        ],
      ),
    );
  }

  _onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }
    _contacts.forEach((contact) {
      if (contact.user.fullName().toLowerCase().contains(text.toLowerCase())) {
        _searchResult.add(contact);
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    _searchResult.clear();
    super.dispose();
  }

  String getStatusByType(ContactType type) {
    switch (type) {
      case ContactType.ACCEPT:
        return 'قبول';
        break;
      case ContactType.PENDING:
        return 'رفض';
        break;
      case ContactType.FRIEND:
        return 'إلغاء الصداقة';
        break;
      case ContactType.UNKNOWN:
        return 'ارسال طلب';
        break;
      case ContactType.BLOCKED:
        return 'إلغاء الحظر';
        break;
      default:
        return 'ارسال طلب';
    }
  }

  Future<void> alert(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Align(
            alignment: Alignment.center,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 25),
                ),
                SizedBox(
                  width: 150,
                  child: new Image.asset("assets/images/mony.png"),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 15),
                ),
                Text(
                  "تكلفة إنشاء غرفة جديدة",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 15),
                ),
                SizedBox(
                  width: 150,
                  child: new Text("1500 نقطة", textAlign: TextAlign.center),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        FlatButton(
                          color: Color(Constants.COLOR_PRIMARY),
                          textColor: Colors.black,
                          child: Text(
                            'تأكيد',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () async {
                            bool isSuccessful =
                                await _userHelper.paymentPoints(1500);
                            if (isSuccessful) {
                              //hideProgress();
                              Toast.show("تم خصم 1500 نقطة بنجاح", context,
                                  duration: Toast.LENGTH_LONG,
                                  gravity: Toast.BOTTOM);
                              showProgress(
                                  context,
                                  ' جاري إنشاء الغرفة ، الرجاء الانتظار ...',
                                  false);

                              HomeConversationModel groupChatConversationModel =
                                  await _fireStoreUtils
                                      .createGroupChatWithoutFriends(
                                          widget.user,
                                          _groupNameController.text,
                                          _groupDescriptionController.text);
                              hideProgress();
                              Navigator.pop(context);
                              pushReplacement(context, Home(user: user));
                            } else {
                              hideProgress();
                              Toast.show("رصيد نقاطك غير كافي", context,
                                  duration: Toast.LENGTH_LONG,
                                  gravity: Toast.CENTER);
                            }
                          },
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        FlatButton(
                          color: Color(Constants.COLOR_SECONDARY),
                          textColor: Colors.black,
                          child: Text(
                            'رجوع',
                            style:
                                TextStyle(fontSize: Constants.FONT_SIZE_MEDIUM),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ]),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
