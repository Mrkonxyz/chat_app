import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _from = GlobalKey<FormState>();
  var _enterEmail = '';
  var _enterPassword = '';
  bool _isAuthenticating = false;
  File? _selectedImage = null;

  var _isLogin = true;

  void _submit() async {
    final isValid = _from.currentState!.validate();

    if (!isValid || !_isLogin && _selectedImage == null) {
      return;
    }

    _from.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        final userCredential = await _firebase.signInWithEmailAndPassword(
            email: _enterEmail, password: _enterPassword);
      } else {
        final userCredential = await _firebase.createUserWithEmailAndPassword(
            email: _enterEmail, password: _enterPassword);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredential.user!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);

        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': "to be done",
          "email": _enterEmail,
          "image_url": imageUrl
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        // to do sumthing
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Authentication failed.')));
      setState(() {
        _isAuthenticating = false;
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
              margin: const EdgeInsets.only(
                  top: 30, bottom: 20, left: 20, right: 20),
              width: 200,
              child: Image.asset('assets/images/chat.png'),
            ),
            Card(
              margin: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                  child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _from,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isLogin)
                        UserImagePicker(
                          onPickImage: (pickImage) {
                            _selectedImage = pickImage;
                          },
                        ),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Email Address'),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter valid email address';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.none,
                        onSaved: (newValue) {
                          _enterEmail = newValue!;
                        },
                      ),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().length < 6) {
                            return 'Password must be least 6 characters';
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          _enterPassword = newValue!;
                        },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (_isAuthenticating) const CircularProgressIndicator(),
                      if (!_isAuthenticating)
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer),
                          child: Text(_isLogin ? 'Login' : 'Signup'),
                        ),
                      if (!_isAuthenticating)
                        TextButton(
                          onPressed: (() {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          }),
                          child: Text(_isLogin
                              ? 'Create an account'
                              : 'I already have an account.'),
                        ),
                    ],
                  ),
                ),
              )),
            )
          ],
        )),
      ),
    );
  }
}
