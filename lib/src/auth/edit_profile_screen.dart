import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth_provider;

class EditProfileScreen extends StatefulWidget {
  static const String routeName = '/edit-profile';
  final String currentUsername;
  final String currentFullName;
  final String currentEmail;
  final String currentPhoneNumber;

  const EditProfileScreen({
    Key? key,
    required this.currentUsername,
    required this.currentFullName,
    required this.currentEmail,
    required this.currentPhoneNumber,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  final _formKey = GlobalKey<FormState>();
  String? _profilePicture;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.currentUsername;
    _fullNameController.text = widget.currentFullName;
    _emailController.text = widget.currentEmail;
    _phoneNumberController.text = widget.currentPhoneNumber;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _usernameController.text = userData['username'] ?? widget.currentUsername;
            _fullNameController.text = userData['fullName'] ?? widget.currentFullName;
            _emailController.text = userData['email'] ?? widget.currentEmail;
            _phoneNumberController.text = userData['phoneNumber'] ?? widget.currentPhoneNumber;
            _profilePicture = userData['profilePicture'];
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
        }, SetOptions(merge: true));

        // Update the user's display name in Firebase Auth
        await user.updateDisplayName(_fullNameController.text.trim());

        if (mounted) {
          final authProvider = Provider.of<app_auth_provider.AuthProvider>(context, listen: false);
          final nextScreen = await authProvider.getNextScreen();
          Navigator.of(context).pushReplacementNamed(nextScreen);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving profile: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Widget _buildProfileImage() {
    if (_profilePicture != null && _profilePicture!.isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(_profilePicture!),
      );
    } else if (_fullNameController.text.isNotEmpty) {
      final initials = _fullNameController.text
          .split(' ')
          .take(2)
          .map((name) => name[0])
          .join('')
          .toUpperCase();
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.blue,
        child: Text(
          initials,
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      );
    } else {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, size: 50, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Fill your Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading && _usernameController.text.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      Center(
                        child: Stack(
                          children: [
                            _buildProfileImage(),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF246BFD),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildTextField('Username', _usernameController, isEditable: false),
                      const SizedBox(height: 16),
                      _buildTextField('Full Name', _fullNameController, validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Full name cannot be empty';
                        }
                        return null;
                      }),
                      const SizedBox(height: 16),
                      _buildTextField('Email Address', _emailController, isEmail: true, isEditable: false),
                      const SizedBox(height: 16),
                      _buildTextField('Phone Number', _phoneNumberController, isPhone: true),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF246BFD),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
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

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isEmail = false, bool isPhone = false, bool isEditable = true, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isEmail
              ? TextInputType.emailAddress
              : (isPhone ? TextInputType.phone : TextInputType.text),
          enabled: isEditable,
          validator: validator,
          decoration: InputDecoration(
            hintText: isEmail
                ? 'example@youremail.com'
                : (isPhone ? '+62-8421-4512-2531' : ''),
            hintStyle: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF246BFD)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            filled: !isEditable,
            fillColor: isEditable ? null : Colors.grey[200],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}