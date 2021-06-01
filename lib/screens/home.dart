import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:social_network/models/user.dart';
import 'package:social_network/screens/activity_feed.dart';
import 'package:social_network/screens/profile.dart';
import 'package:social_network/screens/search.dart';
import 'package:social_network/screens/timeline.dart';
import 'package:social_network/screens/upload.dart';
import 'package:social_network/screens/create_account.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);
CollectionReference usersRef = FirebaseFirestore.instance.collection('users');
CollectionReference postsRef = FirebaseFirestore.instance.collection('posts');
CollectionReference commentsRef =
    FirebaseFirestore.instance.collection('comments');
CollectionReference activityFeedRef =
    FirebaseFirestore.instance.collection('feed');
CollectionReference followersRef =
    FirebaseFirestore.instance.collection('followers');
CollectionReference followingRef =
    FirebaseFirestore.instance.collection('following');
CollectionReference timelineRef =
    FirebaseFirestore.instance.collection('timeline');
final firebase_storage.Reference storageRef =
    firebase_storage.FirebaseStorage.instance.ref();
final DateTime timestamp = DateTime.now();
User? currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController? pageController;
  int index = 0;

  @override
  initState() {
    super.initState();

    pageController = PageController();

    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSingin(account);
    }, onError: (err) {
      print('Erron when sign in: $err');
    });

    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSingin(account);
    }).catchError((err) {
      print('Erron when sign in: $err');
    });
  }

  handleSingin(GoogleSignInAccount? account) async {
    if (account != null) {
      await addUser();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  addUser() async {
    final GoogleSignInAccount user = googleSignIn.currentUser!;
    DocumentSnapshot doc = await usersRef.doc(user.id).get();

    if (!doc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));

      usersRef.doc(user.id).set({
        'id': user.id,
        'username': username,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'email': user.email,
        'bio': '',
        'timestamp': timestamp,
      });

      await followersRef
          .doc(user.id)
          .collection('userFollowers')
          .doc(user.id)
          .set({});

      doc = await usersRef.doc(user.id).get();
    }

    currentUser = User.fromDocument(doc);
  }

  @override
  void dispose() {
    pageController?.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    try {
      await googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> handleLogout() => googleSignIn.disconnect();

  handleChangePage(int index) {
    setState(() {
      this.index = index;
    });
  }

  handleOnTap(int index) {
    pageController?.animateToPage(
      index,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        children: [
          Timeline(currentUser: currentUser!),
          ActivityFeed(),
          Upload(currentUser!),
          Search(),
          Profile(currentUser!.id),
        ],
        controller: pageController,
        onPageChanged: handleChangePage,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
          ),
        ],
        currentIndex: index,
        onTap: handleOnTap,
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Colors.cyan,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Social Network App',
              style: TextStyle(
                fontFamily: 'Signatra',
                fontSize: 40,
                color: Colors.white,
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 30),
              width: 250,
              child: TextButton(
                onPressed: handleLogin,
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 10,
                      bottom: 10,
                    ),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    )),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/google.svg',
                      height: 20,
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 5),
                      child: Text(
                        'Masuk Dengan Google',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}

handleSendNotification({String content = ''}) async {
  var deviceState = await OneSignal.shared.getDeviceState();

  if (deviceState == null || deviceState.userId == null) return;

  var playerId = deviceState.userId!;

  // var imgUrlString =
  //     "http://cdn1-www.dogtime.com/assets/uploads/gallery/30-impossibly-cute-puppies/impossibly-cute-puppy-2.jpg";

  var notification = OSCreateNotification(
    playerIds: [playerId],
    heading: 'Notifikasi',
    content: content,
    // iosAttachments: {"id1": imgUrlString},
    // bigPicture: imgUrlString,
    // buttons: [
    //   OSActionButton(text: "test1", id: "id1"),
    //   OSActionButton(text: "test2", id: "id2")
    // ]
  );

  var response = await OneSignal.shared.postNotification(notification);

  print(response);
}
