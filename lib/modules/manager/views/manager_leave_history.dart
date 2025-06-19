import 'package:final_project/core/services/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerLeaveHistoryScreen extends StatefulWidget {
  const ManagerLeaveHistoryScreen({super.key});

  @override
  State<ManagerLeaveHistoryScreen> createState() =>
      _ManagerLeaveHistoryScreenState();
}

class _ManagerLeaveHistoryScreenState extends State<ManagerLeaveHistoryScreen> {
  List<dynamic> _leaveHistory = [];
  List<dynamic> _filteredLeaveHistory = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchLeaveHistory();
  }

  Future<void> _fetchLeaveHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final managerId = await SessionHelper.getUserId();
      if (managerId == null) throw Exception("Manager ID not found.");

      final data = await supabase
          .from('leave_requests')
          .select('''
      id, status, start_date, end_date, submitted_at, decision_date, leave_type, half_day,
      employee:users!leave_requests_employee_id_fkey(name),
      manager:users!leave_requests_manager_id_fkey(name)
    ''')
          .eq('manager_id', managerId)
          .neq('status', 'pending');

      data.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['decision_date'] ?? '') ?? DateTime(0);
        final dateB =
            DateTime.tryParse(b['decision_date'] ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _leaveHistory = data;
        _filteredLeaveHistory = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching leave history: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase();

    List<dynamic> filtered = _leaveHistory;

    if (_selectedStatus != 'All') {
      filtered =
          filtered.where((request) {
            final status = (request['status'] ?? '').toString().toLowerCase();
            return status == _selectedStatus.toLowerCase();
          }).toList();
    }

    if (query.isNotEmpty) {
      filtered =
          filtered.where((request) {
            final employeeName =
                request['employee']?['name']?.toLowerCase() ?? '';
            final leaveType = request['leave_type']?.toLowerCase() ?? '';
            final status = request['status']?.toLowerCase() ?? '';
            return employeeName.contains(query) ||
                leaveType.contains(query) ||
                status.contains(query);
          }).toList();
    }

    setState(() {
      _filteredLeaveHistory = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave History'),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Field
                        SizedBox(
                          height: 48,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search by name, leave type, or status',
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
                        // Status Filter Chips
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              ['All', 'Approved', 'Rejected'].map((status) {
                                final isSelected = _selectedStatus == status;
                                return ChoiceChip(
                                  label: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: Colors.blue,
                                  backgroundColor: Colors.grey.shade200,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedStatus = status;
                                      _applyFilters(); // or _filterLeaveHistory()
                                    });
                                  },
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        _filteredLeaveHistory.isEmpty
                            ? const Center(
                              child: Text('No leave decisions found.'),
                            )
                            : ListView.builder(
                              itemCount: _filteredLeaveHistory.length,
                              itemBuilder: (context, index) {
                                final request = _filteredLeaveHistory[index];
                                final userName =
                                    request['employee']?['name'] ??
                                    'Unknown Employee';
                                final status = request['status'] ?? 'unknown';
                                final startDate = request['start_date'] ?? '';
                                final endDate = request['end_date'] ?? '';
                                final rawSubmittedAt = request['submitted_at'];
                                final submittedAt =
                                    rawSubmittedAt != null
                                        ? DateFormat(
                                          'MMM d, h:mm a',
                                        ).format(DateTime.parse(rawSubmittedAt))
                                        : 'Unknown';
                                final leaveType =
                                    request['leave_type'] ?? 'N/A';

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
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Leave Type: $leaveType',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          'Leave Dates: $startDate → $endDate',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          'Submitted At: $submittedAt',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              status == 'approved'
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color:
                                                  status == 'approved'
                                                      ? Colors.green
                                                      : Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              status.toString().toUpperCase(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
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
