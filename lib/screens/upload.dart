import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_network/models/user.dart';
import 'package:social_network/screens/home.dart';
import 'package:social_network/widgets/progress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart';
import 'package:uuid/uuid.dart';

final _picker = ImagePicker();

class Upload extends StatefulWidget {
  final User currentUser;

  Upload(this.currentUser);

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  File? image;
  bool isUploading = false;
  String postId = Uuid().v4();

  handleTakePhoto() async {
    Navigator.pop(context);
    PickedFile? image = await _picker.getImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    File selectedImage = File(image!.path);

    setState(() {
      this.image = selectedImage;
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    PickedFile? image = await _picker.getImage(
      source: ImageSource.gallery,
    );
    File selectedImage = File(image!.path);

    setState(() {
      this.image = selectedImage;
    });
  }

  handleImage(context) {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Buat Post'),
          children: [
            SimpleDialogOption(
              child: Text('Photo dengan Kamera'),
              onPressed: handleTakePhoto,
            ),
            SimpleDialogOption(
              child: Text('Gambar dari Galeri'),
              onPressed: handleChooseFromGallery,
            ),
            SimpleDialogOption(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/upload.svg',
            height: 260,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: () => handleImage(context),
              style: ElevatedButton.styleFrom(
                primary: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Upload Gambar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      image = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    final imageFile = decodeImage(File(image!.path).readAsBytesSync());
    final compressedImage = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(encodeJpg(imageFile!, quality: 85));

    setState(() {
      image = compressedImage;
    });
  }

  Future<String> uploadImage(img) async {
    UploadTask uploadTask = storageRef.child('post_$postId.jpg').putFile(img);

    TaskSnapshot storageSnapshot = await uploadTask;

    String downloadUrl = await storageSnapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  createPostInFirestore({String? imageUrl, String? location, String? caption}) {
    postsRef
        .doc(widget.currentUser.id)
        .collection('userPosts')
        .doc(postId)
        .set({
      'postId': postId,
      'userId': widget.currentUser.id,
      'username': widget.currentUser.username,
      'imageUrl': imageUrl,
      'caption': caption,
      'location': location,
      'timestamp': timestamp,
      'likes': {},
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });

    await compressImage();

    String imageUrl = await uploadImage(image);

    await createPostInFirestore(
      imageUrl: imageUrl,
      location: locationController.text,
      caption: captionController.text,
    );

    QuerySnapshot querySnapshot = await followersRef
        .doc(widget.currentUser.id)
        .collection('userFollowers')
        .get();

    querySnapshot.docs.forEach((doc) {
      timelineRef.doc(doc.id).collection('timelinePosts').doc(postId).set({
        'postId': postId,
        'userId': widget.currentUser.id,
        'username': widget.currentUser.username,
        'imageUrl': imageUrl,
        'caption': captionController.text,
        'location': locationController.text,
        'timestamp': timestamp,
        'likes': {},
      });
    });

    captionController.clear();
    locationController.clear();
    setState(() {
      image = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: clearImage,
        ),
        title: Text(
          'Caption Post',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            child: Text(
              'Post',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            onPressed: () => isUploading ? null : handleSubmit(),
          ),
        ],
      ),
      body: ListView(
        children: [
          isUploading ? linearProgress() : Text(''),
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(
                        File(image!.path),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 10)),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                widget.currentUser.photoUrl,
              ),
            ),
            title: Container(
              width: 250,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Tulis caption...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35,
            ),
            title: Container(
              width: 250,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'Dimana photo ini diambil?',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200,
            height: 100,
            alignment: Alignment.center,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: getUserLocation,
                icon: Icon(Icons.my_location),
                label: Text('Gunakan lokasi sekarang'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    Placemark placemark = placemarks[0];
    String address = '${placemark.locality}, ${placemark.country}';
    locationController.text = address;
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return image == null ? buildSplashScreen() : buildUploadForm();
  }
}
