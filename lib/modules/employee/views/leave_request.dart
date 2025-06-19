import 'package:final_project/modules/employee/controllers/leave_balance_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  String? _selectedLeaveType;
  String? _halfDayType;
  String? employeeId;
  String? managerId;
  bool _isBackdated = false;
  bool _isHalfDay = false;

  List<Map<String, dynamic>> _managers = [];

  @override
  void initState() {
    super.initState();
    _loadUserIdsAndBalance();
    _fetchManagers();
  }

  Future<void> _loadUserIdsAndBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email found in storage')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    final response =
        await Supabase.instance.client
            .from('users')
            .select()
            .eq('email', email)
            .single();

    final userId = response['id'];
    await Provider.of<LeaveBalanceProvider>(
      context,
      listen: false,
    ).fetchBalance(userId);

    if (mounted) {
      setState(() {
        employeeId = userId;
      });
    }
  }

  Future<void> _fetchManagers() async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('id, name')
          .eq('role', 'manager');

      setState(() {
        _managers = List<Map<String, dynamic>>.from(data);
      });
    } catch (error) {
      print('Error fetching managers: $error');
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: _isBackdated ? now.subtract(const Duration(days: 30)) : now,
      lastDate: _isBackdated ? now : now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (_selectedLeaveType == null || managerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (_startDateController.text.isEmpty || _endDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    final startDate = DateTime.parse(_startDateController.text);
    final endDate = DateTime.parse(_endDateController.text);
    final now = DateTime.now();

    if (_isBackdated) {
      if (startDate.isAfter(now) || endDate.isAfter(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Future dates not allowed')),
        );
        return;
      }
      if (startDate.isBefore(now.subtract(const Duration(days: 30)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only last 30 days allowed')),
        );
        return;
      }
    } else {
      if (startDate.isBefore(now) || endDate.isBefore(now)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Past dates not allowed')));
        return;
      }
    }

    if (startDate.isAfter(endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start date can\'t be after end date')),
      );
      return;
    }

    final existingLeaves = await Supabase.instance.client
        .from('leave_requests')
        .select('start_date, end_date, status')
        .eq('employee_id', employeeId!);

    for (final leave in existingLeaves) {
      final existingStart = DateTime.parse(leave['start_date']);
      final existingEnd = DateTime.parse(leave['end_date']);
      final status = leave['status'];

      final isOverlapping =
          !(endDate.isBefore(existingStart) || startDate.isAfter(existingEnd));

      if (isOverlapping) {
        final isExactMatch =
            startDate == existingStart && endDate == existingEnd;
        if (!(isExactMatch && status == 'rejected')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Leave overlaps with existing approved/pending leave.',
              ),
            ),
          );
          return;
        }
      }
    }

    double leaveDays;

    final difference = endDate.difference(startDate).inDays + 1;

    if (_isHalfDay) {
      leaveDays = 0.5;
    } else {
      leaveDays = difference.toDouble();
    }

    final balance =
        Provider.of<LeaveBalanceProvider>(context, listen: false).balance;

    final totalLeaves = balance!.totalLeaves.toDouble();
    final currentUsed = balance.usedLeaves.toDouble();
    final remainingLeaves = totalLeaves - currentUsed;

    if (leaveDays > remainingLeaves) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient leave balance. You have only $remainingLeaves left.',
          ),
        ),
      );
      return;
    }

    final uuid = const Uuid().v4();

    try {
      await Supabase.instance.client.from('leave_requests').insert({
        'id': uuid,
        'employee_id': employeeId,
        'manager_id': managerId,
        'leave_type': _selectedLeaveType,
        'start_date': _startDateController.text,
        'end_date': _endDateController.text,
        'half_day': _isHalfDay ? _halfDayType : null,
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      });

      await Supabase.instance.client.from('notifications').insert({
        'recipient_id': managerId,
        'role': 'manager',
        'message': 'You have a new leave request from an employee.',
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      final newUsedLeaves = currentUsed + leaveDays;

      await Supabase.instance.client
          .from('leave_balances')
          .update({'used_leaves': newUsedLeaves})
          .eq('user_id', employeeId!);

      await Provider.of<LeaveBalanceProvider>(
        context,
        listen: false,
      ).fetchBalance(employeeId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting request: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveBalance = context.watch<LeaveBalanceProvider>().balance;

    if (leaveBalance == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Leave'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Leave Balance Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCircleStat(
                        'Total',
                        leaveBalance.totalLeaves.toString(),
                        Colors.blue,
                      ),
                      _buildCircleStat(
                        'Used',
                        leaveBalance.usedLeaves.toString(),
                        Colors.orange,
                      ),
                      _buildCircleStat(
                        'Left',
                        leaveBalance.remainingLeaves.toString(),
                        Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Backdated Option
              DropdownButtonFormField<bool>(
                value: _isBackdated,
                decoration: _roundedDecoration('Request Type'),
                items: const [
                  DropdownMenuItem(value: false, child: Text('Future Leave')),
                  DropdownMenuItem(value: true, child: Text('Backdated Leave')),
                ],
                onChanged:
                    (value) => setState(() => _isBackdated = value ?? false),
              ),
              const SizedBox(height: 16),

              // Leave Type
              DropdownButtonFormField<String>(
                value: _selectedLeaveType,
                decoration: _roundedDecoration('Leave Type'),
                items:
                    ['Casual', 'Sick', 'Other']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged:
                    (value) => setState(() => _selectedLeaveType = value),
                validator:
                    (value) =>
                        value == null ? 'Please select a leave type' : null,
              ),
              const SizedBox(height: 16),

              // Manager
              DropdownButtonFormField<String>(
                value: managerId,
                decoration: _roundedDecoration('Select Manager'),
                items:
                    _managers
                        .map(
                          (manager) => DropdownMenuItem<String>(
                            value: manager['id'],
                            child: Text(manager['name']),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => managerId = val),
                validator:
                    (value) => value == null ? 'Please select a manager' : null,
              ),
              const SizedBox(height: 16),

              // Start Date
              TextFormField(
                controller: _startDateController,
                readOnly: true,
                decoration: _roundedDecoration('Start Date'),
                onTap: () => _pickDate(_startDateController),
              ),
              const SizedBox(height: 16),

              // End Date
              TextFormField(
                controller: _endDateController,
                readOnly: true,
                decoration: _roundedDecoration('End Date'),
                onTap: () => _pickDate(_endDateController),
              ),
              const SizedBox(height: 16),

              // Half Day Checkbox + Type
              CheckboxListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Text('Apply for Half Day Leave'),
                value: _isHalfDay,
                onChanged: (val) {
                  setState(() {
                    _isHalfDay = val ?? false;
                    if (!_isHalfDay) _halfDayType = null;
                  });
                },
              ),
              if (_isHalfDay)
                DropdownButtonFormField<String>(
                  value: _halfDayType,
                  decoration: _roundedDecoration('Half Day Type'),
                  items:
                      ['First Half', 'Second Half']
                          .map(
                            (half) => DropdownMenuItem(
                              value: half,
                              child: Text(half),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _halfDayType = value),
                  validator:
                      (value) =>
                          value == null ? 'Please select half day type' : null,
                ),
              const SizedBox(height: 24),

              // Submit
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _submitLeaveRequest();
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Submit Leave Request'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleStat(String label, String value, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  InputDecoration _roundedDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
