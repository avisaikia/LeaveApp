import 'package:final_project/core/services/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerApprovalScreen extends StatefulWidget {
  const ManagerApprovalScreen({super.key});

  @override
  State<ManagerApprovalScreen> createState() => _ManagerApprovalScreenState();
}

class _ManagerApprovalScreenState extends State<ManagerApprovalScreen> {
  List<dynamic> _leaveRequests = [];
  List<dynamic> _filteredRequests = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    try {
      setState(() => _isLoading = true);
      final supabase = Supabase.instance.client;
      final managerId = await SessionHelper.getUserId();
      if (managerId == null) throw Exception('Manager ID not found.');

      final response = await supabase
          .from('leave_requests')
          .select('''
            *, employee:users!leave_requests_employee_id_fkey(name)
          ''')
          .eq('manager_id', managerId)
          .eq('status', 'pending');

      // Sort by submitted_at descending
      response.sort(
        (a, b) => DateTime.parse(
          b['submitted_at'],
        ).compareTo(DateTime.parse(a['submitted_at'])),
      );

      setState(() {
        _leaveRequests = response;
        _filteredRequests = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching pending requests: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterRequests(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredRequests =
          _leaveRequests.where((request) {
            final name = request['employee']['name']?.toLowerCase() ?? '';
            final type = request['leave_type']?.toLowerCase() ?? '';
            final date = request['submitted_at']?.toLowerCase() ?? '';
            return name.contains(_searchQuery) ||
                type.contains(_searchQuery) ||
                date.contains(_searchQuery);
          }).toList();
    });
  }

  Future<void> _confirmAndHandleDecision(String id, String decision) async {
    final bool confirmed = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '${decision == 'approved' ? 'Approve' : 'Reject'} Leave Request',
            ),
            content: Text(
              'Are you sure you want to ${decision == 'approved' ? 'approve' : 'reject'} this leave request?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      decision == 'approved' ? Colors.green : Colors.red,
                ),
                child: Text(
                  decision == 'approved' ? 'Approve' : 'Reject',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _handleDecision(id, decision);
    }
  }

  Future<void> _handleDecision(String requestId, String decision) async {
    try {
      final supabase = Supabase.instance.client;

      final leaveResponse =
          await supabase
              .from('leave_requests')
              .select('employee_id')
              .eq('id', requestId)
              .single();

      final String employeeId = leaveResponse['employee_id'];

      await supabase
          .from('leave_requests')
          .update({
            'status': decision,
            'decision_date': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      await supabase.from('notifications').insert({
        'recipient_id': employeeId,
        'role': 'employee',
        'message':
            'Your leave request has been ${decision == 'approved' ? 'approved' : 'rejected'}.',
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      await _fetchPendingRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave request ${decision.toUpperCase()}')),
      );
    } catch (e) {
      debugPrint('Error handling decision: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update leave request')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Leave Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/manager-dashboard'),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 🔍 Search Bar
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search by employee, leave type...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: _filterRequests,
                    ),
                  ),
                  Expanded(
                    child:
                        _filteredRequests.isEmpty
                            ? const Center(child: Text('No pending requests.'))
                            : ListView.builder(
                              itemCount: _filteredRequests.length,
                              itemBuilder: (context, index) {
                                final request = _filteredRequests[index];
                                final userName =
                                    request['employee']['name'] ?? 'Unknown';
                                final startDate =
                                    request['start_date'] ?? 'N/A';
                                final endDate = request['end_date'] ?? 'N/A';
                                final leaveType =
                                    request['leave_type'] ?? 'N/A';
                                final submittedAt =
                                    request['submitted_at'] != null
                                        ? DateFormat(
                                          'yyyy-MM-dd hh:mm a',
                                        ).format(
                                          DateTime.parse(
                                            request['submitted_at'],
                                          ),
                                        )
                                        : 'Unknown';

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '👤 Employee: $userName',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '📅 Duration: $startDate → $endDate',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          '📝 Type: $leaveType',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          '⏱️ Submitted At: $submittedAt',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              icon: const Icon(
                                                Icons.open_in_new,
                                                color: Colors.black,
                                              ),
                                              label: const Text(
                                                'Leave Details',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                  color: Colors.black,
                                                ),
                                              ),
                                              onPressed: () async {
                                                final result = await context.push(
                                                  '/manager/leave-detail/${request['id']}',
                                                );
                                                if (result == true) {
                                                  await _fetchPendingRequests(); // Refresh if decision made
                                                }
                                              },
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                ElevatedButton.icon(
                                                  icon: const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                  ),
                                                  label: const Text(
                                                    'Approve',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed:
                                                      () =>
                                                          _confirmAndHandleDecision(
                                                            request['id'],
                                                            'approved',
                                                          ),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton.icon(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                  ),
                                                  label: const Text(
                                                    'Reject',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed:
                                                      () =>
                                                          _confirmAndHandleDecision(
                                                            request['id'],
                                                            'rejected',
                                                          ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
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
