import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;
  final String role;

  const NotificationsScreen({
    required this.userId,
    required this.role,
    super.key,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => _isLoading = true);

    final response = await supabase
        .from('notifications')
        .select()
        .eq('recipient_id', widget.userId)
        .eq('role', 'manager')
        .order('timestamp', ascending: false);

    setState(() {
      _notifications = response;
      _isLoading = false;
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
    fetchNotifications();
  }

  // MARK ALL NOTIFICATIONS AS READ
  Future<void> markAllAsRead() async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', widget.userId)
        .eq('role', 'manager');
    fetchNotifications();
  }

  // DELETE ALL NOTIFICATIONS
  Future<void> clearNotifications() async {
    await supabase
        .from('notifications')
        .delete()
        .eq('recipient_id', widget.userId)
        .eq('role', 'manager');
    fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/manager-dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            tooltip: 'Mark All as Read',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Mark All Notifications as Read'),
                      content: const Text(
                        'Are you sure you want to mark all notifications as read?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Mark All Read'),
                        ),
                      ],
                    ),
              );

              if (confirm == true) {
                await markAllAsRead();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All Notifications',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Clear Notifications'),
                      content: const Text(
                        'Are you sure you want to clear all notifications? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
              );

              if (confirm == true) {
                await clearNotifications();
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  final isRead = item['is_read'] ?? false;
                  final message = item['message'] ?? 'No message';
                  final timestamp = DateTime.parse(item['timestamp']);

                  return ListTile(
                    title: Text(message),
                    subtitle: Text('${timestamp.toLocal()}'),
                    tileColor: isRead ? Colors.white : Colors.blue[50],
                    trailing:
                        isRead
                            ? null
                            : const Icon(
                              Icons.mark_email_unread,
                              color: Colors.blue,
                            ),
                    onTap: () => markAsRead(item['id']),
                  );
                },
              ),
    );
  }
}
