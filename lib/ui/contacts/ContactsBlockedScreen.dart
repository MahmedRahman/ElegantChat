import 'package:elegant/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../constants.dart';
import '../../constants.dart' as Constants;
import '../../model/ContactModel.dart';
import '../../model/ConversationModel.dart';
import '../../model/HomeConversationModel.dart';
import '../../model/User.dart';
import '../../ui/chat/ChatScreen.dart';
import '../../ui/services/FirebaseHelper.dart';
import '../../ui/utils/helper.dart';

List<ContactModel> _searchResult = [];

List<ContactModel> _contacts = [];

class FriendsBlockedScreen extends StatefulWidget {
  final User user;

  const FriendsBlockedScreen({Key key, @required this.user}) : super(key: key);

  @override
  _FriendsBlockedScreenState createState() => _FriendsBlockedScreenState(user);
}

class _FriendsBlockedScreenState extends State<FriendsBlockedScreen> {
  final User user;
  bool showSearchBar = false;
  TextEditingController controller = TextEditingController();
  final fireStoreUtils = FireStoreUtils();

  _FriendsBlockedScreenState(this.user);

  Future<List<ContactModel>> _future;

  @override
  void initState() {
    super.initState();
    fireStoreUtils.getBlocks().listen((shouldRefresh) {
      if (shouldRefresh) {
        setState(() {});
      }
    });
    MyAppState.currentUser.searchBar = false;
    MyAppState.currentUser.refresh = true;
    if (MyAppState.currentUser.searchBar == true) {
      showSearchBar = !showSearchBar;
    }
    if (MyAppState.currentUser.refreshClick == true) {
      setState(() {
        MyAppState.currentUser.refreshClick = false;
        this.refresh();
      });
    }
    this.refresh();
  }

  refresh() {
    _future = fireStoreUtils.getContactsBlocked(user.userID);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "قائمة المحظورين",
          style: TextStyle(fontSize: Constants.FONT_SIZE_MEDIUM),
        ),
        backgroundColor: Color(Constants.COLOR_PRIMARY),
        actions: [
          IconButton(
              icon: Icon(Icons.refresh), onPressed: () => this.refresh()),
        ],
      ),
      body: Column(
        children: <Widget>[
          MyAppState.currentUser.searchBar == true
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
          Padding(padding: EdgeInsets.all(12.0)),
          FutureBuilder<List<ContactModel>>(
            future: _future,
            initialData: [],
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Expanded(
                  child: Container(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(COLOR_ACCENT),
                        ),
                      ),
                    ),
                  ),
                );
              } else if (!snap.hasData || snap.data.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Text(
                      'لا توجد نتائج',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                );
              } else {
                return Expanded(
                  child: _searchResult.length != 0 || controller.text.isNotEmpty
                      ? ListView.builder(
                          itemCount: _searchResult.length,
                          itemBuilder: (context, index) {
                            ContactModel contact = _searchResult[index];
                            return ListTile(
                              onTap: () async {
                                if (_searchResult[index].type ==
                                    ContactType.FRIEND) {
                                  String channelID;
                                  if (contact.user.userID
                                          .compareTo(user.userID) <
                                      0) {
                                    channelID =
                                        contact.user.userID + user.userID;
                                  } else {
                                    channelID =
                                        user.userID + contact.user.userID;
                                  }
                                  ConversationModel conversationModel =
                                      await fireStoreUtils
                                          .getChannelByIdOrNull(channelID);
                                  push(
                                    context,
                                    ChatScreen(
                                      homeConversationModel:
                                          HomeConversationModel(
                                              isGroupChat: false,
                                              members: [contact.user],
                                              conversationModel:
                                                  conversationModel),
                                    ),
                                  );
                                }
                              },
                              leading: displayCircleImage(
                                  contact.user.profilePictureURL, 48, false),
                              title: Text('${contact.user.fullName()}'),
                              //subtitle: Text('${contact.user.about}'),
                              trailing: RaisedButton(
                                elevation: 0,
                                onPressed: () async {
                                  bool result = await _onContactButtonClicked(
                                      contact, index, true);
                                  if (result) {
                                    hideProgress();
                                    setState(() {});
                                  } else {
                                    hideProgress();
                                    showAlertDialog(context,
                                        'Couldn\'t Process', 'Some Error ');
                                  }
                                },
                                child: Text(getStatusByType(contact.type)),
                              ),
                            );
                          })
                      : ListView.builder(
                          itemCount: snap.hasData ? snap.data.length : 0,
                          itemBuilder: (BuildContext context, int index) {
                            if (snap.hasData) {
                              _contacts = snap.data;
                              ContactModel contact = snap.data[index];
                              return ListTile(
                                onTap: () async {
                                  if (contact.type == ContactType.FRIEND) {
                                    String channelID;
                                    if (contact.user.userID
                                            .compareTo(user.userID) <
                                        0) {
                                      channelID =
                                          contact.user.userID + user.userID;
                                    } else {
                                      channelID =
                                          user.userID + contact.user.userID;
                                    }
                                    ConversationModel conversationModel =
                                        await fireStoreUtils
                                            .getChannelByIdOrNull(channelID);
                                    push(
                                      context,
                                      ChatScreen(
                                        homeConversationModel:
                                            HomeConversationModel(
                                                isGroupChat: false,
                                                members: [contact.user],
                                                conversationModel:
                                                    conversationModel),
                                      ),
                                    );
                                  }
                                },
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      contact.user.profilePictureURL),
                                ),
                                title: Text('${contact.user.fullName()}'),
                               // subtitle: Text('${contact.user.about}'),
                                trailing: RaisedButton(
                                  elevation: 0,
                                  color: Colors.grey[200],
                                  onPressed: () async {
                                    bool result = await _onContactButtonClicked(
                                        contact, index, false);
                                    if (result) {
                                      hideProgress();
                                      setState(() {});
                                    } else {
                                      hideProgress();
                                      showAlertDialog(context,
                                          'Couldn\'t Process', 'Some Error ');
                                    }
                                  },
                                  child: Text(getStatusByType(contact.type)),
                                ),
                              );
                            } else {
                              return Container();
                            }
                          },
                        ),
                );
              }
            },
          )
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

  Future<bool> _onContactButtonClicked(
      ContactModel contact, int index, bool fromSearch) async {
    bool isSuccessful = false;
    switch (contact.type) {
      case ContactType.ACCEPT:
        showProgress(context, 'قبول الصداقة ....', false);
        isSuccessful = await fireStoreUtils.onFriendAccept(
            contact.user, user.userID, false);
        if (isSuccessful) {
          if (fromSearch) {
            _searchResult[index].type = ContactType.FRIEND;
            _contacts
                .where((user) => user.user.userID == contact.user.userID)
                .first
                .type = ContactType.FRIEND;
          } else {
            _contacts[index].type = ContactType.FRIEND;
          }
        }
        break;
      case ContactType.FRIEND:
        showProgress(context, 'ازالة الصداقة', false);
        isSuccessful =
            await fireStoreUtils.onUnFriend(contact.user, user.userID, false);
        if (isSuccessful) {
          if (fromSearch) {
            _searchResult.removeAt(index);
            _contacts
                .removeWhere((item) => item.user.userID == contact.user.userID);
          } else {
            _contacts.removeAt(index);
          }
        }
        break;
      case ContactType.PENDING:
        showProgress(context, 'جارٍ إزالة طلب الصداقة ...', false);
        isSuccessful = await fireStoreUtils.onCancelRequest(
            contact.user.userID, user.userID, false);
        if (isSuccessful) {
          if (fromSearch) {
            _searchResult.removeAt(index);
            _contacts
                .removeWhere((item) => item.user.userID == contact.user.userID);
          } else {
            _contacts.removeAt(index);
          }
        }
        break;
      case ContactType.BLOCKED:
        showProgress(context, 'جارٍ الغاء الحظر ...', false);
        isSuccessful =
            await fireStoreUtils.onUnBlock(contact.user, user.userID, false);
        if (isSuccessful) {
          if (fromSearch) {
            _searchResult.removeAt(index);
            _contacts
                .removeWhere((item) => item.user.userID == contact.user.userID);
          } else {
            _contacts.removeAt(index);
          }
        }

        break;
      case ContactType.UNKNOWN:
//        showProgress(context, 'Sending Friendship Request...', false);
//        _contacts[index].type = ContactType.PENDING;
        break;
    }
    return isSuccessful;
  }
}
