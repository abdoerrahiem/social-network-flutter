import 'dart:async';

import 'package:flutter/material.dart';
import 'package:social_network/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  String? username;

  handleOnTap() {
    final form = _formKey.currentState;

    if (form!.validate()) {
      form.save();

      final snackbar = SnackBar(
        content: Text('Selamat datang $username!'),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackbar);

      Timer(Duration(seconds: 2), () {
        Navigator.pop(context, username);
      });
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      appBar: header(context, title: 'Atur profilmu', removeBackButton: true),
      body: ListView(
        children: [
          Container(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 25),
                  child: Center(
                    child: Text(
                      'Tambahkan username',
                      style: TextStyle(fontSize: 25),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Container(
                    child: Form(
                      key: _formKey,
                      child: TextFormField(
                        validator: (value) {
                          if (value!.trim().length < 3 || value.isEmpty) {
                            return 'Username terlalu pendek';
                          } else if (value.trim().length > 12) {
                            return 'Username terlalu panjang';
                          } else {
                            return null;
                          }
                        },
                        onSaved: (value) => username = value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Username',
                          labelStyle: TextStyle(fontSize: 15),
                          hintText: 'Paling sedikit 3 karakter',
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: handleOnTap,
                  child: Container(
                    height: 50,
                    width: 350,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
