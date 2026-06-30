import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_service.dart';
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

// ─────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────

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

  // ── lifecycle ──
  @override
  void initState() {
    super.initState();
    _subordinateOptions = getSubordinateLevelOptions(widget.myLevel);
    _loadVisits();
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
      onTabChange: (index) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AppRouter(
              employeeId: 0,
              token: '',
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
          summary: _visits[i],
          roleColor: _roleColor(_visits[i].roleName),
          selectedDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
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

  const _VisitCard({
    required this.summary,
    required this.roleColor,
    required this.selectedDate,
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
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: roleColor.withOpacity(0.12),
              child: Text(
                summary.name.isNotEmpty ? summary.name[0].toUpperCase() : '?',
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
                  Text(
                    summary.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _kInk,
                    ),
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
      ),
    );
  }
}