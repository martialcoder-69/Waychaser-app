import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Waychaser/presentation/pages/Loginpage.dart';
import 'package:Waychaser/presentation/pages/asset_vector.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState(){
    super.initState();
    _redirect();
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Center(
        child: SvgPicture.asset(
          AssetVector.logo
        ),
      )
    );
  }
  Future<void> _redirect() async{
    await Future.delayed(const Duration(seconds:2));
    Navigator.pushReplacement(context, 
    MaterialPageRoute(builder:
    (BuildContext context)=>const Loginpage()));
  }
}