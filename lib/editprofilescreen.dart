import 'dart:io';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/utils/utils/file picking/image_picking.dart';
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
  String userEmail = '';
  ImageProvider? _imageProvider;
  String? _profilePicUrl;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = userName;
    _getUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
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
    final XFile? image = await pickSingleImage();
    if (image != null) {
      await _uploadProfilePicture(image);
    }
  }

  Future<void> _uploadProfilePicture(XFile image) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUploadingImage = true);
    try {
      File imageFile = File(image.path);
      final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user.uid}');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'profilePicture': downloadUrl},
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() {
        _profilePicUrl = downloadUrl;
        _imageProvider = NetworkImage(downloadUrl);
      });
    } catch (e) {
      VoidLogger.error('Failed to upload profile picture', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload profile picture. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save your profile.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'name': _nameController.text,
          'email': user.email,
          if (_profilePicUrl != null) 'profilePicture': _profilePicUrl,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() => userName = _nameController.text);
      Navigator.pop(context);
    } catch (e) {
      VoidLogger.error('Failed to save profile', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your profile. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                    onTap: _isUploadingImage ? null : _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60.r,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 55.r,
                            backgroundImage: _imageProvider ?? AssetImage(VoidImages.profile),
                          ),
                        ),
                        if (_isUploadingImage)
                          CircleAvatar(
                            radius: 60.r,
                            backgroundColor: Colors.black.withOpacity(0.4),
                            child: const CircularProgressIndicator(color: Colors.white),
                          ),
                      ],
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
                  controller: _emailController..text = userEmail,
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
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200.w, 50.h),
                      backgroundColor: Colors.blue,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save', style: TextStyle(color: Colors.white)),
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
