import 'dart:io'; // Import this for working with File
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String userName = 'New User';
  String userEmail = 'abdullah@example.com';
  ImageProvider? _imageProvider;
  String? _profilePicUrl;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = userName;
    _getUserProfile();
  }

  Future<void> _getUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Fetch user's profile data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'];
          userEmail = userDoc['email'];
          _profilePicUrl = userDoc['profilePicture'];
          // Check if the URL is valid and not empty
          _imageProvider = (_profilePicUrl != null && _profilePicUrl!.isNotEmpty)
              ? NetworkImage(_profilePicUrl!)
              : AssetImage(VoidImages.profile);
          _nameController.text = userName;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Upload the new profile picture to Firebase Storage
      await _uploadProfilePicture(image);
    }
  }

  Future<void> _uploadProfilePicture(XFile image) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Convert the image path (String) into a File
    File imageFile = File(image.path);

    // Create a reference to Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user.uid}');

    // Upload the image
    UploadTask uploadTask = storageRef.putFile(imageFile);  // Pass the File object here
    TaskSnapshot snapshot = await uploadTask;

    // Get the download URL after uploading
    String downloadUrl = await snapshot.ref.getDownloadURL();

    // Check if the download URL is valid
    if (downloadUrl.isNotEmpty) {
      // Update Firestore with the new profile picture URL
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profilePicture': downloadUrl,
      });

      setState(() {
        _profilePicUrl = downloadUrl;
        _imageProvider = NetworkImage(_profilePicUrl!); // Update the profile picture
      });
    } else {
      // Handle case where the URL is not valid
      print("Failed to get a valid URL");
    }
  }

  Future<void> _saveProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch the user's document to check if it exists
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // If the document exists, update it
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text,
        });
      } else {
        // If the document doesn't exist, create it
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text,
          'email': user.email,
          'profilePicture': _profilePicUrl ?? '',  // Set profile picture URL if available
        });
      }

      setState(() {
        userName = _nameController.text; // Update local variable
      });

      Navigator.pop(context); // Go back to previous screen
    } else {
      // Handle case where user is not authenticated
      print("User not authenticated");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(VoidImages.otherscreen_background), // Update with your image
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w,vertical: 50.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60.r,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 55.r,
                        backgroundImage: _imageProvider ?? AssetImage(VoidImages.profile),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 60.h),

                // Name TextField
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: TextEditingController(text: userEmail),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                  readOnly: true,
                ),
                SizedBox(height: 30.h),

                // Save Button
                Center(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text('Save',style: TextStyle(color:Colors.white),),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200.w, 50.h),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
