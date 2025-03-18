import 'package:flutter/material.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomDrawer extends StatelessWidget {
  final String userRole;

  const CustomDrawer({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header with User Info
          UserAccountsDrawerHeader(
            accountName: Text("John Doe", style: TextStyle(fontSize: 18)),
            accountEmail: Text("johndoe@example.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
            ),
            decoration: BoxDecoration(color: Colors.blueAccent),
          ),

          // Common Menu Items
          ListTile(
            leading: Icon(Icons.dashboard, color: Colors.blueAccent),
            title: Text("Dashboard"),
            onTap: () {
              Navigator.pop(context); // Close Drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: Colors.blueAccent),
            title: Text("Profile"),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          // Role-Specific Menu Items
          // if (userRole == "admin")
          //   ListTile(
          //     leading: Icon(FontAwesomeIcons.userPlus, color: Colors.green),
          //     title: Text("Manage Users"),
          //     onTap: () {},
          //   ),
          // if (userRole == "manager")
          //   ListTile(
          //     leading:
          //         Icon(FontAwesomeIcons.clipboardList, color: Colors.orange),
          //     title: Text("Review Requests"),
          //     onTap: () {},
          //   ),
          // if (userRole == "employee")
          //   ListTile(
          //     leading: Icon(FontAwesomeIcons.paperPlane, color: Colors.teal),
          //     title: Text("Apply for Leave"),
          //     onTap: () {},
          //   ),

          Divider(),

          // Logout
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text("Logout"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
