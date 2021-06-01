import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_network/models/user.dart';
import 'package:social_network/screens/comments.dart';
import 'package:social_network/screens/home.dart';
import 'package:social_network/widgets/activity_feed_item.dart';
import 'package:social_network/widgets/custom_image.dart';
import 'package:social_network/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String userId;
  final String username;
  final String location;
  final String caption;
  final String imageUrl;
  final dynamic likes;

  Post({
    required this.postId,
    required this.userId,
    required this.username,
    required this.location,
    required this.caption,
    required this.imageUrl,
    required this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      userId: doc['userId'],
      username: doc['username'],
      location: doc['location'],
      caption: doc['caption'],
      imageUrl: doc['imageUrl'],
      likes: doc['likes'],
    );
  }

  int getLikeCount(likes) {
    if (likes == null) {
      return 0;
    }

    int count = 0;

    likes.values.forEach((val) => {
          if (val == true) {count += 1}
        });

    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        userId: this.userId,
        username: this.username,
        location: this.location,
        caption: this.caption,
        imageUrl: this.imageUrl,
        likes: this.likes,
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser!.id;
  final String postId;
  final String userId;
  final String username;
  final String location;
  final String caption;
  final String imageUrl;
  int likeCount;
  Map likes;
  bool? isLiked;
  bool showHeart = false;

  _PostState({
    required this.postId,
    required this.userId,
    required this.username,
    required this.location,
    required this.caption,
    required this.imageUrl,
    required this.likeCount,
    required this.likes,
  });

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.doc(userId).get(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = currentUserId == userId;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner
              ? IconButton(
                  onPressed: () => handleDeletePost(context),
                  icon: Icon(Icons.more_vert),
                  alignment: Alignment.centerRight,
                )
              : Text(''),
        );
      },
    );
  }

  handleDeletePost(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Hapus post ini?'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              deletePost();
            },
            child: Text(
              'Hapus',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
            ),
          ),
        ],
      ),
    );
  }

  deletePost() async {
    QuerySnapshot followersSnapshot =
        await followersRef.doc(userId).collection('userFollowers').get();

    followersSnapshot.docs.forEach((doc) {
      timelineRef
          .doc(doc.id)
          .collection('timelinePosts')
          .doc(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    });

    postsRef.doc(userId).collection('userPosts').doc(postId).get().then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    storageRef.child('post_$postId.jpg').delete();

    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(userId)
        .collection('feedItems')
        .where('postId', isEqualTo: postId)
        .get();
    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    QuerySnapshot commentsSnapshot =
        await commentsRef.doc(postId).collection('comments').get();
    commentsSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  addLikeToAcitivityFeed() {
    bool isNotPostOwner = currentUserId != userId;

    if (isNotPostOwner) {
      activityFeedRef.doc(userId).collection('feedItems').add({
        'type': 'like',
        'username': currentUser!.username,
        'userId': currentUser!.id,
        'userImage': currentUser!.photoUrl,
        'commentData': '',
        'postId': postId,
        'imageUrl': imageUrl,
        'timestamp': timestamp,
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != userId;

    if (isNotPostOwner) {
      activityFeedRef
          .doc(userId)
          .collection('feedItems')
          .doc(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  handleLikePost() async {
    bool _isLiked = likes[currentUserId] == true;
    QuerySnapshot followerSnapshot =
        await followersRef.doc(userId).collection('userFollowers').get();

    if (_isLiked) {
      followerSnapshot.docs.forEach((doc) {
        timelineRef
            .doc(doc.id)
            .collection('timelinePosts')
            .doc(postId)
            .update({'likes.$currentUserId': false});
      });

      postsRef
          .doc(userId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': false});

      removeLikeFromActivityFeed();

      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      handleSendNotification(
        content: '${currentUser!.username} menyukai post anda',
      );

      followerSnapshot.docs.forEach((doc) {
        timelineRef
            .doc(doc.id)
            .collection('timelinePosts')
            .doc(postId)
            .update({'likes.$currentUserId': true});
      });

      postsRef
          .doc(userId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': true});

      addLikeToAcitivityFeed();

      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });

      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: [
          cachedNetworkImage(imageUrl),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.elasticOut,
                  cycles: 0,
                  builder: (context, anim, child) => Transform.scale(
                    scale: anim.value as double,
                    child: Icon(
                      Icons.favorite,
                      size: 80,
                      color: Colors.red,
                    ),
                  ),
                )
              : Text(''),
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: 40,
                left: 20,
              ),
            ),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked == true ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: Colors.pink,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20),
            ),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                userId: userId,
                imageUrl: imageUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(
                left: 20,
              ),
              child: Text(
                '$likeCount likes',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(
                left: 20,
              ),
              child: Text(
                '$username ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Text(caption),
            )
          ],
        )
      ],
    );
  }

  showComments(
    BuildContext context, {
    String? postId,
    String? userId,
    String? imageUrl,
  }) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Comments(
        postId: postId!,
        userId: userId!,
        imageUrl: imageUrl!,
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    isLiked = likes[currentUserId] == true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}
