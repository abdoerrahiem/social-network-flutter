import 'package:flutter/material.dart';
import 'package:social_network/screens/post_screen.dart';
import 'package:social_network/widgets/custom_image.dart';
import 'package:social_network/widgets/post.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          userId: post.userId,
          postId: post.postId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: cachedNetworkImage(post.imageUrl),
    );
  }
}
