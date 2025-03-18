import 'package:flutter/material.dart';
import '../screens/admin_dashboard.dart';
import '../screens/manager_dashboard.dart';
import '../screens/employee_dashboard.dart';

class RoleBasedDashboard extends StatelessWidget {
  final String userRole;

  const RoleBasedDashboard({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    if (userRole == "admin") {
      return AdminDashboard();
    } else if (userRole == "manager") {
      return ManagerDashboard();
    } else {
      return EmployeeDashboard();
    }
  }
}
