import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'calculator_screen.dart';
import 'signin_screen.dart';
import 'dashboard_screen.dart';
import 'product_list_screen.dart';
import 'contacts_screen.dart';
import 'myhome_map_screen.dart';
import 'light_monitor_screen.dart'; // <-- Light Monitor import
//import 'camera_light_monitor_screen.dart';
class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const HomeScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CalculatorScreen(),
      DashboardScreen(toggleTheme: widget.toggleTheme),
      ProductListScreen(),
      MyHomeMapScreen(),
    ];
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera),
                title: Text('Take a Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.image),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void navigateWithFade(BuildContext context, int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
          GestureDetector(
            onTap: _showImagePicker,
            child: CircleAvatar(
              backgroundImage: _image != null
                  ? FileImage(_image!)
                  : AssetImage('assets/profile_avatar.jpg') as ImageProvider,
              radius: 18,
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? "Guest"),
              accountEmail: Text(user?.email ?? "guest@example.com"),
              currentAccountPicture: GestureDetector(
                onTap: _showImagePicker,
                child: CircleAvatar(
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : AssetImage('assets/profile_avatar.jpg') as ImageProvider,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.calculate),
              title: Text("Calculator"),
              onTap: () {
                navigateWithFade(context, 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text("Dashboard"),
              onTap: () {
                navigateWithFade(context, 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text("Products"),
              onTap: () {
                navigateWithFade(context, 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text("My Home"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, 'myhome_map');
              },
            ),
            ListTile(
              leading: Icon(Icons.contacts),
              title: Text("Contacts"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactsScreen()),
                );
              },
            ),
             ListTile(
               leading: Icon(Icons.light_mode),
               title: Text("Light Monitor"),
               onTap: () {
                 Navigator.pop(context);
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => LightMonitorScreen()),
                 );
               },
             ),
//             ListTile(
//   leading: Icon(Icons.light_mode),
//   title: Text("Light Monitor (Camera)"),
//   onTap: () {
//     Navigator.pop(context);
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => CameraLightMonitorScreen()),
//     );
//   },
// ),

            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: () async {
                bool confirmLogout = await showLogoutDialog(context);
                if (confirmLogout) {
                  await _auth.signOut();
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 500),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          SignInScreen(toggleTheme: widget.toggleTheme),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        elevation: 10,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Calculator'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'My Home'),
        ],
      ),
    );
  }

  Future<bool> showLogoutDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Logout")),
        ],
      ),
    );
  }
}
