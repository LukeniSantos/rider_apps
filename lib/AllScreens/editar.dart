import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rider_apps/AllScreens/loginscreen.dart';
import 'package:rider_apps/AllScreens/mainscreen.dart';
import 'package:rider_apps/AllWidgets/progressDialog.dart';
import 'package:rider_apps/main.dart';

import '../configMaps.dart';

class EditarScreen extends StatefulWidget {
  static const String idScreen = "register";

  @override
  _EditarScreenState createState() => _EditarScreenState();
}

class _EditarScreenState extends State<EditarScreen> {
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
                  "Coloque os seus dados novos",
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
                            labelText: "Nome",
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
                            labelText: "Contacto",
                            labelStyle: TextStyle(
                              fontSize: 15.0,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 10.0,
                            )),
                        style: TextStyle(fontSize: 14.0),
                      ),
                      //BOTÃO EDITAR
                      SizedBox(
                        height: 40.0,
                      ),
                      TextButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Confirmar"),
                            Icon(Icons.app_registration),
                          ],
                        ),
                        onPressed: () {
                          if (nameTextEditingController.text.length < 4) {
                            displayToastMesenger(
                                "O campo nome tem de ter mais 3 caracteres.",
                                context);
                          } else if (phoneTextEditingController.text.isEmpty ||
                              phoneTextEditingController.text.length != 9) {
                            displayToastMesenger(
                                "Verifique o numero que digitou.", context);
                          } else if (nipTextEditingController.text.isEmpty) {
                            displayToastMesenger(
                                "Verifique o seu nip.", context);
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
                      //botão ir para tela principal
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                              context, MainScreen.idScreen, (route) => false);
                        },
                        child: Text("Cancelar alterações"),
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
          message: "Atualizando, por favor espere...",
        );
      },
    );

    // Assume you have collected the updated user data.
    Map<String, dynamic> updatedUserData = {
      "name": nameTextEditingController.text.trim(),
      "phone": phoneTextEditingController.text.trim(),
      "nip": nipTextEditingController.text.trim(),
    };

    try {
      // Update the data in the database using the user's ID.
      await userRef.child(firebaseUser.uid).update(updatedUserData);

      displayToastMesenger("Dados atualizados com sucesso.", context);
      Navigator.pushNamedAndRemoveUntil(
          context, MainScreen.idScreen, (route) => false);
    } catch (error) {
      Navigator.pop(context); // Close the progress dialog.
      displayToastMesenger("Erro ao atualizar dados: $error", context);
    }
  }
}

displayToastMesenger(String mensagem, BuildContext context) {
  Fluttertoast.showToast(msg: mensagem);
}
