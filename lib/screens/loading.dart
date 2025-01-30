import 'dart:async';

import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    Future.delayed(const Duration(seconds: 4, milliseconds: 690), () {
      context.go("/login");
    });
    return Scaffold(
      backgroundColor: const Color(0xff212544),
      body: Column(
        children: [
          Container(
            height: height * 0.22,
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage("assets/images/ust.png"),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40,vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Yükleniyor \nLütfen Bekleyin.", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),)
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, 110),
                child: InkWell(
                  child: SizedBox(
                    width: 200,
                    child: Opacity(
                      opacity: 0.9,
                      child: DotLottieLoader.fromAsset(
                        "assets/motions/loadingAnim.lottie",
                        frameBuilder: (BuildContext ctx, DotLottie? dotlottie) {
                          if (dotlottie != null) {
                            return Lottie.memory(
                              dotlottie.animations.values.single,
                            );
                          } else {
                            return Container();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: height * 0.2, // Alt görselin yüksekliği
              decoration: const BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage("assets/images/alt.png"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
