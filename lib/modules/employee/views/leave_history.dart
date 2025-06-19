import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  List<dynamic> _allLeaveRequests = [];
  List<dynamic> _leaveRequests = [];
  bool _loading = true;

  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadLeaveHistory();
  }

  Future<void> _loadLeaveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;

    final leaveResponse = await Supabase.instance.client
        .from('leave_requests')
        .select('*')
        .eq('employee_id', userId)
        .order('submitted_at', ascending: false);

    setState(() {
      _allLeaveRequests = leaveResponse;
      _leaveRequests = leaveResponse;
      _loading = false;
    });
  }

  void _applyFilters() {
    List<dynamic> filtered = _allLeaveRequests;

    if (_selectedStatus != 'All') {
      filtered =
          filtered
              .where(
                (leave) =>
                    (leave['status'] ?? '').toString().toLowerCase() ==
                    _selectedStatus.toLowerCase(),
              )
              .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();

      filtered =
          filtered.where((leave) {
            final leaveType =
                (leave['leave_type'] ?? '').toString().toLowerCase();
            final status = (leave['status'] ?? '').toString().toLowerCase();
            final reason = (leave['reason'] ?? '').toString().toLowerCase();

            return leaveType.contains(q) ||
                status.contains(q) ||
                reason.contains(q);
          }).toList();
    }

    setState(() {
      _leaveRequests = filtered;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/employee-dashboard'),
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        SizedBox(
                          height: 48,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search type, status, reason...',
                              prefixIcon: const Icon(Icons.search),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (query) {
                              _searchQuery = query;
                              _applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Filter Chips with equal spacing
                        Wrap(
                          spacing: 12, // horizontal spacing
                          runSpacing: 8, // vertical spacing (if wrapped)
                          children:
                              ['All', 'Approved', 'Rejected', 'Pending'].map((
                                status,
                              ) {
                                final isSelected = _selectedStatus == status;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedStatus = status;
                                      _applyFilters();
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.blue.shade100
                                              : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.blue.shade800
                                                : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child:
                        _leaveRequests.isEmpty
                            ? const Center(
                              child: Text('No leave requests found.'),
                            )
                            : ListView.builder(
                              itemCount: _leaveRequests.length,
                              itemBuilder: (context, index) {
                                final leave = _leaveRequests[index];
                                final startDate = DateFormat(
                                  'MMM d, yyyy',
                                ).format(DateTime.parse(leave['start_date']));
                                final endDate = DateFormat(
                                  'MMM d, yyyy',
                                ).format(DateTime.parse(leave['end_date']));
                                final leaveType =
                                    leave['leave_type'] ?? 'Unknown';
                                final halfDay = leave['half_day'] ?? 'Full Day';

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade50,
                                        Colors.white,
                                      ],
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
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(
                                      '$leaveType Leave (${halfDay.toString().toUpperCase()})',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 6),
                                        Text(
                                          '📅 $startDate → $endDate',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        if ((leave['reason'] ?? '')
                                            .toString()
                                            .trim()
                                            .isNotEmpty)
                                          Text(
                                            '📝 Reason: ${leave['reason']}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        if ((leave['remark'] ?? '')
                                            .toString()
                                            .trim()
                                            .isNotEmpty)
                                          Text(
                                            '📌 Remark: ${leave['remark']}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Text(
                                      leave['status'].toString().toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(leave['status']),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
