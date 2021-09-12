import 'package:elegant/ui/account/ProfileScreen.dart';
import 'package:flutter/material.dart';

import '../../constants.dart' as Constants;
import '../../main.dart';
import '../../model/ContactModel.dart';
import '../../model/ConversationModel.dart';
import '../../model/HomeConversationModel.dart';
import '../../model/User.dart';
import '../chat/ChatScreen.dart';
import '../services/FirebaseHelper.dart';
import '../utils/helper.dart';

List<ContactModel> _searchResult = [];

class SearchScreen extends StatefulWidget {
  final User user;

  const SearchScreen({Key key, @required this.user}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState(user);
}

class _SearchScreenState extends State<SearchScreen> {
  final User user;
  TextEditingController controller = TextEditingController();
  final fireStoreUtils = FireStoreUtils();
  bool isSearching = false;

  _SearchScreenState(this.user);

  @override
  void initState() {
    super.initState();
    fireStoreUtils.getBlocks().listen((shouldRefresh) {
      if (shouldRefresh) {
        setState(() {});
      }
    });
    // _future = fireStoreUtils.getContacts(user.userID, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("البحث عن اصدقاء"),
        backgroundColor: Color(Constants.COLOR_PRIMARY),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 4),
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
                  hintText: 'البحث',
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
          ),
          Expanded(
            child: _searchResult.length != 0
                ? ListView.builder(
                    itemCount: _searchResult.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: displayCircleImage(
                            _searchResult[index].user.profilePictureURL,
                            42,
                            false),
                        title: Text(
                          _searchResult[index].user.name,
                          style: TextStyle(fontSize: 12),
                        ),
                        // subtitle: Text(_searchResult[index].user.about.length>50? _searchResult[index].user.about.substring(0,50):_searchResult[index].user.about),

                        trailing: RaisedButton(
                          onPressed: () async {
                            print(_searchResult[index].type);
                            bool result = await _onContactButtonClicked(
                                _searchResult[index], index, false);
                            print(result);
                            if (result) {
                              hideProgress();
                              setState(() {});
                            } else {
                              hideProgress();
                              // showAlertDialog(
                              //     context, 'Error', 'Something went wrong');
                            }
                          },
                          child: Text(
                            getStatusByType(_searchResult[index].type),
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        onTap: () async {
                          if (_searchResult[index].type == ContactType.FRIEND) {
                         
                            String channelID;
                            if (_searchResult[index]
                                    .user
                                    .userID
                                    .compareTo(user.userID) <
                                0) {
                              channelID = _searchResult[index].user.userID +
                                  user.userID;
                            } else {
                              channelID = user.userID +
                                  _searchResult[index].user.userID;
                            }
                            ConversationModel conversationModel =
                                await fireStoreUtils
                                    .getChannelByIdOrNull(channelID);
                            push(
                              context,
                              ChatScreen(
                                homeConversationModel: HomeConversationModel(
                                    isGroupChat: false,
                                    members: [_searchResult[index].user],
                                    conversationModel: conversationModel),
                              ),
                            );
                            
                          } else {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    new ProfileScreen(
                                        user1: MyAppState.currentUser,
                                        user2: _searchResult[index].user)));
                          }
                        },
                      );
                    })
                : Container(
                    child: Center(
                      child: isSearching
                          ? CircularProgressIndicator()
                          : Container(
                              child: controller.text.length != 0
                                  ? Text(" لا توجد نتائج ${controller.text}")
                                  : Text("ابدأ بالبحث"),
                            ),
                    ),
                  ),
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

    setState(() => isSearching = true);

    fireStoreUtils.searchContacts(user.userID, text).then((contact) {
      if (contact.length > 0) {
        contact.forEach((element) {
          print(element.user.name);
          _searchResult.add(element);
        });
        setState(() {
          _searchResult = _searchResult;
          isSearching = false;
        });
      } else {
        setState(() {
          _searchResult = [];
          isSearching = false;
        });
      }
    }).catchError((e) {
      print(e);
    });
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
        return 'إلغاء';
        break;
      case ContactType.FRIEND:
        return ' انتم اصدقاء بالفعل';
        break;
      case ContactType.UNKNOWN:
        return 'اضافة';
        break;
      case ContactType.BLOCKED:
        return 'الغاء الحظر';
        break;
      default:
        return 'اضافة كصديق';
    }
  }

  Future<bool> _onContactButtonClicked(
      ContactModel contact, int index, bool fromSearch) async {
    bool isSuccessful = false;
    switch (contact.type) {
      case ContactType.ACCEPT:
        showProgress(context, 'قبول الصداقة ...', false);
        isSuccessful = await fireStoreUtils.onFriendAccept(
            contact.user, user.userID, false);
        if (isSuccessful) {
          _searchResult[index].type = ContactType.FRIEND;
        }
        break;
      case ContactType.FRIEND:
      //إزالة الصداقة
      /*
        showProgress(context, 'إزالة الصداقة ...', false);
        isSuccessful =
            await fireStoreUtils.onUnFriend(contact.user, user.userID, false);
        if (isSuccessful) {
          _searchResult.removeAt(index);
        }*/
        break;
      case ContactType.PENDING:
        showProgress(context, 'جارٍ إزالة طلب الصداقة ...', false);
        isSuccessful = await fireStoreUtils.onCancelRequest(
            contact.user.userID, user.userID, false);
        if (isSuccessful) {
          _searchResult.removeAt(index);
        }
        break;
      case ContactType.BLOCKED:
        break;
      case ContactType.UNKNOWN:
        showProgress(context, 'إرسال طلب صداقة ...', false);
        isSuccessful =
            await fireStoreUtils.sendFriendRequest(contact.user, user.userID);
        _searchResult[index].type = ContactType.PENDING;
        break;
    }
    return isSuccessful;
  }
}
