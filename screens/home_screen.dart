import 'package:flutter/material.dart';
import 'package:leave_app/widgets/leave_summary.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/role_based_dashboard.dart';

class HomeScreen extends StatelessWidget {
  final String userRole;

  const HomeScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
      ),
      drawer: CustomDrawer(
        userRole: userRole,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),

            if (userRole != "admin") LeaveSummary(),

            SizedBox(height: 20),

            // Role-Based Dashboard
            Expanded(
              child: RoleBasedDashboard(userRole: userRole),
            ),
          ],
        ),
      ),
    );
  }
}
