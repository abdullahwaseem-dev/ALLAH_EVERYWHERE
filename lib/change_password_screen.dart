import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _retypeNewPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isRetypeNewPasswordVisible = false;

  Future<void> _changePassword() async {
    User? user = _auth.currentUser;

    if (user == null) {
      _showSnackbar('No user is logged in');
      return;
    }

    String currentPassword = _currentPasswordController.text;
    String newPassword = _newPasswordController.text;
    String retypeNewPassword = _retypeNewPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || retypeNewPassword.isEmpty) {
      _showSnackbar('All fields are required');
      return;
    }

    if (newPassword != retypeNewPassword) {
      _showSnackbar('New password and retype password do not match');
      return;
    }

    try {
      // Reauthenticate the user with the current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // If reauthentication is successful, update the password
      await user.updatePassword(newPassword);

      _showSnackbar('Password updated successfully');
      Navigator.pop(context); // Go back to the previous screen
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showSnackbar('Your current password is incorrect');
      } else {
        _showSnackbar('Failed to change password: ${e.message}');
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Change Password',
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
            image: AssetImage(VoidImages.otherscreen_background),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 170.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  isVisible: _isCurrentPasswordVisible,
                  toggleVisibility: () {
                    setState(() {
                      _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                    });
                  },
                ),
                SizedBox(height: 20.h),

                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  isVisible: _isNewPasswordVisible,
                  toggleVisibility: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                ),
                SizedBox(height: 20.h),

                // Retype New Password Field with Toggle Button
                _buildPasswordField(
                  controller: _retypeNewPasswordController,
                  label: 'Retype New Password',
                  isVisible: _isRetypeNewPasswordVisible,
                  toggleVisibility: () {
                    setState(() {
                      _isRetypeNewPasswordVisible = !_isRetypeNewPasswordVisible;
                    });
                  },
                ),
                SizedBox(height: 30.h),

                // Save Button
                Center(
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    child: Text('Save', style: TextStyle(color: Colors.white)),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}
