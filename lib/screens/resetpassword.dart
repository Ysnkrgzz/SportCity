import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth.dart';

class ResetScreen extends StatefulWidget {
  const ResetScreen({super.key});

  @override
  _ResetScreenState createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen> {
  bool isAvailable = true;
  String? errorMessage;
  final TextEditingController usernameController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    try {
      await Auth().resetpassword(email: usernameController.text);
      setState(() {
        errorMessage = "Şifre sıfırlama e-postası gönderildi.";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xff212544),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Üst görsel
                Container(
                  height: height * 0.25,
                  width: width,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage("assets/images/ust.png"),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Lütfen şifresini\nsıfırlamak istediğiniz\nmail adresini girin.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.4, // Satır aralığı
                        ),
                      ),
                      CustomSizedBox(),
                      // E-posta giriş alanı
                      TextField(
                        controller: usernameController,
                        decoration: CustomInputDecoration("Mail Adresi"),
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      CustomSizedBox(),
                      // Hata veya bilgilendirme mesajı
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.green, fontSize: 14),
                          ),
                        ),
                      CustomSizedBox(),
                      // Şifreyi Sıfırla butonu
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              if (isAvailable) {
                                resetPassword();
                              }
                            },
                            child: const Text(
                              "Şifreyi Sıfırla",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      CustomSizedBox(),
                      // Durum değiştirici (aktif/pasif)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isAvailable = !isAvailable;
                          });
                        },
                        child: Center(child: Text("", style: TextStyle(fontSize: 0),),),
                      ),
                      CustomSizedBox(),
                    ],
                  ),
                )
              ],
            ),
          ),
          // Geri dönüş butonu
          Positioned(
            top: 45,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => context.go('/login'),
            ),
          ),
        ],
      ),
    );
  }
}

Widget CustomSizedBox() => const SizedBox(height: 20);

InputDecoration CustomInputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Colors.grey),
    filled: true,
    fillColor: Colors.white10,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.blueAccent),
    ),
  );
}
