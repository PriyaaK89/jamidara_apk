class NotificationModel {
  final int id;
  final String? moduleType;
  final String? notificationCategory;
  final int isRead;
  final DateTime? createdAt;
  final String? orderNo;
  final String? status;
  final String? transactionType;
  final int? approvalLevel;
  final String? createdByName;
  final String? juniorName;
  final String? dispatcherName;
  final String? seniorName;
  final String? currentApproverName;
  final Map<String, dynamic> raw;

  NotificationModel({
    required this.id,
    this.moduleType,
    this.notificationCategory,
    required this.isRead,
    this.createdAt,
    this.orderNo,
    this.status,
    this.transactionType,
    this.approvalLevel,
    this.createdByName,
    this.juniorName,
    this.dispatcherName,
    this.seniorName,
    this.currentApproverName,
    required this.raw,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    int? parseInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');

    return NotificationModel(
      id: parseInt(json['id']) ?? 0,
      moduleType: json['module_type']?.toString(),
      notificationCategory: json['notification_category']?.toString(),
      isRead: parseInt(json['is_read']) ?? 0,
      createdAt: parseDate(json['created_at']),
      orderNo: json['order_no']?.toString(),
      status: json['status']?.toString(),
      transactionType: json['transaction_type']?.toString(),
      approvalLevel: parseInt(json['approval_level']),
      createdByName: json['created_by_name']?.toString(),
      juniorName: json['junior_name']?.toString(),
      dispatcherName: json['dispatcher_name']?.toString(),
      seniorName: json['senior_name']?.toString(),
      currentApproverName: json['current_approver_name']?.toString(),
      raw: json,
    );
  }
  /// order_notifications' own columns (via `n.*`) weren't shown, so this
  /// falls back through likely field names — swap in the real column
  /// (e.g. `raw['message']`) once you confirm it.
  String get displayMessage {
    return raw['message']?.toString() ??
        raw['title']?.toString() ??
        raw['notification_text']?.toString() ??
        '${transactionType ?? 'Order'} ${orderNo ?? ''} • ${status ?? ''}'.trim();
  }
}