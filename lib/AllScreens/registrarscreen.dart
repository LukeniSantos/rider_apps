import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rider_apps/AllScreens/loginscreen.dart';
import 'package:rider_apps/AllScreens/mainscreen.dart';
import 'package:rider_apps/AllWidgets/progressDialog.dart';
import 'package:rider_apps/main.dart';

class RegistrarScreen extends StatefulWidget {
  static const String idScreen = "register";

  @override
  _RegistrarScreenState createState() => _RegistrarScreenState();
}

class _RegistrarScreenState extends State<RegistrarScreen> {
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController nipTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
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
                  "Register as a Rider",
                  style: TextStyle(fontSize: 24.0, fontFamily: "Brand Bold"),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      //Nome
                      SizedBox(
                        height: 1.0,
                      ),
                      TextField(
                        controller: nameTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                            prefixIcon: Icon(Icons.people_alt_rounded),
                            labelText: "Name",
                            labelStyle: TextStyle(
                              fontSize: 15.0,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 10.0,
                            )),
                        style: TextStyle(fontSize: 14.0),
                      ),
                      //email
                      SizedBox(
                        height: 1.0,
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
                      //NIP
                      SizedBox(
                        height: 1.0,
                      ),
                      TextField(
                        controller: nipTextEditingController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            prefixIcon: Icon(Icons.numbers),
                            labelText: "NIP",
                            labelStyle: TextStyle(
                              fontSize: 15.0,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 10.0,
                            )),
                        style: TextStyle(fontSize: 14.0),
                      ),
                      //TELEFONE
                      SizedBox(
                        height: 1.0,
                      ),
                      TextField(
                        controller: phoneTextEditingController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                            prefixIcon: Icon(Icons.phone),
                            labelText: "Phone",
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
                        height: 1.0,
                      ),
                      TextField(
                        controller: passwordTextEditingController,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.password),
                          labelText: "Password",
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
                      //BOTÃO REGISTRAR
                      SizedBox(
                        height: 40.0,
                      ),
                      TextButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Create Account "),
                            Icon(Icons.app_registration),
                          ],
                        ),
                        onPressed: () {
                          if (nameTextEditingController.text.length < 4) {
                            displayToastMesenger(
                                "O campo nome tem de ter mais 3 caracteres",
                                context);
                          } else if (!emailTextEditingController.text
                              .contains("@")) {
                            displayToastMesenger(
                                "O email não é valido", context);
                          } else if (phoneTextEditingController.text.isEmpty ||
                              phoneTextEditingController.text.length != 9) {
                            displayToastMesenger(
                                "Verifique o numero que digitou", context);
                          } else if (passwordTextEditingController.text.length <
                              6) {
                            displayToastMesenger(
                                "verifique a sua passowd", context);
                          } else {
                            registerNewUser(context);
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
                      ),
                      //botão ir para a tela de login
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                              context, LoginScreen.idScreen, (route) => false);
                        },
                        child: Text("Você tem conta?_ Login por aqui."),
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
  void registerNewUser(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(
            message: "registrando, por favor espere...",
          );
        });

    final firebaseUser = (await _firebaseAuth
            .createUserWithEmailAndPassword(
                email: emailTextEditingController.text,
                password: passwordTextEditingController.text)
            .catchError((errMsg) {
      Navigator.pop(context);
      displayToastMesenger("Erro" + errMsg.toString(), context);
    }))
        .user;
    if (firebaseUser != null) {
      //Salar tudo na bd
      Map userDataMap = {
        "name": nameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "phone": phoneTextEditingController.text.trim(),
        "nip": nipTextEditingController.text.trim(),
      };
      userRef.child(firebaseUser.uid).set(userDataMap);
      displayToastMesenger("Seja bem vindo, sua conta foi criada.", context);
      Navigator.pushNamedAndRemoveUntil(
          context, MainScreen.idScreen, (route) => false);
    } else {
      Navigator.pop(context);
      //mensagem de erro
      displayToastMesenger("Novo usuario não foi criado.", context);
    }
  }
}

displayToastMesenger(String mensagem, BuildContext context) {
  Fluttertoast.showToast(msg: mensagem);
}
