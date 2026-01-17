import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../utils/app_colors.dart';

class AccountSettingsScreen extends StatefulWidget {
  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _profileImageController = TextEditingController();
  final DbHelper _dbHelper = DbHelper();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _profileImageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      List<UserModel> users = await _dbHelper.getAllUsers();
      if (users.isNotEmpty) {
        setState(() {
          _currentUser = users.first;
          _nameController.text = _currentUser!.name;
          _emailController.text = _currentUser!.email;
          _profileImageController.text = _currentUser!.profileImage;
          _isLoading = false;
        });
      } else {
        // Create default user if none exists
        UserModel defaultUser = UserModel(
          name: 'Enjelin Morgeana',
          email: 'enjelin@mail.com',
          profileImage: '',
          password: 'password123',
        );
        int id = await _dbHelper.insertUser(defaultUser);
        defaultUser.id = id;
        setState(() {
          _currentUser = defaultUser;
          _nameController.text = _currentUser!.name;
          _emailController.text = _currentUser!.email;
          _profileImageController.text = _currentUser!.profileImage;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_currentUser != null) {
        _currentUser!.name = _nameController.text.trim();
        _currentUser!.email = _emailController.text.trim();
        _currentUser!.profileImage = _profileImageController.text.trim();
        
        await _dbHelper.updateUser(_currentUser!);
        
        // Save user name to shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _currentUser!.name);
        await prefs.setString('user_email', _currentUser!.email);
        await prefs.setString('user_profile_image', _currentUser!.profileImage);

        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account settings saved successfully!')),
        );
        
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Account Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Picture Section
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primary,
                            backgroundImage: _profileImageController.text.isNotEmpty
                                ? NetworkImage(_profileImageController.text)
                                : null,
                            child: _profileImageController.text.isEmpty
                                ? const Icon(Icons.person, size: 60, color: Colors.black)
                                : null,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Profile Picture URL',
                            style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Name Field
                    Text(
                      'Name',
                      style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Enter your name',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Email Field
                    Text(
                      'Email',
                      style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Profile Image URL Field
                    Text(
                      'Profile Picture URL',
                      style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _profileImageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Enter image URL',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}



