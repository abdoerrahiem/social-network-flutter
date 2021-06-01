import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_network/screens/home.dart';
import 'package:social_network/widgets/header.dart';
import 'package:social_network/widgets/progress.dart';
import 'package:social_network/widgets/comment.dart';

class Comments extends StatefulWidget {
  final String postId;
  final String userId;
  final String imageUrl;

  Comments({
    required this.postId,
    required this.userId,
    required this.imageUrl,
  });

  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        userId: this.userId,
        imageUrl: this.imageUrl,
      );
}

class CommentsState extends State<Comments> {
  final String postId;
  final String userId;
  final String imageUrl;
  TextEditingController commentController = TextEditingController();

  CommentsState({
    required this.postId,
    required this.userId,
    required this.imageUrl,
  });

  buildComments() {
    return StreamBuilder<QuerySnapshot>(
      stream: commentsRef
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        List<Comment> comments = [];
        snapshot.data!.docs.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });

        return ListView(
          children: comments,
        );
      },
    );
  }

  handleAddComment() {
    if (commentController.text.isNotEmpty) {
      handleSendNotification(
        content:
            '${currentUser!.username} berkomentar: ${commentController.text}',
      );

      commentsRef.doc(postId).collection('comments').add({
        'userId': currentUser!.id,
        'username': currentUser!.username,
        'comment': commentController.text,
        'timestamp': timestamp,
        'avatarUrl': currentUser!.photoUrl,
      });

      bool isNotPostOwner = userId != currentUser!.id;
      if (isNotPostOwner) {
        activityFeedRef.doc(userId).collection('feedItems').add({
          "type": "comment",
          "commentData": commentController.text,
          "timestamp": timestamp,
          "postId": postId,
          "userId": currentUser!.id,
          "username": currentUser!.username,
          "userImage": currentUser!.photoUrl,
          "imageUrl": imageUrl,
        });
      }

      commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: 'Komentar'),
      body: Column(
        children: [
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Tulis komentar...',
              ),
            ),
            trailing: Ink(
              decoration: ShapeDecoration(
                color: Theme.of(context).primaryColor,
                shape: CircleBorder(),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.send,
                  color: Colors.white,
                ),
                iconSize: 20,
                onPressed: handleAddComment,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
