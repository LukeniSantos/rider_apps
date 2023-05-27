import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rider_apps/AllScreens/mainscreen.dart';
import 'package:rider_apps/AllScreens/registrarscreen.dart';
import 'package:rider_apps/AllWidgets/progressDialog.dart';
import 'package:rider_apps/main.dart';

class LoginScreen extends StatefulWidget {
  static const String idScreen = "login";

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(
                  image: AssetImage("images/logo.png"),
                  width: 390,
                  height: 250.0,
                  alignment: Alignment.center,
                ),
                SizedBox(
                  height: 1.0,
                ),
                Text(
                  "Login as a Rider",
                  style: TextStyle(fontSize: 24.0, fontFamily: "Brand Bold"),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      //MAIL
                      SizedBox(
                        height: 10.0,
                      ),
                      TextField(
                        controller: emailTextEditingController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email),
                            labelText: "Email",
                            labelStyle: TextStyle(
                              fontSize: 15.0,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 10.0,
                            )),
                        style: TextStyle(fontSize: 14.0),
                      ),
                      //SENHA
                      SizedBox(
                        height: 10.0,
                      ),
                      TextField(
                        controller: passwordTextEditingController,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.password),
                          labelText: "Passord",
                          labelStyle: TextStyle(
                            fontSize: 15.0,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.0,
                          ),
                        ),
                        style: TextStyle(fontSize: 14.0),
                      ),
                      //BOTÃO LOGIN CONTA
                      SizedBox(
                        height: 40.0,
                      ),
                      TextButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Login "),
                            Icon(Icons.login_rounded),
                          ],
                        ),
                        onPressed: () {
                          if (!emailTextEditingController.text.contains("@")) {
                            displayToastMesenger(
                                "O email não é valido", context);
                          } else if (passwordTextEditingController
                              .text.isEmpty) {
                            displayToastMesenger(
                                "passowd é obrigatoria", context);
                          } else {
                            loginAndAuthenticateUser(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(20.0),
                          fixedSize: Size(400, 60),
                          textStyle: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          primary: Colors.amber,
                          onPrimary: Color.fromARGB(255, 0, 0, 0),
                          elevation: 10,
                          shadowColor: Colors.black,
                          shape: StadiumBorder(),
                        ),
                      ), //BOTÂO NAO TEM CONTA
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context,
                              RegistrarScreen.idScreen, (route) => false);
                        },
                        child: Text("Não tem conta? Registra-se aqui."),
                        style: TextButton.styleFrom(
                          primary: Colors.black,
                          shape: StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void loginAndAuthenticateUser(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(
            message: "Autenticando, por favor espere...",
          );
        });

    final firebaseUser = (await _firebaseAuth
            .signInWithEmailAndPassword(
                email: emailTextEditingController.text,
                password: passwordTextEditingController.text)
            .catchError((errMsg) {
      displayToastMesenger("Erro: " + errMsg.toString(), context);
    }))
        .user;
    if (firebaseUser != null) {
      Navigator.pop(context);
      DataSnapshot snap;
      userRef.child(firebaseUser.uid).once().then((snap) {
        if (snap.snapshot.exists) {
          Navigator.pushNamedAndRemoveUntil(
              context, MainScreen.idScreen, (route) => false);
          displayToastMesenger("Seja bem vindo", context);
        } else {
          Navigator.pop(context);
          _firebaseAuth.signOut();
          displayToastMesenger("Usuario inesisente, crie uma conta.", context);
        }
      });
    } else {
      Navigator.pop(context);
      displayToastMesenger("A senha ou email está errado.", context);
    }
  }
}
