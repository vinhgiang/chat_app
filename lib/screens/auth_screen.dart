import 'dart:io';

import 'package:chat_app/widgets/vg_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  bool _isLoginMode = true;
  String _email = '';
  String _password = '';
  String _username = '';
  File? _pickedImg;
  bool _isLoading = false;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || !_isLoginMode && _pickedImg == null) {
      return;
    }

    _form.currentState!.save();

    try {
      setState(() {
        _isLoading = true;
      });
      if (_isLoginMode) {
        await _firebase.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
      } else {
        final userCredential = await _firebase.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('${userCredential.user!.uid}.jpg');

        await storageRef.putFile(_pickedImg!);
        final imgUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _username,
          'email': _email,
          'image_url': imgUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      String errorMsg = error.message ?? 'Authentication failed';

      if (error.code == 'INVALID_LOGIN_CREDENTIALS') {
        errorMsg =
            'Your email or password is incorrect.\nPlease double-check and try again.';
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isLoginMode)
                          VgImagePicker(
                            onImagePick: (pickedImg) {
                              _pickedImg = pickedImg;
                            },
                          ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty ||
                                !value.contains('@')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _email = value!;
                          },
                        ),
                        if (!_isLoginMode)
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                            enableSuggestions: false,
                            validator: (value) {
                              if (value == null || value.trim().length < 4) {
                                return 'Username should be at least 4 characters long.';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _username = newValue!;
                            },
                          ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().length < 6) {
                              return 'Password should be at least 6 characters long.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _password = value!;
                          },
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        if (_isLoading) const CircularProgressIndicator(),
                        if (!_isLoading)
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                            child: Text(_isLoginMode ? 'Login' : 'Sign up'),
                          ),
                        if (!_isLoading)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                              });
                            },
                            child: Text(_isLoginMode
                                ? 'Create an account'
                                : 'Already have an account?'),
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
