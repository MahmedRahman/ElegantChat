import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_list_pick/country_list_pick.dart';
import 'package:country_list_pick/country_selection_theme.dart';
import 'package:elegant/model/Friendship.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:select_form_field/select_form_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

import '../../constants.dart';
import '../../constants.dart' as Constants;
import '../../main.dart';
import '../../model/User.dart';
import '../../ui/auth/AuthScreen.dart';
import '../../ui/contacts/ContactsBlockedScreen.dart';
import '../../ui/services/FirebaseHelper.dart';
import '../../ui/utils/helper.dart';
import 'crop.dart';

class AccountDetailsScreen extends StatefulWidget {
  final User user;

  AccountDetailsScreen({Key key, @required this.user}) : super(key: key);

  @override
  _AccountDetailsScreenState createState() {
    return _AccountDetailsScreenState(user);
  }
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  @override
  void initState() {
    super.initState();
    getFriends(user.userID);
  }

  User user;
  int randomNumber = 0;
  String emailNew;
  bool _visibleMarkIcon = false;
  String iconMark = "";
  String emailOld;

  static Firestore firestore = Firestore.instance;
  GlobalKey<FormState> _key = GlobalKey();
  bool _validate = false;
  String name,
      emailCurrent,
      phone,
      about,
      gender,
      age,
      country,
      merchantID,
      getCountry,
      friends = "0",
      textType,
      urlIcon;

  TextEditingController _phone = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _aboutController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  final List<Map<String, dynamic>> _items = [
    {
      'value': '',
      'label': 'تحديد',
    },
    {
      'value': 'male',
      'label': 'male',
    },
    {
      'value': 'female',
      'label': 'female',
    },
  ];
  FireStoreUtils _fireStoreUtils = FireStoreUtils();

  _AccountDetailsScreenState(this.user);

  @override
  Widget build(BuildContext context) {
    if (!_validate) {
      name = user.name;
      gender = user.gender;
      merchantID = user.merchantID;
      country = user.country.toString();
      textType = user.typeUser;
      _aboutController.text = user.about;
      _phone.text = user.phone;
      emailCurrent = user.associatedEmail;
      _ageController.text = user.age;

      switch (textType) {
        case "user":
          textType = "مستخدم عادي";
          urlIcon = "assets/images/icon_user.png";
          break;
        case "admin":
          textType = "حساب مسؤول موثق";
          urlIcon = "assets/images/icon_admin.png";
          iconMark = "assets/images/mark_admin.png";
          _visibleMarkIcon = true;
          break;
        case "merchant":
          textType = "حساب تاجر - مارشنت";
          urlIcon = "assets/images/icon_merchant.png";
          iconMark = "assets/images/mark_merchant.png";
          _visibleMarkIcon = true;
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
          'تعديل الملف الشخصي',
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
                              child: displayCircleImage(
                                  user.profilePictureURL, 130, false)),
                          Positioned(
                            left: 80,
                            right: 0,
                            child: FloatingActionButton(
                                backgroundColor: Color(COLOR_ACCENT),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                                mini: true,
                                onPressed: _onCameraClick),
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
                            style: TextStyle(fontSize: 20),
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
                        //number of friends
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
                                  friends,
                                ),
                              ),
                            ],
                          ),
                        ),
                        //created at
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
                    SizedBox(height: 20.0),
                    //MarkIcon
                    Visibility(
                      visible: _visibleMarkIcon,
                      child: Center(
                        child:
                            Container(width: 250, child: Image.asset(iconMark)),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    //status
                    TextFormField(
                      style: TextStyle(fontSize: 14),
                      onSaved: (String val) {
                        about = val;
                      },
                      controller: _aboutController,
                      cursorColor: Color(COLOR_ACCENT),
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          contentPadding:
                              EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey[300], width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey[300], width: 2.0),
                          ),
                          labelText: "الحالة"),
                    ),
                    SizedBox(height: 16.0),
                    //privateLock
                    ListTile(
                      title: Text("القفل الخاص"),
                      //subtitle: Text("تفعيل / إلغاء تفعيل القفل الخاص"),
                      trailing: Switch(
                          value: user.privateLock != null
                              ? user.privateLock
                              : false,
                          onChanged: (bool newValue) async {
                            user.privateLock = newValue;
                            showProgress(context, 'جار حفظ التغييرات', true);
                            if (newValue) {
                              await firestore
                                  .collection(USERS)
                                  .document(user.userID)
                                  .updateData({'privateLock': newValue});

                              hideProgress();
                              this.user.privateLock = newValue;
                              MyAppState.currentUser.privateLock = newValue;

                              setState(() {});
                            } else {
                              await firestore
                                  .collection(USERS)
                                  .document(user.userID)
                                  .updateData({'privateLock': newValue});

                              hideProgress();
                              this.user.privateLock = newValue;
                              MyAppState.currentUser.privateLock = newValue;

                              setState(() {});
                            }
                          }),
                    ),

                    //hideFriends
                    ListTile(
                      title: Text("اخفاء الاصدقاء"),
                      //subtitle: Text("تفعيل / إلغاء تفعيل القفل الخاص"),
                      trailing: Switch(
                          value: user.hideFriends != null
                              ? user.hideFriends
                              : false,
                          onChanged: (bool newValue) async {
                            user.hideFriends = newValue;
                            showProgress(context, 'جار حفظ التغييرات', true);
                            if (newValue) {
                              await firestore
                                  .collection(USERS)
                                  .document(user.userID)
                                  .updateData({'hideFriends': newValue});

                              hideProgress();
                              this.user.hideFriends = newValue;
                              MyAppState.currentUser.hideFriends = newValue;

                              setState(() {});
                            } else {
                              await firestore
                                  .collection(USERS)
                                  .document(user.userID)
                                  .updateData({'hideFriends': newValue});

                              hideProgress();
                              this.user.hideFriends = newValue;
                              MyAppState.currentUser.hideFriends = newValue;

                              setState(() {});
                            }
                          }),
                    ),

                    //email
                    SizedBox(height: 16.0),
                    Text(
                      "البريد الالكتروني المرتبط",
                      style: TextStyle(fontSize: 11),
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                           emailCurrent.toString().length <=3 ? 'برجاء كتابة بريد الالكترونى ' :  '${emailCurrent.toString().substring(2)}******il',
                          style: TextStyle(fontSize: 15),
                        ),
                        SizedBox(width: 15.0),
                        IconButton(
                            icon: const Icon(
                              Icons.delete_forever_outlined,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              Random random = new Random();
                              setState(() {
                                randomNumber = random.nextInt(9999);
                              });
                              if (emailCurrent == "@") {
                                Toast.show("لا يوجد ايميل لحذفه", context,
                                    duration: Toast.LENGTH_LONG,
                                    gravity: Toast.CENTER);
                              } else {
                                alertConfirmSendCode(context);
                              }
                            }),
                        IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.green,
                            ),
                            onPressed: () async {
                              Random random = new Random();
                              setState(() {
                                randomNumber = random.nextInt(9999);
                              });
                              if (emailCurrent == "@") {
                                verficationEmail("new");
                              } else {
                                alertConfirmSendCode(context);
                              }
                            }),
                      ],
                    ),
                    SizedBox(height: 12.0),

                    //phone
                    TextFormField(
                      style: TextStyle(fontSize: 14),
                      onSaved: (String val) {
                        phone = val;
                      },
                      validator: validateMobile,
                      controller: _phone,
                      cursorColor: Color(COLOR_ACCENT),
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          contentPadding:
                              EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey[300], width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey[300], width: 2.0),
                          ),
                          labelText: "رقم الهاتف"),
                    ),
                    SizedBox(height: 16.0),

                    //age
                    TextFormField(
                      style: TextStyle(fontSize: 14),
                      onSaved: (String val) {
                        age = val;
                      },
                      controller: _ageController,
                      cursorColor: Color(COLOR_ACCENT),
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          contentPadding:
                              EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey[300], width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey[300], width: 2.0),
                          ),
                          labelText: " العمر "),
                    ),
                    SizedBox(height: 16.0),
                    // Country
                    CountryListPick(
                      appBar: AppBar(
                        backgroundColor: Colors.orangeAccent,
                        title: Text('اختر بلدك'),
                      ),

                      // if you need custom picker use this

                      // To disable option set to false
                      theme: CountryTheme(
                        isShowFlag: true,
                        isShowTitle: true,
                         isShowCode: false,
                        isDownIcon: true,
                        showEnglishName: true,
                      ),
                      // Set default value
                      initialSelection: country,
                      onChanged: (CountryCode code) {
                        country = code.dialCode.toString();
                        print(country);

                        //country = code.dialCode;

                        print(code.name);
                        print(code.code);
                        print(code.dialCode);
                        print(code.flagUri);
                      },
                      // Whether to allow the widget to set a custom UI overlay
                      useUiOverlay: false,
                      // Whether the country list should be wrapped in a SafeArea
                      useSafeArea: false,
                    ),

                    //gender
                    SelectFormField(
                      type: SelectFormFieldType.dialog,
                      // or can be dialog
                      initialValue: gender,
                      labelText: ' الجنس',
                      hintText: gender,
                      items: _items,
                      onChanged: (val) => gender = val,
                      onSaved: (val) => gender,
                    ),
                    SizedBox(height: 16.0),
                    SizedBox(height: 16.0),
                    InkWell(
                      onTap: () {
                        _resetPassword(context, user);
                      },
                      child: new Text("استعادة الحساب "),
                    ),
                    SizedBox(height: 14),

                    // list block
                    InkWell(
                      onTap: () {
                        push(context, FriendsBlockedScreen(user: user));
                      },
                      child: new Text("قائمة الحظر"),
                    ),
                    SizedBox(height: 14),

                    SizedBox(height: 14),
                    //createdAt
                    Text(
                      "تاريخ انشاء الحساب",
                    ),
                    SizedBox(height: 8.0),

               
                    Text(DateFormat("dd-MM-yyyy").format(user.createdAt.toDate()).toString()),
                    SizedBox(height: 8.0),
                    SizedBox(height: 16.0),

                    //save update
                    Container(
                      width: double.infinity,
                      child: RaisedButton(
                        color: Color(COLOR_PRIMARY),
                        textColor: Colors.white,
                        child: Text("حفظ التعديلات"),
                        onPressed: () async {
                          showDialog(
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
                                        height: 140,
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
                                                "حفظ التغييرات",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: <Widget>[
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: Text('إلغاء')),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      _validateAndSave(
                                                          buildContext);
                                                    },
                                                    child: Text(
                                                      'نعم',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                            COLOR_PRIMARY),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              });
                        },
                      ),
                    ),
                    SizedBox(height: 14),

                    //reset password

                    SizedBox(height: 14),

                    //logout

                    SizedBox(height: 14),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  _resetPassword(BuildContext context, User user) {
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
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('إلغاء')),
                                    TextButton(
                                        onPressed: () async {
                                          if (_passwordController
                                                  .text.isNotEmpty &&
                                              _passwordController.text ==
                                                  _confirmController.text &&
                                              _passwordController.text.length >
                                                  5) {
                                            showProgress(context,
                                                "يرجى الانتظار ...", false);

                                            if (_passwordController
                                                .text.isNotEmpty) {
                                              await firestore
                                                  .collection(USERS)
                                                  .document(user.userID)
                                                  .updateData({
                                                'password': _passwordController
                                                    .text
                                                    .trim()
                                              });
                                              print(user.userID);
                                              setState(() {
                                                MyAppState
                                                        .currentUser.password =
                                                    _passwordController.text
                                                        .trim();
                                              });
                                              hideProgress();

                                              Navigator.pop(context);
                                              Toast.show("تم تغيير كلمة المرور",
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

  _validateAndSave(BuildContext buildContext) async {
    if (_key.currentState.validate()) {
      _key.currentState.save();

      showProgress(context, "جار الحفظ ...", false);
      await _updateUser(buildContext);
      hideProgress();
    } else {
      setState(() {
        _validate = true;
      });
    }
  }

  _updateUser(BuildContext buildContext) async {
    user.name = name;
    user.about = about;
    user.phone = phone;
    user.gender = gender;
    user.merchantID = merchantID;
    user.country = country.toString();
    user.age = age;

    print(phone);

    var updatedUser = await FireStoreUtils().updateCurrentUser(user, context);
    if (updatedUser != null) {
      MyAppState.currentUser = user;
      Scaffold.of(buildContext).showSnackBar(SnackBar(
          content: Text(
        'تم حفظ البيانات',
        style: TextStyle(fontSize: 17),
      )));
    } else {
      Scaffold.of(buildContext).showSnackBar(SnackBar(
          content: Text(
        'فشل الحفظ , حاول لاحقا',
        style: TextStyle(fontSize: 17),
      )));
    }
  }

  Future<void> _imagePicked(File image) async {
    showProgress(context, 'جار تحميل الصورة', false);
    user.profilePictureURL =
        await _fireStoreUtils.uploadUserImageToFireStorage(image, user.userID);
    await _fireStoreUtils.updateCurrentUser(user, context);
    MyAppState.currentUser = user;
    hideProgress();
  }

  @override
  void dispose() {
    _aboutController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<List<Friendship>> getFriends(String userID) async {
    List friendshipList = [];
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

  Future<void> _sendCode(int code, String email, String action) async {
    final response = await http
        .post(Constants.URL_HOSTING_API + Constants.URL_SEND_CODE_EMAIL, body: {
      "code": code.toString(),
      "email": email,
    });
    print(response.body);
    var dataUser = json.decode(response.body);
    if (dataUser.length == 0) {
      Toast.show("فشل ارسال رمز التحقق", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
    } else {
      if (dataUser[0]['result'] == 'success') {
        TextEditingController _codeController = TextEditingController();
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
                                      "أدخل رمز التحقق :",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
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
                                      keyboardType: TextInputType.text,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      maxLines: 1,
                                      controller: _codeController,
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
                                        labelText: 'الرمز :',
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
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('إلغاء')),
                                        TextButton(
                                            onPressed: () async {
                                              if (_codeController.text !=
                                                      null &&
                                                  _codeController.text.trim() ==
                                                      randomNumber.toString()) {
                                                if (action == "delete") {
                                                  await firestore
                                                      .collection(USERS)
                                                      .document(user.userID)
                                                      .updateData({
                                                    'associatedEmail': "@"
                                                  });
                                                  setState(() {
                                                    MyAppState.currentUser
                                                        .associatedEmail = "@";
                                                    emailCurrent = "@";
                                                  });
                                                  hideProgress();
                                                  Navigator.pop(context);
                                                  Toast.show(
                                                      "تم حذف الايميل", context,
                                                      duration:
                                                          Toast.LENGTH_LONG,
                                                      gravity: Toast.CENTER);
                                                }
                                                if (action == 'new') {
                                                  showProgress(
                                                      context,
                                                      'جاري تحديث البريد ',
                                                      false);

                                                  if (email.isNotEmpty) {
                                                    await firestore
                                                        .collection(USERS)
                                                        .document(user.userID)
                                                        .updateData({
                                                      'associatedEmail':
                                                          email.trim()
                                                    });
                                                    setState(() {
                                                      MyAppState.currentUser
                                                              .associatedEmail =
                                                          email.trim();
                                                      emailCurrent =
                                                          email.trim();
                                                    });
                                                    hideProgress();
                                                    Navigator.pop(context);
                                                    Navigator.pop(context);
                                                  }
                                                }
                                                // else {
                                                //   TextEditingController
                                                //       _emailNewController =
                                                //       TextEditingController();
                                                //   showDialog(
                                                //       context: context,
                                                //       builder: (context) {
                                                //         return Center(
                                                //             child: SingleChildScrollView(
                                                //                 child: Dialog(
                                                //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                //                     elevation: 16,
                                                //                     child: Container(
                                                //                       height:
                                                //                           250,
                                                //                       width:
                                                //                           350,
                                                //                       child: Padding(
                                                //                           padding: const EdgeInsets.only(top: 20.0, left: 16, right: 16, bottom: 16),
                                                //                           child: Column(
                                                //                             mainAxisSize:
                                                //                                 MainAxisSize.min,
                                                //                             crossAxisAlignment:
                                                //                                 CrossAxisAlignment.start,
                                                //                             children: <Widget>[
                                                //                               Text(
                                                //                                 "البريد الالكتروني الجديد :",
                                                //                                 style: TextStyle(fontWeight: FontWeight.bold),
                                                //                               ),
                                                //                               SizedBox(height: 16),
                                                //                               Padding(padding: const EdgeInsets.only(top: 10.0, left: 16, right: 16, bottom: 16)),
                                                //                               TextField(
                                                //                                 textInputAction: TextInputAction.done,
                                                //                                 keyboardType: TextInputType.text,
                                                //                                 textCapitalization: TextCapitalization.sentences,
                                                //                                 maxLines: 1,
                                                //                                 controller: _emailNewController,
                                                //                                 decoration: InputDecoration(
                                                //                                   contentPadding: EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0),
                                                //                                   focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Color(COLOR_ACCENT), width: 2.0)),
                                                //                                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                                //                                   labelText: 'الايميل الجديد :',
                                                //                                   labelStyle: TextStyle(
                                                //                                     fontSize: 12,
                                                //                                   ),
                                                //                                 ),
                                                //                               ),
                                                //                               Padding(padding: const EdgeInsets.only(top: 10.0, left: 16, right: 16, bottom: 16)),
                                                //                               SizedBox(height: 14),
                                                //                               Row(
                                                //                                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                //                                 children: <Widget>[
                                                //                                   TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
                                                //                                   TextButton(
                                                //                                       onPressed: () async {
                                                //                                         showProgress(context, 'جاري تحديث البريد ', false);
                                                //
                                                //                                         if (_emailNewController.text.isNotEmpty) {
                                                //                                           await firestore.collection(USERS).document(user.userID).updateData({
                                                //                                             'associatedEmail': _emailNewController.text.trim()
                                                //                                           });
                                                //                                           setState(() {
                                                //                                             MyAppState.currentUser.associatedEmail = _emailNewController.text.trim();
                                                //                                             emailCurrent = _emailNewController.text.trim();
                                                //                                           });
                                                //                                           hideProgress();
                                                //                                           Navigator.pop(context);
                                                //                                           Toast.show("تم تحديث البريد", context, duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
                                                //                                         }
                                                //                                         if (_emailNewController.text.isEmpty) {
                                                //                                           hideProgress();
                                                //                                           Toast.show("يرجى كتابة الايميل", context, duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
                                                //                                         }
                                                //                                         hideProgress();
                                                //                                       },
                                                //                                       child: Text('تأكيد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(COLOR_ACCENT)))),
                                                //                                 ],
                                                //                               )
                                                //                             ],
                                                //                           )),
                                                //                     ))));
                                                //       });
                                                // }
                                              } else {
                                                hideProgress();
                                                Toast.show(
                                                    "رمز التحقق خاطئ", context,
                                                    duration: Toast.LENGTH_LONG,
                                                    gravity: Toast.CENTER);
                                              }
                                            },
                                            child: Text('تأكيد',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Color(COLOR_ACCENT)))),
                                      ],
                                    )
                                  ],
                                )),
                          ))));
            });
      } else if (dataUser[0]['result'] == 'error') {
        hideProgress();
        Toast.show("فشل ارسال رمز التحقق", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
      }
    }
  }

  _onCameraClick() {
    showModalBottomSheet(
        context: context,
        builder: (bc) {
          return Container(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text("التقاط من الكاميرا"),
                  onTap: () async {
                    // Navigator.pop(context);
                    // var image =
                    //     await ImagePicker.pickImage(source: ImageSource.camera);
                    // if (image != null) {
                    //   await _imagePicked(image);
                    // }
                    // setState(() {});
                    Navigator.pop(context);
                    // var image =
                    // await ImagePicker.pickImage(source: ImageSource.camera);
                    // if (image != null) {
                    //   await _imagePicked(image);
                    // }
                    // setState(() {});
                    final result = await Navigator.push(
                        context,
                        // Create the SelectionScreen in the next step.
                        MaterialPageRoute(
                            builder: (context) => CropImage(type: 'camera')));
                    if (result != null) {
                      await _imagePicked(result);
                    } else {}
                    // Navigator.pop(context);

                    setState(() {});
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo),
                  title: Text("صورة من المعرض"),
                  onTap: () async {
                    // Navigator.pop(context);
                    // var image = await ImagePicker.pickImage(
                    //     source: ImageSource.gallery);
                    // if (image != null) {
                    //   await _imagePicked(image);
                    // }
                    // setState(() {});
                    Navigator.pop(context);
                    // var image =
                    // await ImagePicker.pickImage(source: ImageSource.camera);
                    // if (image != null) {
                    //   await _imagePicked(image);
                    // }
                    // setState(() {});
                    final result = await Navigator.push(
                        context,
                        // Create the SelectionScreen in the next step.
                        MaterialPageRoute(
                            builder: (context) => CropImage(type: 'gallery')));
                    if (result != null) {
                      await _imagePicked(result);
                    } else {}
                    // Navigator.pop(context);

                    setState(() {});
                  },
                ),
                ListTile(
                  leading: Icon(Icons.cancel),
                  title: Text("إزالة الصورة"),
                  onTap: () async {
                    Navigator.pop(context);
                    showProgress(context, 'حذف الصورة', false);
                    user.profilePictureURL = DEFAULT_URL;
                    await _fireStoreUtils.updateCurrentUser(user, context);
                    MyAppState.currentUser = user;
                    hideProgress();
                    setState(() {});
                  },
                ),
                ListTile(
                  title: Text("إلغاء"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        });
  }

  alertConfirmSendCode(BuildContext context) {
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
                        height: 170,
                        width: 350,
                        child: Padding(
                            padding: const EdgeInsets.only(
                                top: 20.0, left: 16, right: 16, bottom: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "سيتم ارسال رمز تحقق الى :",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  emailCurrent,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('إلغاء')),
                                    TextButton(
                                        onPressed: () async {
                                          _sendCode(randomNumber,
                                              emailCurrent.trim(), 'delete');
                                          Navigator.pop(context);
                                        },
                                        child: Text('متابعة',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(COLOR_PRIMARY)))),
                                  ],
                                )
                              ],
                            )),
                      ))));
        });
  }

  alertLogout(BuildContext context) {
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
                        height: 140,
                        width: 350,
                        child: Padding(
                            padding: const EdgeInsets.only(
                                top: 20.0, left: 16, right: 16, bottom: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "تأكيد تسجيل الخروج",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('إلغاء')),
                                    TextButton(
                                        onPressed: () async {
                                          user.active = false;

                                          _fireStoreUtils.updateUser(
                                              false, user.userID);
                                          MyAppState.currentUser = null;

                                          SharedPreferences shard =
                                              await SharedPreferences
                                                  .getInstance();
                                          shard.clear();
                                          pushAndRemoveUntil(
                                              context, AuthScreen(), false);
                                        },
                                        child: Text('تسجيل خروج',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(COLOR_PRIMARY)))),
                                  ],
                                )
                              ],
                            )),
                      ))));
        });
  }

  verficationEmail(String s) {
    TextEditingController _emailNewController = TextEditingController();
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
                                  "البريد الالكتروني  :",
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
                                  keyboardType: TextInputType.text,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLines: 1,
                                  controller: _emailNewController,
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
                                    labelText: 'الايميل  :',
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
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('إلغاء')),
                                    TextButton(
                                        onPressed: () async {
                                          _sendCode(
                                              randomNumber,
                                              _emailNewController.text.trim(),
                                              'new');
                                          if (_emailNewController
                                              .text.isEmpty) {
                                            hideProgress();
                                            Toast.show(
                                                "يرجى كتابة الايميل", context,
                                                duration: Toast.LENGTH_LONG,
                                                gravity: Toast.CENTER);
                                          }
                                          hideProgress();
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
