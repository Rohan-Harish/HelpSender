import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:help_sender/pages/dash.dart';
import 'package:help_sender/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthControl {
  //This function handles where the app lands
  handleAuth(){
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, snapshot){
        if(snapshot.hasData){
          return DashBoardView();
        }
        else{
          return LoginView();
        }
      },
    );
  }

  signOut(){
    FirebaseAuth.instance.signOut();
  }

  signIn(AuthCredential authCredential) async{
    FirebaseAuth.instance.signInWithCredential(authCredential);
  }

  signInWithSMS(smsCode, verID){
    // ignore: deprecated_member_use
    AuthCredential authCredential = PhoneAuthProvider.getCredential(verificationId: verID, smsCode: smsCode);
    signIn(authCredential);
  }

  String getUser(){
    return FirebaseAuth.instance.currentUser.uid.toString();
  }
}

class FireData{
  String _uid = FirebaseAuth.instance.currentUser.uid;
  FirebaseFirestore firestore;
  int karma;

  QuerySnapshot snap;

  Future<Map> getUserInfo() async{
    Map<String, dynamic> vals = {};
    final prefs = await SharedPreferences.getInstance();
    firestore = FirebaseFirestore.instance;

    DocumentSnapshot snap = await firestore.collection("users").doc(_uid).collection("info").doc("creds").get();

    if(snap.exists){
      vals = snap.data();
    }
    else{
      vals['fname'] = prefs.getString("fname");
      vals['lname'] = prefs.getString("lname");
      vals['karma-user'] = 0;
      vals['rating-user'] = 0;
      firestore.collection("users").doc(_uid).collection("info").doc("creds").set(vals);
    }
    return vals;
  }

  Future<Map> getListings() async{
    Map<String, dynamic> vals = {};
    firestore = FirebaseFirestore.instance;
    snap = await firestore.collection("listings").get();
    if(snap.size > 0){
      Iterable<DocumentSnapshot> snaps = snap.docs.getRange(0, snap.docs.length);
      for(DocumentSnapshot s in snaps){
        vals[s.id.toString()] = s.data();
      }
      print(vals);
      return vals;
    }
    print(vals);
    return vals;
  }

  setInvite(String id) async{
    firestore = FirebaseFirestore.instance;
    firestore.collection("listings").doc(id).update({"pitches":_uid});
  }

  Future<Map> getInvitations() async{
    firestore = FirebaseFirestore.instance;
    DocumentSnapshot snapu = await firestore.collection("listings").doc(_uid).get();
    String idfor = snapu.data()['pitches'];
    DocumentSnapshot snap = await firestore.collection("users").doc(idfor).collection("info").doc("creds").get();
    return {
      "name" : snap.data()["fname"] + " " + snap.data()["lname"],
      "rating" : snap.data()["rating-user"]
    };
  }

  removeInvite(){
    firestore = FirebaseFirestore.instance;
    firestore.collection("listings").doc(_uid).update({"pitches":[]});
  }

  Future<int> getKarma() async{
    firestore = FirebaseFirestore.instance;
    DocumentSnapshot snap = await firestore.collection("users").doc(_uid).collection("info").doc("creds").get();
    print(snap.data()["karma-user"]);
    return snap.data()["karma-user"];
  }

  void setData(String name, String description, int karma) async{
    firestore = FirebaseFirestore.instance;
    DocumentSnapshot snap = await firestore.collection("users").doc(_uid).collection("info").doc("creds").get();
    int rating = snap.data()['rating-user'];
    firestore.collection("listings").doc(_uid).set(<String,dynamic>{
      'description': description,
      'name': name,
      'karma': karma,
      'rate': rating,
      'taken':false,
      'pitches':[]
    });
  }

}