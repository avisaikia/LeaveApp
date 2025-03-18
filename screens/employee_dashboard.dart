import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        dashboardCard("Apply for Leave", FontAwesomeIcons.paperPlane,
            Colors.tealAccent, () {}),
        dashboardCard("View Leave History", FontAwesomeIcons.history,
            Colors.purpleAccent, () {}),
      ],
    );
  }
}
