import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../layout/main_layout.dart';
import '../../layout/app_router.dart';
import '../EmpProfile/visit_details_modal.dart';

class HierarchyVisitSummary {
  final int id;
  final String name;
  final String roleName;
  final int totalVisits;
  final String contactNo;

  HierarchyVisitSummary({
    required this.id,
    required this.name,
    required this.roleName,
    required this.totalVisits,
    required this.contactNo,
  });

  factory HierarchyVisitSummary.fromJson(Map<String, dynamic> json) {
    return HierarchyVisitSummary(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      roleName: json['role_name'] ?? '',
      totalVisits: json['total_visits'] ?? 0,
      contactNo: json['contact_no'] ?? '',
    );
  }
}

class LevelUser {
  final int id;
  final String name;
  final String jobRole;

  LevelUser({required this.id, required this.name, required this.jobRole});

  factory LevelUser.fromJson(Map<String, dynamic> json) {
    return LevelUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      jobRole: json['job_role'] ?? json['role_name'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) => other is LevelUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

const List<Map<String, dynamic>> _allLevels = [
  {'level': 1, 'slug': 'zsm', 'label': 'ZSM'},
  {'level': 2, 'slug': 'rsm', 'label': 'RSM'},
  {'level': 3, 'slug': 'asm', 'label': 'ASM'},
  {'level': 4, 'slug': 'tsm', 'label': 'TSM'},
  {'level': 5, 'slug': 'so', 'label': 'SO'},
  {'level': 6, 'slug': 'fa', 'label': 'FA'},
];

List<Map<String, dynamic>> getSubordinateLevelOptions(int myLevel) {
  return _allLevels.where((l) => (l['level'] as int) > myLevel).toList();
}

// ── theme palette (green stays as an accent, not a wash) ──
const Color _kPrimaryGreen = Color(0xFF2E7D32);
const Color _kDarkGreen = Color(0xFF1B5E20);
const Color _kBg = Color(0xFFF4F6F5);
const Color _kCard = Colors.white;
const Color _kInk = Color(0xFF1A1A1A);
const Color _kSubInk = Color(0xFF6B7280);
const Color _kBorder = Color(0xFFE6E8EA);

Color _roleColor(String roleNameOrSlug) {
  final r = roleNameOrSlug.toLowerCase();
  if (r.contains('zsm') || r.contains('zonal')) return const Color(0xFF6A1B9A);
  if (r.contains('rsm') || r.contains('regional'))
    return const Color(0xFF1565C0);
  if (r.contains('asm') || r.contains('area')) return const Color(0xFF00838F);
  if (r.contains('tsm') || r.contains('territory'))
    return const Color(0xFFEF6C00);
  if (r.contains('so') || r.contains('sales off'))
    return const Color(0xFF2E7D32);
  if (r.contains('fa') || r.contains('field')) return const Color(0xFFC62828);
  return const Color(0xFF607D8B);
}

/// Icon for a visit_type — falls back to a generic pin if the type
/// doesn't match any of the known ones.
IconData _visitTypeIcon(String visitType) {
  final t = visitType.toLowerCase();
  if (t.contains('farmer')) return Icons.grass_rounded;
  if (t.contains('retailer')) return Icons.storefront_rounded;
  if (t.contains('distributor')) return Icons.local_shipping_rounded;
  if (t.contains('dealer')) return Icons.storefront_outlined;
  return Icons.place_rounded;
}

/// Capitalizes just the first letter — "farmer" → "Farmer",
/// "RETAILER" → "Retailer". Leaves already-clean labels untouched.
String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}

/// Parses a plain "YYYY-MM-DD" (or "YYYY-MM-DD HH:mm:ss") string manually
/// — avoids DateTime.parse's UTC interpretation shifting the day
/// depending on device timezone. Returns "-" if the value is missing.
String _formatDate(String? date) {
  if (date == null || date.isEmpty) return '-';
  final datePart = date.split(' ').first; // strip time if present
  final parts = datePart.split('-');
  if (parts.length == 3) {
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
  return date;
}

Future<String> _baseUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('FLUTTER_BASE_URL') ?? '';
}

Future<Map<String, String>> _authHeaders() async {
  final token = await StorageService.getToken();
  return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
}

Future<List<HierarchyVisitSummary>> fetchHierarchyVisits({
  required String date,
  int? level,
  int? userId,
}) async {
  final base = await _baseUrl();
  final headers = await _authHeaders();

  final params = <String, String>{'date': date};
  if (level != null) params['level'] = level.toString();
  if (userId != null) params['user_id'] = userId.toString();

  final uri = Uri.parse(
    '$base/hierarchy-visits',
  ).replace(queryParameters: params);
  debugPrint('fetchHierarchyVisits → $uri');

  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    final List<dynamic> data = decoded['data'] ?? [];
    return data.map((e) => HierarchyVisitSummary.fromJson(e)).toList();
  }
  throw Exception(
    'Failed to load hierarchy visits (${response.statusCode}): ${response.body}',
  );
}

Future<List<LevelUser>> fetchUsersByLevel(int level) async {
  final base = await _baseUrl();
  final headers = await _authHeaders();

  final uri = Uri.parse(
    '$base/users-by-level',
  ).replace(queryParameters: {'level': level.toString()});
  debugPrint('fetchUsersByLevel → $uri');

  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    final List<dynamic> data = body['data'] ?? [];
    return data.map((e) => LevelUser.fromJson(e)).toList();
  }
  throw Exception(
    'Failed to load users (${response.statusCode}): ${response.body}',
  );
}

/// Fetches the current active target (target vs achieved by visit_type)
/// for a single employee, via ApiService.getEmployeeTargetProgress.
/// Returns null if that employee has no active assignment right now, or
/// if the call didn't succeed.
Future<EmployeeActiveTarget?> fetchEmployeeTargetProgress(int userId) async {
  final token = await StorageService.getToken();
  final result = await ApiService.getEmployeeTargetProgress(
    token: token ?? '',
    employeeId: userId,
  );

  debugPrint('fetchEmployeeTargetProgress($userId) → $result');

  if (result['success'] == true) {
    final List<dynamic> data = result['data'] ?? [];
    if (data.isEmpty) return null; // no active assignment for this employee
    return EmployeeActiveTarget.fromJson(data.first as Map<String, dynamic>);
  }

  throw Exception(
    result['message']?.toString() ?? 'Failed to load target progress',
  );
}

class EmployeeActiveTarget {
  final int employeeId;
  final int totalTarget;
  final int totalAchieved;
  final String? periodStart;
  final String? periodEnd;
  final List<VisitTypeProgress> breakdown;

  EmployeeActiveTarget({
    required this.employeeId,
    required this.totalTarget,
    required this.totalAchieved,
    required this.periodStart,
    required this.periodEnd,
    required this.breakdown,
  });

  factory EmployeeActiveTarget.fromJson(Map<String, dynamic> json) {
    final targetsList = (json['targets'] as List?) ?? [];

    // period_start / period_end come back on each individual target row
    // (repeated per visit_type, but identical across all rows for the
    // same assignment) — so just take them off the first row.
    String? periodStart;
    String? periodEnd;
    if (targetsList.isNotEmpty) {
      final first = targetsList.first as Map<String, dynamic>;
      periodStart = first['period_start']?.toString();
      periodEnd = first['period_end']?.toString();
    }

    return EmployeeActiveTarget(
      employeeId: json['id'] ?? 0,
      totalTarget: json['total_target'] ?? 0,
      totalAchieved: json['total_achieved'] ?? 0,
      periodStart: periodStart,
      periodEnd: periodEnd,
      breakdown: targetsList
          .map((e) => VisitTypeProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VisitTypeProgress {
  final String visitType;
  final int targetValue;
  final int achieved;

  VisitTypeProgress({
    required this.visitType,
    required this.targetValue,
    required this.achieved,
  });

  factory VisitTypeProgress.fromJson(Map<String, dynamic> json) {
    return VisitTypeProgress(
      visitType: json['visit_type'] ?? '',
      targetValue: json['target_value'] ?? 0,
      achieved: json['achieved'] ?? 0,
    );
  }
}

/// Drop-in widget showing an employee's current running target — placed
/// above the employee row in _VisitCard (and can also be reused at the
/// top of visit_details_modal.dart's content), passing in the employee's
/// userId.
///
/// Always renders something: the real progress card, an explicit
/// "no active target" card, or an error card — never disappears.
class EmployeeTargetSummaryCard extends StatefulWidget {
  final int userId;

  const EmployeeTargetSummaryCard({super.key, required this.userId});

  @override
  State<EmployeeTargetSummaryCard> createState() =>
      _EmployeeTargetSummaryCardState();
}

class _EmployeeTargetSummaryCardState extends State<EmployeeTargetSummaryCard> {
  bool _loading = true;
  EmployeeActiveTarget? _target;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EmployeeTargetSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      setState(() {
        _loading = true;
        _target = null;
        _error = null;
      });
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final result = await fetchEmployeeTargetProgress(widget.userId);
      if (!mounted) return;
      setState(() => _target = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _kPrimaryGreen,
            ),
          ),
        ),
      );
    }

    // Real fetch error — show it, don't hide it.
    if (_error != null) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Could not load target',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No active assignment for this employee.
    if (_target == null) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flag_outlined,
                size: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No active visit target assigned',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Real target with progress.
    final t = _target!;
    final progress = t.totalTarget == 0
        ? 0.0
        : (t.totalAchieved / t.totalTarget).clamp(0, 1).toDouble();
    final pct = (progress * 100).round();
    final isComplete = t.totalTarget > 0 && t.totalAchieved >= t.totalTarget;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kBg, _kBg.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── header row: icon, title + period dates, % badge ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (isComplete ? Colors.green : _kDarkGreen)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  isComplete
                      ? Icons.verified_rounded
                      : Icons.track_changes_rounded,
                  size: 16,
                  color: isComplete ? Colors.green[700] : _kDarkGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Target',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 10, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatDate(t.periodStart)} - ${_formatDate(t.periodEnd)}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: (isComplete ? Colors.green : _kPrimaryGreen)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: isComplete ? Colors.green[700] : _kDarkGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── progress bar with achieved/total label ──
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(
                isComplete ? Colors.green[600]! : _kPrimaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${t.totalAchieved} / ${t.totalTarget} visits',
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (t.breakdown.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: _kBorder),
            const SizedBox(height: 10),

            // ── per visit-type tiles, laid out in an even grid so they
            // never wrap unevenly (e.g. 2 in one row + 1 alone below) ──
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                // Up to 3 columns per row; fewer columns if there are
                // fewer than 3 visit types so tiles don't stretch oddly.
                final columns = t.breakdown.length >= 3 ? 3 : t.breakdown.length;
                final tileWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: t.breakdown.map((b) {
                    final done = b.targetValue > 0 && b.achieved >= b.targetValue;
                    return SizedBox(
                      width: tileWidth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: done
                                ? Colors.green.withOpacity(0.35)
                                : _kBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              _visitTypeIcon(b.visitType),
                              size: 15,
                              color: done ? Colors.green[700] : _kDarkGreen,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${b.achieved}/${b.targetValue}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: done ? Colors.green[700] : _kInk,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _capitalize(b.visitType),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: _kSubInk,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class TeamVisitReportPage extends StatefulWidget {
  final int myLevel;

  const TeamVisitReportPage({super.key, required this.myLevel});

  @override
  State<TeamVisitReportPage> createState() => _TeamVisitReportPageState();
}

class _TeamVisitReportPageState extends State<TeamVisitReportPage> {
  // ── filter state ──
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedLevelOption;
  LevelUser? _selectedUser;

  // ── data ──
  late final List<Map<String, dynamic>> _subordinateOptions;
  List<LevelUser> _levelUsers = [];
  List<HierarchyVisitSummary> _visits = [];

  // ── loading / error ──
  bool _loadingVisits = false;
  bool _loadingUsers = false;
  String? _error;

  // ── the logged-in user's own id, so their own row in the list can be
  // labelled "(My Visits)" instead of looking like just another team
  // member ──
  int? _myEmployeeId;

  // ── lifecycle ──
  @override
  void initState() {
    super.initState();
    _subordinateOptions = getSubordinateLevelOptions(widget.myLevel);
    _loadVisits();
    _loadMyEmployeeId();
  }

  Future<void> _loadMyEmployeeId() async {
    final id = await StorageService.getEmployeeId();
    if (!mounted) return;
    setState(() => _myEmployeeId = id);
  }

  // ── API calls ──
  Future<void> _loadVisits() async {
    setState(() {
      _loadingVisits = true;
      _error = null;
    });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final results = await fetchHierarchyVisits(
        date: dateStr,
        level: _selectedLevelOption?['level'] as int?,
        userId: _selectedUser?.id,
      );
      setState(() => _visits = results);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingVisits = false);
    }
  }

  Future<void> _onLevelChanged(Map<String, dynamic>? option) async {
    setState(() {
      _selectedLevelOption = option;
      _selectedUser = null;
      _levelUsers = [];
    });

    _loadVisits();

    if (option != null) {
      setState(() => _loadingUsers = true);
      try {
        final users = await fetchUsersByLevel(option['level'] as int);
        setState(() => _levelUsers = users);
      } catch (e) {
        _showSnack('Could not load users: $e');
      } finally {
        setState(() => _loadingUsers = false);
      }
    }
  }

  Future<void> _onUserChanged(LevelUser? user) async {
    setState(() => _selectedUser = user);
    _loadVisits();
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
            primary: _kDarkGreen,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadVisits();
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _indexToRoute(int index) {
    switch (index) {
      case 0:
        return "dashboard";
      case 1:
        return "attendance";
      case 2:
        return "visit";
      case 3:
        return "order";
      case 4:
        return "more";
      default:
        return "dashboard";
    }
  }

  // ── build ──
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 4,
      currentRoute: "team_visit_report",
      isOrderSubPageOpen: false,
      onTabChange: (index) async {
        final token = await StorageService.getToken();
        final employeeId = await StorageService.getEmployeeId();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AppRouter(
              employeeId: employeeId ?? 0,
              token: token ?? '',
              initialRoute: _indexToRoute(index),
            ),
          ),
        );
      },
      child: Container(
        color: _kBg,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterPanel(),
            _buildSummaryBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── header ──
  Widget _buildHeader() {
    return Container(
      color: _kCard,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _kPrimaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: _kDarkGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Team Visit Report',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _kInk,
            ),
          ),
        ],
      ),
    );
  }

  // ── filter panel ──
  Widget _buildFilterPanel() {
    return Container(
      color: _kCard,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
    );
  }

  Widget _buildDateRow() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: _kPrimaryGreen,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('dd MMM yyyy').format(_selectedDate),
              style: const TextStyle(
                color: _kInk,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
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
          (opt) =>
              DropdownMenuItem(value: opt, child: Text(opt['label'] as String)),
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
          color: _kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _kPrimaryGreen,
            ),
          ),
        ),
      );
    }

    return _styledDropdown<LevelUser?>(
      hint: 'All Users',
      value: _selectedUser,
      items: [
        const DropdownMenuItem(value: null, child: Text('All Users')),
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
        color: _kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(color: _kInk, fontSize: 13),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── summary bar ──
  Widget _buildSummaryBar() {
    final total = _visits.fold<int>(0, (sum, v) => sum + v.totalVisits);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kDarkGreen, _kPrimaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kPrimaryGreen.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryChip(Icons.people_outline, '${_visits.length}', 'Members'),
          Container(
            height: 28,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withOpacity(0.25),
          ),
          _summaryChip(Icons.flag_outlined, '$total', 'Total Visits'),
          const Spacer(),
          if (_selectedLevelOption != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _selectedLevelOption!['label'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // ── body ──
  Widget _buildBody() {
    if (_loadingVisits) {
      return const Center(
        child: CircularProgressIndicator(color: _kPrimaryGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Failed to load visits',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadVisits,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kDarkGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kPrimaryGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_walk_outlined,
                size: 46,
                color: _kPrimaryGreen.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No visits on ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
              style: const TextStyle(
                color: _kSubInk,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _kPrimaryGreen,
      onRefresh: _loadVisits,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _visits.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _VisitCard(
          key: ValueKey(_visits[i].id),
          summary: _visits[i],
          roleColor: _roleColor(_visits[i].roleName),
          selectedDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
          isMe: _myEmployeeId != null && _visits[i].id == _myEmployeeId,
        ),
      ),
    );
  }
} // ← END of _TeamVisitReportPageState

// ─────────────────────────────────────────────
// Visit Card
// ─────────────────────────────────────────────

class _VisitCard extends StatelessWidget {
  final HierarchyVisitSummary summary;
  final Color roleColor;
  final String selectedDate;
  final bool isMe;

  const _VisitCard({
    super.key,
    required this.summary,
    required this.roleColor,
    required this.selectedDate,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Employee row: avatar, name/role/phone, visit count ──
            // shown first so the person's identity is the first thing
            // seen, with their target progress following underneath.
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: roleColor.withOpacity(0.12),
                  child: Text(
                    summary.name.isNotEmpty
                        ? summary.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + role badge + contact
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              summary.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _kInk,
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _kPrimaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'My Visits',
                                style: TextStyle(
                                  color: _kDarkGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          summary.roleName,
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (summary.contactNo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              summary.contactNo,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Visit count badge
                GestureDetector(
                  onTap: () {
                    showVisitDetailsModal(
                      context,
                      userId: summary.id,
                      employeeName: summary.name,
                      totalVisits: summary.totalVisits,
                      date: selectedDate,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: summary.totalVisits > 0
                          ? _kDarkGreen
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${summary.totalVisits}',
                          style: TextStyle(
                            color: summary.totalVisits > 0
                                ? Colors.white
                                : Colors.grey[500],
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'visits',
                          style: TextStyle(
                            color: summary.totalVisits > 0
                                ? Colors.white70
                                : Colors.grey[400],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: _kBorder),
            const SizedBox(height: 12),

            // ── Current target progress, shown below the employee row ──
            EmployeeTargetSummaryCard(
              key: ValueKey('target_${summary.id}'),
              userId: summary.id,
            ),
          ],
        ),
      ),
    );
  }
}