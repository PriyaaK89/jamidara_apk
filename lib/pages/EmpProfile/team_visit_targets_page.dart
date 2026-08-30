import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../layout/main_layout.dart';
import '../../layout/app_router.dart';
import './team_visit_report_page.dart'; // reuse LevelUser / getSubordinateLevelOptions / fetchUsersByLevel

// ── models ──

class TargetDetail {
  final int assignmentId;
  final String visitType;
  final int targetValue;
  final int achieved;
  final String? periodStart;
  final String? periodEnd;

  TargetDetail({
    required this.assignmentId,
    required this.visitType,
    required this.targetValue,
    required this.achieved,
    this.periodStart,
    this.periodEnd,
  });

  double get progress =>
      targetValue == 0 ? 0 : (achieved / targetValue).clamp(0, 1).toDouble();

  factory TargetDetail.fromJson(Map<String, dynamic> json) {
    return TargetDetail(
      assignmentId: json['assignment_id'] ?? 0,
      visitType: json['visit_type'] ?? '',
      targetValue: json['target_value'] ?? 0,
      achieved: json['achieved'] ?? 0,
      periodStart: json['period_start'],
      periodEnd: json['period_end'],
    );
  }
}

class TeamTargetSummary {
  final int id;
  final String name;
  final String contactNo;
  final String roleName;
  final int level;
  final int totalTarget;
  final int totalAchieved;
  final List<TargetDetail> targets;

  TeamTargetSummary({
    required this.id,
    required this.name,
    required this.contactNo,
    required this.roleName,
    required this.level,
    required this.totalTarget,
    required this.totalAchieved,
    required this.targets,
  });

  double get progress =>
      totalTarget == 0 ? 0 : (totalAchieved / totalTarget).clamp(0, 1);

  factory TeamTargetSummary.fromJson(Map<String, dynamic> json) {
    return TeamTargetSummary(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      contactNo: json['contact_no'] ?? '',
      roleName: json['role_name'] ?? '',
      level: json['level'] ?? 0,
      totalTarget: json['total_target'] ?? 0,
      totalAchieved: json['total_achieved'] ?? 0,
      targets: ((json['targets'] as List?) ?? [])
          .map((e) => TargetDetail.fromJson(e))
          .toList(),
    );
  }
}

// ── theme (matches TeamVisitReportPage, extended with status colors) ──
const Color _kPrimaryGreen = Color(0xFF2E7D32);
const Color _kDarkGreen = Color(0xFF1B5E20);
const Color _kBg = Color(0xFFF4F6F5);
const Color _kCard = Colors.white;
const Color _kInk = Color(0xFF1A1A1A);
const Color _kSubInk = Color(0xFF6B7280);
const Color _kBorder = Color(0xFFE6E8EA);
const Color _kAmber = Color(0xFFEF6C00);
const Color _kRed = Color(0xFFC62828);

Color _roleColor(String roleNameOrSlug) {
  final r = roleNameOrSlug.toLowerCase();
  if (r.contains('zsm') || r.contains('zonal')) return const Color(0xFF6A1B9A);
  if (r.contains('rsm') || r.contains('regional')) return const Color(0xFF1565C0);
  if (r.contains('asm') || r.contains('area')) return const Color(0xFF00838F);
  if (r.contains('tsm') || r.contains('territory')) return const Color(0xFFEF6C00);
  if (r.contains('so') || r.contains('sales off')) return const Color(0xFF2E7D32);
  if (r.contains('fa') || r.contains('field')) return const Color(0xFFC62828);
  return const Color(0xFF607D8B);
}

// Status color driven by how close a target is to completion —
// gives an at-a-glance read on team performance instead of a single flat green.
Color _progressColor(double progress) {
  if (progress >= 0.75) return _kPrimaryGreen;
  if (progress >= 0.4) return _kAmber;
  return _kRed;
}

// Capitalizes the first letter of every word — e.g. "farmer visit" -> "Farmer Visit".
String _titleCase(String text) {
  if (text.trim().isEmpty) return text;
  return text
      .split(' ')
      .map((word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

// Formats an ISO-ish date string ("2026-08-01") into a short readable form ("01 Aug 2026").
// Falls back to the raw string if it can't be parsed.
String _formatDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}';
}

IconData _visitTypeIcon(String visitType) {
  final v = visitType.toLowerCase();
  if (v.contains('call')) return Icons.call_outlined;
  if (v.contains('order')) return Icons.receipt_long_outlined;
  if (v.contains('retail') || v.contains('shop') || v.contains('store')) {
    return Icons.storefront_outlined;
  }
  if (v.contains('distributor') || v.contains('dist')) {
    return Icons.local_shipping_outlined;
  }
  return Icons.place_outlined;
}

class TeamTargetsPage extends StatefulWidget {
  final int myLevel;

  const TeamTargetsPage({super.key, required this.myLevel});

  @override
  State<TeamTargetsPage> createState() => _TeamTargetsPageState();
}

class _TeamTargetsPageState extends State<TeamTargetsPage> {
  Map<String, dynamic>? _selectedLevelOption;
  LevelUser? _selectedUser;

  late final List<Map<String, dynamic>> _subordinateOptions;
  List<LevelUser> _levelUsers = [];
  List<TeamTargetSummary> _teamTargets = [];

  bool _loading = false;
  bool _loadingUsers = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subordinateOptions = getSubordinateLevelOptions(widget.myLevel);
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await StorageService.getToken();
      final result = await ApiService.getTeamTargets(
        token: token ?? '',
        level: _selectedLevelOption?['level'] as int?,
        userId: _selectedUser?.id,
      );

      if (result['success'] == true) {
        final List<dynamic> data = result['data'] ?? [];
        setState(() {
          _teamTargets = data.map((e) => TeamTargetSummary.fromJson(e)).toList();
        });
      } else {
        setState(() => _error = result['message']?.toString() ?? 'Failed to load');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _onLevelChanged(Map<String, dynamic>? option) async {
    setState(() {
      _selectedLevelOption = option;
      _selectedUser = null;
      _levelUsers = [];
    });

    _loadTargets();

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
    _loadTargets();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 4,
      currentRoute: "team_targets",
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
            const SizedBox(height: 10),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimaryGreen.withOpacity(0.16), _kPrimaryGreen.withOpacity(0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.track_changes_rounded, color: _kDarkGreen, size: 21),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Targets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kInk, letterSpacing: -0.3),
                ),
                SizedBox(height: 2),
                Text(
                  'Track visit target achievement across your team',
                  style: TextStyle(fontSize: 12, color: _kSubInk),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loading ? null : _loadTargets,
            icon: AnimatedRotation(
              turns: _loading ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: Icon(Icons.refresh_rounded, color: _loading ? Colors.grey[400] : _kDarkGreen),
            ),
            tooltip: 'Refresh',
            splashRadius: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: _kCard,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(child: _buildLevelDropdown()),
          if (_selectedLevelOption != null) ...[
            const SizedBox(width: 10),
            Expanded(child: _buildUserDropdown()),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelDropdown() {
    return _styledDropdown<Map<String, dynamic>?>(
      hint: 'All Levels',
      icon: Icons.layers_outlined,
      value: _selectedLevelOption,
      items: [
        const DropdownMenuItem(value: null, child: Text('All Levels')),
        ..._subordinateOptions.map(
          (opt) => DropdownMenuItem(value: opt, child: Text(opt['label'] as String)),
        ),
      ],
      onChanged: _onLevelChanged,
    );
  }

  Widget _buildUserDropdown() {
    if (_loadingUsers) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimaryGreen),
          ),
        ),
      );
    }

    return _styledDropdown<LevelUser?>(
      hint: 'All Users',
      icon: Icons.person_outline_rounded,
      value: _selectedUser,
      items: [
        const DropdownMenuItem(value: null, child: Text('All Users')),
        ..._levelUsers.map((u) => DropdownMenuItem(value: u, child: Text(u.name))),
      ],
      onChanged: _onUserChanged,
    );
  }

  Widget _styledDropdown<T>({
    required String hint,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(hint, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(color: _kInk, fontSize: 13, fontWeight: FontWeight.w500),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final totalTarget = _teamTargets.fold<int>(0, (sum, t) => sum + t.totalTarget);
    final totalAchieved = _teamTargets.fold<int>(0, (sum, t) => sum + t.totalAchieved);
    final overallProgress = totalTarget == 0 ? 0.0 : (totalAchieved / totalTarget).clamp(0, 1);
    final progressPct = (overallProgress * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kDarkGreen, _kPrimaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _kPrimaryGreen.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryChip(Icons.people_alt_rounded, '${_teamTargets.length}', 'Members'),
              Container(
                height: 30,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white.withOpacity(0.22),
              ),
              _summaryChip(Icons.flag_rounded, '$totalAchieved/$totalTarget', 'Achieved'),
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
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overallProgress.toDouble(),
                    minHeight: 7,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$progressPct%',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String value, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1.1)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _kPrimaryGreen, strokeWidth: 2.6),
            SizedBox(height: 14),
            Text('Loading targets…', style: TextStyle(color: _kSubInk, fontSize: 12.5)),
          ],
        ),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _kRed.withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, color: _kRed, size: 38),
              ),
              const SizedBox(height: 16),
              Text('Failed to load targets',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.grey[800])),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12.5)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadTargets,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kDarkGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_teamTargets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _kPrimaryGreen.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.track_changes_outlined, size: 48, color: _kPrimaryGreen.withOpacity(0.55)),
            ),
            const SizedBox(height: 16),
            const Text('No targets found', style: TextStyle(color: _kInk, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              'Try a different level or user filter',
              style: TextStyle(color: _kSubInk, fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _kPrimaryGreen,
      onRefresh: _loadTargets,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
        itemCount: _teamTargets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 11),
        itemBuilder: (ctx, i) => _TargetCard(
          summary: _teamTargets[i],
          roleColor: _roleColor(_teamTargets[i].roleName),
        ),
      ),
    );
  }
}

// ── target card (expandable to show per-visit-type breakdown) ──

class _TargetCard extends StatefulWidget {
  final TeamTargetSummary summary;
  final Color roleColor;

  const _TargetCard({required this.summary, required this.roleColor});

  @override
  State<_TargetCard> createState() => _TargetCardState();
}

class _TargetCardState extends State<_TargetCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final statusColor = _progressColor(s.progress);
    final pct = (s.progress * 100).round();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _expanded ? widget.roleColor.withOpacity(0.35) : _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_expanded ? 0.06 : 0.03),
            blurRadius: _expanded ? 14 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: s.targets.isEmpty ? null : () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: widget.roleColor.withOpacity(0.12),
                        child: Text(
                          s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                          style: TextStyle(color: widget.roleColor, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: _kCard, width: 2),
                          ),
                          child: const SizedBox(width: 6, height: 6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: _kInk),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s.roleName,
                            style: TextStyle(color: widget.roleColor, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: s.progress,
                                  minHeight: 6,
                                  backgroundColor: _kBg,
                                  valueColor: AlwaysStoppedAnimation(statusColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$pct%',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${s.totalAchieved}/${s.totalTarget}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kInk),
                      ),
                      if (s.targets.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: (_expanded && s.targets.isNotEmpty)
                  ? Column(
                      children: [
                        const Divider(height: 24, color: _kBorder),
                        ...s.targets.map((t) {
                          final periodText = (t.periodStart != null && t.periodStart!.isNotEmpty)
                              ? '${_formatDate(t.periodStart)}'
                                  '${(t.periodEnd != null && t.periodEnd!.isNotEmpty) ? ' – ${_formatDate(t.periodEnd)}' : ''}'
                              : '';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _kBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(_visitTypeIcon(t.visitType), size: 13, color: _kSubInk),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _titleCase(t.visitType),
                                        style: const TextStyle(fontSize: 12.5, color: _kInk, fontWeight: FontWeight.w500),
                                      ),
                                      if (periodText.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_outlined, size: 10, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              periodText,
                                              style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 46,
                                  height: 4,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: _kBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: t.progress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _progressColor(t.progress),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${t.achieved}/${t.targetValue}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kInk),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}