import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaveRequestDetailScreen extends StatefulWidget {
  final String requestId;

  const LeaveRequestDetailScreen({super.key, required this.requestId});

  @override
  State<LeaveRequestDetailScreen> createState() =>
      _LeaveRequestDetailScreenState();
}

class _LeaveRequestDetailScreenState extends State<LeaveRequestDetailScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? leaveDetails;
  Map<String, dynamic>? leaveBalance;
  List<dynamic> leaveHistory = [];
  bool isLoading = true;
  final TextEditingController _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    try {
      setState(() => isLoading = true);

      final request =
          await supabase
              .from('leave_requests')
              .select('''
        id, start_date, end_date, leave_type, half_day, submitted_at, employee_id,
        employee:users!leave_requests_employee_id_fkey(name)
      ''')
              .eq('id', widget.requestId)
              .single();

      final empId = request['employee_id'];

      final balance =
          await supabase
              .from('leave_balances')
              .select()
              .eq('user_id', empId)
              .single();

      final history = await supabase
          .from('leave_requests')
          .select('start_date, end_date, leave_type, status')
          .eq('employee_id', empId)
          .neq('id', widget.requestId)
          .order('start_date', ascending: false);

      setState(() {
        leaveDetails = request;
        leaveBalance = balance;
        leaveHistory = history;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleDecision(String decision) async {
    try {
      final empId = leaveDetails!['employee_id'];
      final remark = _remarkController.text.trim();

      await supabase
          .from('leave_requests')
          .update({
            'status': decision,
            'decision_date': DateTime.now().toIso8601String(),
            'remark': remark,
          })
          .eq('id', widget.requestId);

      await supabase.from('notifications').insert({
        'recipient_id': empId,
        'role': 'employee',
        'message':
            'Your leave request has been ${decision == 'approved' ? 'approved' : 'rejected'}.',
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request ${decision.toUpperCase()}')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Decision error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update request')),
        );
      }
    }
  }

  Future<void> _confirmDecision(String decision) async {
    final result = await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('${decision.toUpperCase()} Request'),
            content: Text(
              'Are you sure you want to $decision this leave request?\n\nRemark: ${_remarkController.text.trim()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(decision.toUpperCase()),
              ),
            ],
          ),
    );

    if (result == true) {
      await _handleDecision(decision);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (leaveDetails == null) {
      return const Scaffold(
        body: Center(child: Text("Unable to load leave request.")),
      );
    }

    final employeeName = leaveDetails!['employee']['name'];
    final startDate = DateFormat.yMMMd().format(
      DateTime.parse(leaveDetails!['start_date']),
    );
    final endDate = DateFormat.yMMMd().format(
      DateTime.parse(leaveDetails!['end_date']),
    );
    final leaveType = leaveDetails!['leave_type'];
    final halfDayValue = leaveDetails!['half_day'];
    final isHalfDay =
        halfDayValue != null ? 'Half Day (${halfDayValue})' : 'Full Day';
    final submittedAt = DateFormat.yMMMd().add_jm().format(
      DateTime.parse(leaveDetails!['submitted_at']),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Leave Request Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildCard(
              title: "Leave Balance",
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircleStat(
                      label: "Total",
                      value: leaveBalance!['total_leaves'].toString(),
                      color: Colors.blue,
                      icon: Icons.calendar_month,
                    ),
                    _buildCircleStat(
                      label: "Used",
                      value: leaveBalance!['used_leaves'].toString(),
                      color: Colors.orange,
                      icon: Icons.event_busy,
                    ),
                    _buildCircleStat(
                      label: "Left",
                      value:
                          (leaveBalance!['total_leaves'] -
                                  leaveBalance!['used_leaves'])
                              .toString(),
                      color: Colors.green,
                      icon: Icons.event_available,
                    ),
                  ],
                ),
              ],
            ),

            _buildCard(
              title: "👤 Employee Details",
              children: [
                Text("Name: $employeeName"),
                Text("Duration: $startDate → $endDate"),
                Text("Type: $leaveType — $isHalfDay"),
                Text("Submitted: $submittedAt"),
              ],
            ),
            _buildCard(
              title: "🗒️ Manager's Remark",
              children: [
                TextField(
                  controller: _remarkController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Add remarks (optional)",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    "Approve",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => _confirmDecision('approved'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    "Reject",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => _confirmDecision('rejected'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildCard(
              title: "📜 Previous Leave History",
              children:
                  leaveHistory.isEmpty
                      ? [const Text("No previous leave records.")]
                      : leaveHistory.map((entry) {
                        final histStart = DateFormat.yMMMd().format(
                          DateTime.parse(entry['start_date']),
                        );
                        final histEnd = DateFormat.yMMMd().format(
                          DateTime.parse(entry['end_date']),
                        );
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("$histStart → $histEnd"),
                          subtitle: Text(
                            "${entry['leave_type']} — Status: ${entry['status']}",
                          ),
                        );
                      }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCard({required String title, required List<Widget> children}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue.shade50, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

Widget _buildCircleStat({
  required String label,
  required String value,
  required Color color,
  required IconData icon,
}) {
  return Column(
    children: [
      Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
