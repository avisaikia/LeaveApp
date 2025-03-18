import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        dashboardCard(
          "Add User",
          FontAwesomeIcons.userPlus,
          Colors.blueAccent,
          () {},
        ),
        dashboardCard(
          "Remove User",
          FontAwesomeIcons.userMinus,
          Colors.redAccent,
          () {},
        ),
      ],
    );
  }
}
