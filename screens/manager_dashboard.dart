import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        dashboardCard("View Leave Requests", FontAwesomeIcons.clipboardList,
            Colors.orangeAccent, () {}),
        // ignore: deprecated_member_use
        dashboardCard("Approve/Reject Requests", FontAwesomeIcons.checkCircle,
            Colors.greenAccent, () {}),
      ],
    );
  }
}
