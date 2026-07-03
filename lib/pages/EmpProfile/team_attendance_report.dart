import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_service.dart';
import '../../layout/main_layout.dart';
import '../../layout/app_router.dart';

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────

class TeamAttendance {
  final int employeeId;
  final String employeeName;
  final String contactNo;
  final String roleName;
  final int level;
  final String attendanceDate;
  final String status;
  final String attendanceUnit;
  final int workingMinutes;
  final String? checkInTime;
  final String? checkOutTime;
  final String? visitLocation;
  final String? travelMode;
  final String? workType;
  final String? fieldWorkType;
  final String? vehicleType;
  final int? odometerReading;
  final int? dayOverOdometerReading;
  final String? leaveReason;

  TeamAttendance({
    required this.employeeId,
    required this.employeeName,
    required this.contactNo,
    required this.roleName,
    required this.level,
    required this.attendanceDate,
    required this.status,
    required this.attendanceUnit,
    required this.workingMinutes,
    this.checkInTime,
    this.checkOutTime,
    this.visitLocation,
    this.travelMode,
    this.workType,
    this.fieldWorkType,
    this.vehicleType,
    this.odometerReading,
    this.dayOverOdometerReading,
    this.leaveReason,
  });

  factory TeamAttendance.fromJson(Map<String, dynamic> json) {
    return TeamAttendance(
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'] ?? '',
      contactNo: json['contact_no'] ?? '',
      roleName: json['role_name'] ?? '',
      level: json['level'] ?? 0,
      attendanceDate: json['attendance_date'] ?? '',
      status: json['status'] ?? '',
      attendanceUnit: json['attendance_unit'] ?? '',
      workingMinutes: json['working_minutes'] ?? 0,
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      visitLocation: json['visit_location'],
      travelMode: json['travel_mode'],
      workType: json['work_type'],
      fieldWorkType: json['field_work_type'],
      vehicleType: json['vehicle_type'],
      odometerReading: json['odometer_reading'],
      dayOverOdometerReading: json['day_over_odometer_reading'],
      leaveReason: json['leave_reason'],
    );
  }
}

class AttendanceImages {
  final Map<String, String> images;

  AttendanceImages({required this.images});

  factory AttendanceImages.fromJson(Map<String, dynamic> json) {
    final raw = json['images'] as Map<String, dynamic>? ?? {};
    return AttendanceImages(
      images: raw.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

class LevelUserAttendance {
  final int id;
  final String name;
  final String jobRole;

  LevelUserAttendance({
    required this.id,
    required this.name,
    required this.jobRole,
  });

  factory LevelUserAttendance.fromJson(Map<String, dynamic> json) {
    return LevelUserAttendance(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      jobRole: json['job_role'] ?? json['role_name'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LevelUserAttendance && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────
// Level config
// ─────────────────────────────────────────────

const List<Map<String, dynamic>> _allLevels = [
  {'level': 1, 'slug': 'zsm', 'label': 'ZSM'},
  {'level': 2, 'slug': 'rsm', 'label': 'RSM'},
  {'level': 3, 'slug': 'asm', 'label': 'ASM'},
  {'level': 4, 'slug': 'tsm', 'label': 'TSM'},
  {'level': 5, 'slug': 'so', 'label': 'SO'},
  {'level': 6, 'slug': 'fa', 'label': 'FA'},
];

List<Map<String, dynamic>> _getSubordinateLevelOptions(int myLevel) {
  return _allLevels
      .where((l) => (l['level'] as int) > myLevel)
      .toList();
}

// ─────────────────────────────────────────────
// Formatting helpers (NEW)
// ─────────────────────────────────────────────

/// Converts a "HH:mm:ss" (24-hour) time string into a friendly
/// "h:mm a" (12-hour with AM/PM) string. Falls back gracefully
/// if the value is null, empty, or not parseable.
String formatTime12Hour(String? time) {
  if (time == null || time.trim().isEmpty) return '—';
  try {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dt);
  } catch (_) {
    return time;
  }
}

/// Converts snake_case / lowercase backend values like
/// "two_wheeler" or "private" into readable Title Case labels
/// like "Two Wheeler" or "Private". Returns '—' for empty values.
String formatLabel(String? value) {
  if (value == null || value.trim().isEmpty) return '—';
  return value
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

// ─────────────────────────────────────────────
// API helpers
// ─────────────────────────────────────────────

Future<String> _baseUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('FLUTTER_BASE_URL') ?? '';
}

Future<Map<String, String>> _authHeaders() async {
  final token = await StorageService.getToken();
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}

Future<List<LevelUserAttendance>> _fetchUsersByLevel(int level) async {
  final base = await _baseUrl();
  final headers = await _authHeaders();
  final uri = Uri.parse('$base/users-by-level')
      .replace(queryParameters: {'level': level.toString()});
  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    final List<dynamic> data = body['data'] ?? [];
    return data.map((e) => LevelUserAttendance.fromJson(e)).toList();
  }
  throw Exception('Failed to load users (${response.statusCode})');
}

Future<List<TeamAttendance>> _fetchTeamAttendance({
  required String date,
  int? level,
  int? userId,
}) async {
  final base = await _baseUrl();
  final headers = await _authHeaders();
  final params = <String, String>{'date': date};
  if (level != null) params['level'] = level.toString();
  if (userId != null) params['user_id'] = userId.toString();
  final uri = Uri.parse('$base/my-team-attendance')
      .replace(queryParameters: params);
  debugPrint('fetchTeamAttendance → $uri');
  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    final List<dynamic> data = decoded['data'] ?? [];
    return data.map((e) => TeamAttendance.fromJson(e)).toList();
  }
  throw Exception(
      'Failed to load attendance (${response.statusCode}): ${response.body}');
}

Future<AttendanceImages> _fetchAttendanceImages(
    int employeeId, String date) async {
  final base = await _baseUrl();
  final headers = await _authHeaders();
  final uri = Uri.parse('$base/get-attendance-images/$employeeId')
      .replace(queryParameters: {'date': date});
  debugPrint('fetchAttendanceImages → $uri');
  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    return AttendanceImages.fromJson(jsonDecode(response.body));
  }
  throw Exception(
      'No images found (${response.statusCode})');
}

// ─────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────

class TeamAttendancePage extends StatefulWidget {
  final int myLevel;

  const TeamAttendancePage({super.key, required this.myLevel});

  @override
  State<TeamAttendancePage> createState() => _TeamAttendancePageState();
}

class _TeamAttendancePageState extends State<TeamAttendancePage> {
  // ── filter state ──
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedLevelOption;
  LevelUserAttendance? _selectedUser;

  // ── data ──
  late final List<Map<String, dynamic>> _subordinateOptions;
  List<LevelUserAttendance> _levelUsers = [];
  List<TeamAttendance> _attendanceList = [];

  // ── loading / error ──
  bool _loadingUsers = false;
  bool _loadingAttendance = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subordinateOptions = _getSubordinateLevelOptions(widget.myLevel);
    _loadAttendance();
  }

  // ── loaders ──
  Future<void> _loadAttendance() async {
    setState(() {
      _loadingAttendance = true;
      _error = null;
    });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final results = await _fetchTeamAttendance(
        date: dateStr,
        level: _selectedLevelOption?['level'] as int?,
        userId: _selectedUser?.id,
      );
      setState(() => _attendanceList = results);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingAttendance = false);
    }
  }

  Future<void> _onLevelChanged(Map<String, dynamic>? option) async {
    setState(() {
      _selectedLevelOption = option;
      _selectedUser = null;
      _levelUsers = [];
    });
    _loadAttendance();

    if (option != null) {
      setState(() => _loadingUsers = true);
      try {
        final users = await _fetchUsersByLevel(option['level'] as int);
        setState(() => _levelUsers = users);
      } catch (e) {
        _showSnack('Could not load users: $e');
      } finally {
        setState(() => _loadingUsers = false);
      }
    }
  }

  Future<void> _onUserChanged(LevelUserAttendance? user) async {
    setState(() => _selectedUser = user);
    _loadAttendance();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1B5E20),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadAttendance();
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── attendance image modal ──
  Future<void> _showImageModal(TeamAttendance item) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AttendanceImageModal(
        employeeId: item.employeeId,
        employeeName: item.employeeName,
        date: dateStr,
        fetchImages: _fetchAttendanceImages,
      ),
    );
  }

  // ── helpers ──
  String _formatWorkingTime(int minutes) {
    if (minutes == 0) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present': return const Color(0xFF1B5E20);
      case 'absent':  return const Color(0xFFB71C1C);
      case 'leave':   return const Color(0xFFE65100);
      case 'half day':return const Color(0xFF1565C0);
      default:        return const Color(0xFF757575);
    }
  }

  String _indexToRoute(int index) {
    switch (index) {
      case 0: return "dashboard";
      case 1: return "attendance";
      case 2: return "visit";
      case 3: return "order";
      case 4: return "more";
      default: return "dashboard";
    }
  }

  // ── summary counts ──
  Map<String, int> get _summaryCount {
    final map = <String, int>{};
    for (final a in _attendanceList) {
      final s = a.status.toLowerCase();
      map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }

  // ── build ──
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildFilterPanel(),
      _buildSummaryBar(),
      Expanded(child: _buildBody()),
    ],
  );
}
  // ── filter panel (REDESIGNED — light floating card, no duplicate green block) ──
  Widget _buildFilterPanel() {
    return Container(
      color: const Color.fromARGB(255, 248, 248, 248),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded,
                  color: Color(0xFF1B5E20), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Team Attendance',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDateRow(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildLevelDropdown()),
                    if (_selectedLevelOption != null) ...[
                      const SizedBox(width: 10),
                      Expanded(child: _buildUserDropdown()),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E6E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: Color(0xFF1B5E20), size: 18),
            const SizedBox(width: 10),
            Text(
              DateFormat('dd MMM yyyy').format(_selectedDate),
              style: const TextStyle(
                  color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelDropdown() {
    return _styledDropdown<Map<String, dynamic>?>(
      hint: 'All Levels',
      value: _selectedLevelOption,
      items: [
        const DropdownMenuItem(value: null, child: Text('All Levels')),
        ..._subordinateOptions.map(
          (opt) => DropdownMenuItem(
            value: opt,
            child: Text(opt['label'] as String),
          ),
        ),
      ],
      onChanged: _onLevelChanged,
    );
  }

  Widget _buildUserDropdown() {
    if (_loadingUsers) {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E6E0)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF1B5E20)),
          ),
        ),
      );
    }
    return _styledDropdown<LevelUserAttendance?>(
      hint: 'All Members',
      value: _selectedUser,
      items: [
        const DropdownMenuItem(value: null, child: Text('All Members')),
        ..._levelUsers.map(
          (u) => DropdownMenuItem(value: u, child: Text(u.name)),
        ),
      ],
      onChanged: _onUserChanged,
    );
  }

  Widget _styledDropdown<T>({
    required String hint,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E6E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── summary bar (light card, sits under the filter panel) ──
  Widget _buildSummaryBar() {
    final counts = _summaryCount;
    return Container(
      color: const Color.fromARGB(255, 248, 248, 248),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _summaryChip(Icons.people_outline,
                '${_attendanceList.length}', 'Total',
                color: const Color(0xFF1B5E20)),
            const SizedBox(width: 14),
            if ((counts['present'] ?? 0) > 0)
              _summaryChip(Icons.check_circle_outline,
                  '${counts['present']}', 'Present',
                  color: const Color(0xFF2E7D32)),
            if ((counts['absent'] ?? 0) > 0) ...[
              const SizedBox(width: 14),
              _summaryChip(Icons.cancel_outlined,
                  '${counts['absent']}', 'Absent',
                  color: const Color(0xFFB71C1C)),
            ],
            if ((counts['leave'] ?? 0) > 0) ...[
              const SizedBox(width: 14),
              _summaryChip(Icons.event_busy_outlined,
                  '${counts['leave']}', 'Leave',
                  color: const Color(0xFFE65100)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String value, String label,
      {Color color = Colors.black87}) {
    return Row(
      children: [
        Icon(icon, color: color.withOpacity(0.85), size: 15),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }

  // ── body ──
  Widget _buildBody() {
    if (_loadingAttendance) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
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
              Text('Failed to load attendance',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey[800])),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAttendance,
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

    if (_attendanceList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No attendance on ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
              style: TextStyle(
                  color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1B5E20),
      onRefresh: _loadAttendance,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _attendanceList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _AttendanceCard(
          item: _attendanceList[i],
          statusColor: _statusColor(_attendanceList[i].status),
          formattedWorkingTime:
              _formatWorkingTime(_attendanceList[i].workingMinutes),
          onViewImages: () => _showImageModal(_attendanceList[i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Attendance Card
// ─────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  final TeamAttendance item;
  final Color statusColor;
  final String formattedWorkingTime;
  final VoidCallback onViewImages;

  const _AttendanceCard({
    required this.item,
    required this.statusColor,
    required this.formattedWorkingTime,
    required this.onViewImages,
  });

  @override
  Widget build(BuildContext context) {
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
        children: [
          // ── Header ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withOpacity(0.15),
                  child: Text(
                    item.employeeName.isNotEmpty
                        ? item.employeeName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        item.roleName,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    formatLabel(item.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Row 1: Check-in / Check-out / Working hours
                Row(
                  children: [
                    _infoBlock(
                      Icons.login_rounded,
                      'Check In',
                      formatTime12Hour(item.checkInTime),
                      const Color(0xFF1B5E20),
                    ),
                    _divider(),
                    _infoBlock(
                      Icons.logout_rounded,
                      'Check Out',
                      formatTime12Hour(item.checkOutTime),
                      const Color(0xFFB71C1C),
                    ),
                    _divider(),
                    _infoBlock(
                      Icons.access_time_rounded,
                      'Working',
                      formattedWorkingTime,
                      const Color(0xFF1565C0),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Row 2: Work type / Attendance unit
                Row(
                  children: [
                    Expanded(
                      child: _labelValue(
                        'Attendance',
                        formatLabel(item.attendanceUnit),
                      ),
                    ),
                    Expanded(
                      child: _labelValue(
                        'Work Type',
                        formatLabel(item.workType),
                      ),
                    ),
                    if (item.fieldWorkType != null)
                      Expanded(
                        child: _labelValue(
                          'Field Work',
                          formatLabel(item.fieldWorkType),
                        ),
                      ),
                  ],
                ),

                // Row 3: Travel / Odometer (only if present)
                if (item.travelMode != null ||
                    item.odometerReading != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.travelMode != null)
                        Expanded(
                          child: _labelValue(
                              'Travel', formatLabel(item.travelMode)),
                        ),
                      if (item.vehicleType != null)
                        Expanded(
                          child: _labelValue(
                              'Vehicle', formatLabel(item.vehicleType)),
                        ),
                      if (item.odometerReading != null)
                        Expanded(
                          child: _labelValue(
                            'Odometer',
                            '${item.odometerReading} → ${item.dayOverOdometerReading ?? '—'}',
                          ),
                        ),
                    ],
                  ),
                ],

                // Location
                if (item.visitLocation != null &&
                    item.visitLocation!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        item.visitLocation!,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],

                // Leave reason
                if (item.leaveReason != null &&
                    item.leaveReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Leave Reason: ${item.leaveReason}',
                      style: const TextStyle(
                          color: Color(0xFFE65100), fontSize: 12),
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Contact + View Images button
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      item.contactNo.isNotEmpty ? item.contactNo : '—',
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const Spacer(),
                    // View Images button
                    GestureDetector(
                      onTap: onViewImages,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library_outlined,
                                color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'View Images',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1A1A1A))),
          Text(label,
              style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: Colors.grey[200]);
  }

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF1A1A1A))),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Attendance Image Modal
// ─────────────────────────────────────────────

class _AttendanceImageModal extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final String date;
  final Future<AttendanceImages> Function(int, String) fetchImages;

  const _AttendanceImageModal({
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.fetchImages,
  });

  @override
  State<_AttendanceImageModal> createState() =>
      _AttendanceImageModalState();
}

class _AttendanceImageModalState extends State<_AttendanceImageModal> {
  AttendanceImages? _images;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final images =
          await widget.fetchImages(widget.employeeId, widget.date);
      setState(() {
        _images = images;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _imageLabel(String key) {
    const labels = {
      'check_in': 'Check In',
      'check_out': 'Check Out',
      'selfie': 'Selfie',
      'location': 'Location',
    };
    return labels[key] ?? key.replaceAll('_', ' ').toUpperCase();
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.photo_library_outlined,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.employeeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy')
                            .format(DateTime.parse(widget.date)),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
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
          ),

          // Body
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                        color: Color(0xFF1B5E20)),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image_not_supported_outlined,
                                color: Colors.grey, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No images available for this date',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : _images == null || _images!.images.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No images found',
                                style: TextStyle(color: Colors.grey)),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: _images!.images.entries
                                  .map(
                                    (entry) => _ImageTile(
                                      label: _imageLabel(entry.key),
                                      url: entry.value,
                                      onTap: () => _showFullImage(
                                          context, entry.value),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Image Tile inside modal
// ─────────────────────────────────────────────

class _ImageTile extends StatelessWidget {
  final String label;
  final String url;
  final VoidCallback onTap;

  const _ImageTile({
    required this.label,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
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
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey[100],
                  child: Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.grey[400], size: 40),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.fullscreen, size: 16),
              label: const Text('View Full'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E20),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}