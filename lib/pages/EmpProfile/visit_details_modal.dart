import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_service.dart';

class VisitDetail {
  final int id;
  final String createdAt;
  final String visitType;
  final String customerType;
  final String visitPurpose;
  final String comment;
  final String? reminderDate;
  final String employeeName;
  final String contactNo;
  final String customerName;
  final String firmName;
  final String contactNumber;
  final String address;
  final String area;
  final String? district;
  final String pincode;
  final String? imageUrl;

  VisitDetail({
    required this.id,
    required this.createdAt,
    required this.visitType,
    required this.customerType,
    required this.visitPurpose,
    required this.comment,
    this.reminderDate,
    required this.employeeName,
    required this.contactNo,
    required this.customerName,
    required this.firmName,
    required this.contactNumber,
    required this.address,
    required this.area,
    this.district,
    required this.pincode,
    this.imageUrl,
  });

  factory VisitDetail.fromJson(Map<String, dynamic> json) {
    return VisitDetail(
      id: json['id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      visitType: json['visit_type'] ?? '',
      customerType: json['customer_type'] ?? '',
      visitPurpose: json['visit_purpose'] ?? '',
      comment: json['comment'] ?? '',
      reminderDate: json['reminder_date'],
      employeeName: json['employee_name'] ?? '',
      contactNo: json['contact_no'] ?? '',
      customerName: json['customer_name'] ?? '',
      firmName: json['firm_name'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      address: json['address'] ?? '',
      area: json['area'] ?? '',
      district: json['district'],
      pincode: json['pincode'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}

// ─────────────────────────────────────────────
// API
// ─────────────────────────────────────────────

/// Fetches visit details for a user across a date RANGE (start–end
/// inclusive) — mirrors fetchHierarchyVisits' start_date/end_date pattern.
Future<List<VisitDetail>> fetchUserVisitDetails(
  int userId, {
  required String startDate,
  required String endDate,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final base = prefs.getString('FLUTTER_BASE_URL') ?? '';
  final token = await StorageService.getToken();

  final uri = Uri.parse('$base/get-hierarchy-visits/$userId').replace(
    queryParameters: {
      'start_date': startDate,
      'end_date': endDate,
    },
  );
  debugPrint('fetchUserVisitDetails → $uri');

  final response = await http.get(uri, headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  });

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    final List<dynamic> data = decoded['data'] ?? [];
    return data.map((e) => VisitDetail.fromJson(e)).toList();
  }
  throw Exception(
      'Failed to load visit details (${response.statusCode}): ${response.body}');
}

// ─────────────────────────────────────────────
// Show Modal — call this from anywhere
// ─────────────────────────────────────────────

void showVisitDetailsModal(
  BuildContext context, {
  required int userId,
  required String employeeName,
  required int totalVisits,
  required String startDate,
  required String endDate,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VisitDetailsModal(
      userId: userId,
      employeeName: employeeName,
      totalVisits: totalVisits,
      startDate: startDate,
      endDate: endDate,
    ),
  );
}

// ─────────────────────────────────────────────
// Modal Widget
// ─────────────────────────────────────────────

class _VisitDetailsModal extends StatefulWidget {
  final int userId;
  final String employeeName;
  final int totalVisits;
  final String startDate;
  final String endDate;

  const _VisitDetailsModal({
    required this.userId,
    required this.employeeName,
    required this.totalVisits,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<_VisitDetailsModal> createState() => _VisitDetailsModalState();
}

class _VisitDetailsModalState extends State<_VisitDetailsModal> {
  List<VisitDetail> _visits = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await fetchUserVisitDetails(
        widget.userId,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );
      setState(() {
        _visits = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── helpers ──
  String _formatDate(String raw) {
    try {
      // Force UTC interpretation, regardless of whether the string has 'Z' or not
      DateTime dt = DateTime.parse(raw);
      if (!raw.endsWith('Z') && !raw.contains('+')) {
        dt = DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
      }
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
    } catch (_) {
      return raw;
    }
  }

  String _formatReminderDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _purposeLabel(String p) {
    const map = {
      'new_dist_planning': 'New Dist. Planning',
      'sales_order': 'Sales Order',
      'sales_return': 'Sales Return',
      'collection': 'Collection',
      'others': 'Others',
    };
    return map[p] ?? p;
  }

  Color _purposeColor(String p) {
    switch (p) {
      case 'sales_order':      return const Color(0xFF1B5E20);
      case 'collection':       return const Color(0xFF1565C0);
      case 'sales_return':     return const Color(0xFFB71C1C);
      case 'new_dist_planning':return const Color(0xFF6A1B9A);
      default:                 return const Color(0xFF757575);
    }
  }

  Color _typeColor(String t) {
    switch (t.toLowerCase()) {
      case 'retailer':    return const Color(0xFF2E7D32);
      case 'distributor': return const Color(0xFF1565C0);
      default:            return const Color(0xFF757575);
    }
  }

  /// "12 Jan 2026" if start == end, otherwise "12 Jan 2026 - 14 Jan 2026"
  String get _rangeLabel {
    if (widget.startDate == widget.endDate) return widget.startDate;
    return '${widget.startDate} - ${widget.endDate}';
  }

  // ── build ──
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 20,
            child: Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employeeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${widget.totalVisits} visit${widget.totalVisits != 1 ? 's' : ''} · $_rangeLabel',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to load visit details',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_walk_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No visit details found',
              style: TextStyle(
                  color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _visits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _VisitDetailCard(
        visit: _visits[i],
        index: i + 1,
        formatDate: _formatDate,
        formatReminder: _formatReminderDate,
        purposeLabel: _purposeLabel,
        purposeColor: _purposeColor,
        typeColor: _typeColor,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Visit Detail Card  (unchanged)
// ─────────────────────────────────────────────

class _VisitDetailCard extends StatelessWidget {
  final VisitDetail visit;
  final int index;
  final String Function(String) formatDate;
  final String Function(String?) formatReminder;
  final String Function(String) purposeLabel;
  final Color Function(String) purposeColor;
  final Color Function(String) typeColor;

  const _VisitDetailCard({
    required this.visit,
    required this.index,
    required this.formatDate,
    required this.formatReminder,
    required this.purposeLabel,
    required this.purposeColor,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    final pColor = purposeColor(visit.visitPurpose);
    final tColor = typeColor(visit.visitType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: pColor.withOpacity(0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formatDate(visit.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                _badge(purposeLabel(visit.visitPurpose), pColor),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _badge(
                      visit.visitType[0].toUpperCase() +
                          visit.visitType.substring(1),
                      tColor,
                    ),
                    const SizedBox(width: 8),
                    _badge(
                      visit.customerType == 'new' ? 'New Customer' : 'Existing',
                      visit.customerType == 'new'
                          ? const Color(0xFF6A1B9A)
                          : const Color(0xFF757575),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _sectionTitle('Customer Info'),
                const SizedBox(height: 8),
                _infoRow(Icons.person_outline, 'Name', visit.customerName),
                _infoRow(Icons.business_outlined, 'Firm', visit.firmName),
                _infoRow(Icons.phone_outlined, 'Contact', visit.contactNumber),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _sectionTitle('Location'),
                const SizedBox(height: 8),
                _infoRow(Icons.location_on_outlined, 'Address', visit.address),
                _infoRow(Icons.map_outlined, 'Area', visit.area),
                if (visit.district != null && visit.district!.isNotEmpty)
                  _infoRow(Icons.corporate_fare_outlined, 'District', visit.district!),
                _infoRow(Icons.pin_drop_outlined, 'Pincode', visit.pincode),
                if (visit.comment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _sectionTitle('Comment'),
                  const SizedBox(height: 6),
                  Text(
                    visit.comment,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
                if (visit.reminderDate != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.notifications_outlined,
                    'Reminder',
                    formatReminder(visit.reminderDate),
                    iconColor: const Color(0xFFE65100),
                  ),
                ],
                if (visit.imageUrl != null && visit.imageUrl!.length > 10) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _sectionTitle('Visit Photo'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showFullImage(context, visit.imageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        visit.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          color: Colors.grey[100],
                          child: Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: Colors.grey[400]),
                          ),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 180,
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF1B5E20)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: Color(0xFF1B5E20),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color iconColor = const Color(0xFF1B5E20),
  }) {
    if (value.isEmpty || value == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          SizedBox(
            width: 70,
            child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}