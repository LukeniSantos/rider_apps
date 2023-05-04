import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Users {
  var id;
  var email;
  var name;
  var phone;
  var nip;

  Users({this.id, this.email, this.name, this.phone, this.nip});

  Users.fromSnapshot(DataSnapshot dataSnapshot) {
    if (dataSnapshot.exists) {
      id = dataSnapshot.key;

      email = (dataSnapshot.value as Map)["email"];
      name = (dataSnapshot.value as Map)["name"];
      phone = (dataSnapshot.value as Map)["phone"];
      nip = (dataSnapshot.value as Map)["nip"];
    }
  }
}
