import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/notification_model.dart';
import "../services/notify_service.dart";

class NotificationCountGroup {
  final String? moduleType;
  final String? notificationCategory;
  final int total;

  NotificationCountGroup({
    this.moduleType,
    this.notificationCategory,
    required this.total,
  });

  factory NotificationCountGroup.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total'];
    return NotificationCountGroup(
      moduleType: json['module_type']?.toString(),
      notificationCategory: json['notification_category']?.toString(),
      total: rawTotal is int ? rawTotal : int.tryParse('$rawTotal') ?? 0,
    );
  }
}

class NotificationModal extends StatefulWidget {
  const NotificationModal({super.key});

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal> {
  bool _isLoading = true;
  String? _error;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    final res = await ApiService.markNotificationsRead(
      token,
      notificationIds: [notification.id],
    );

    if (res["success"] == true) {
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });

      final current = NotificationService.unreadCount.value;
      NotificationService.setUnreadCount(current > 0 ? current - 1 : 0);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "Failed to mark as read")),
        );
      }
    }
  }
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final res = await ApiService.getNotifications(token);

      if (res["success"] == true) {
        final List data = res["data"] ?? [];
        setState(() {
          _notifications = data
              .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res["message"] ?? "Failed to load notifications";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Something went wrong: $e";
        _isLoading = false;
      });
    }
  }


  

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Notifications",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: _fetchNotifications, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(child: Text("No new notifications"));
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final n = _notifications[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1),
              child: const Icon(Icons.notifications, color: Color(0xFF1B5E20)),
            ),
            title: Text(
              n.displayMessage,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                if (n.createdByName != null) "By: ${n.createdByName}",
                if (n.createdAt != null) _formatDate(n.createdAt!),
              ].join(" • "),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Color(0xFF1B5E20)),
              tooltip: "Mark as read",
              onPressed: () => _markAsRead(n),
            ),
          );
        },
      ),
    );
  }

String _formatDate(DateTime date) {
    int hour = date.hour;
    final String period = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    if (hour == 0) hour = 12;

    final String hourStr = hour.toString().padLeft(2, '0');
    final String minuteStr = date.minute.toString().padLeft(2, '0');

    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} "
        "$hourStr:$minuteStr $period";
  }
}