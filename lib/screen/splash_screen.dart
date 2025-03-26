// screen/splash_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart'; // Import SignUpScreen

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade200, Colors.teal.shade400],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/baramedlogo.PNG', // Siguraduhin na tama ang file path
              height: 300,
            ),
            SizedBox(height: 10),
            Text(
              '"Serbisyong Tapat, Kalusugang Sapat!"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        color:
                            Colors.white, // FIXED: Inalis ang misplaced `color`
                      ),
                    ),
                  ),
                  SizedBox(),
                  SizedBox(height: 10),
                  Text('or', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(color: Colors.teal),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    child: Text(
                      'Create an account',
                      style: TextStyle(fontSize: 18, color: Colors.teal),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Login with other account',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.g_translate, color: Colors.red),
                        onPressed: () {
                          print("Google login pressed");
                        },
                      ),
                      SizedBox(width: 20),
                      IconButton(
                        icon: Icon(Icons.facebook, color: Colors.blue),
                        onPressed: () {
                          print("Facebook login pressed");
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
