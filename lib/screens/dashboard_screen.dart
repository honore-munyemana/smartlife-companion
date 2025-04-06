import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin_screen.dart';  

class DashboardScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final VoidCallback toggleTheme;

  DashboardScreen({required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignInScreen(toggleTheme: toggleTheme)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Welcome to the Dashboard!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "User Information:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            Text("Email: ${user?.email ?? 'Not logged in'}"),
            Text("UID: ${user?.uid ?? 'N/A'}"),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Placeholder action triggered')),
                );
              },
              child: Text('Trigger Action'),
            ),
            SizedBox(height: 20),
            Text(
              "Additional Features:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 5,
              child: ListTile(
                title: Text("Feature 1"),
                subtitle: Text("Click to learn more"),
                onTap: () {},
              ),
            ),
            Card(
              elevation: 5,
              child: ListTile(
                title: Text("Feature 2"),
                subtitle: Text("Click to learn more"),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
