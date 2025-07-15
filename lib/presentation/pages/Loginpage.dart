import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Waychaser/OpenStreetMapScreen.dart';
import 'package:path_provider/path_provider.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController _usernamecontroller = TextEditingController();
  final TextEditingController _passwordcontroller = TextEditingController();

  void dispose() {
  _usernamecontroller.dispose();
  _passwordcontroller.dispose();
  super.dispose();
}
Future<void> _saveAuth(String userid) async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/bg_auth.json');
    await f.writeAsString(jsonEncode({'userid': userid}), mode: FileMode.write);
  }
Future<bool> loginwithUserandPass(String user,String pass) async{
  print(user);
  print(pass);
  try{
    final response = await http.post(
    Uri.parse("https://9367d2d45914.ngrok-free.app/api/v2/login"),
    headers:{"Content-Type":"application/json"},
    body:jsonEncode({'userID':user,'password':pass})
  );
  if(response.statusCode==500){
    print(response.body);
  }
  if (response.statusCode == 200) {
      //final data = jsonDecode(response.body);
      print("yes");
      await _saveAuth(user);
      return true;
    } else {
      print(response.statusCode);
      return false;
    }
  } catch(e) {
    print("Login error: $e");
    return false;
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Login(),
              const SizedBox(height: 40),
              _UsernameField(_usernamecontroller),
              const SizedBox(height: 20),
              _PasswordField(_passwordcontroller),
              const SizedBox(height: 30),
              _LoginButton(_usernamecontroller,_passwordcontroller,),
            ],
          ),
        ),
      ),
    );
  }

  Widget _Login() {
    return const Text(
      'Login',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _UsernameField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Username',
        prefixIcon: Icon(Icons.person),
        filled: true,
        fillColor: Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _PasswordField(TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock),
        filled: true,
        fillColor: Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _LoginButton(TextEditingController user,TextEditingController pass) {
    return ElevatedButton(
      onPressed: () async{
        final username = user.text.trim();
        final password = pass.text;
        // TODO: Handle login logic
       if(await loginwithUserandPass(username,password)==true){
        Navigator.push(
  context,
  MaterialPageRoute(
    builder: (BuildContext context) => const OpenStreetMapScreen(),
  ),
        );
       }
       else{
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed. Check credentials.')),
          );
       }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text(
        'Login',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
