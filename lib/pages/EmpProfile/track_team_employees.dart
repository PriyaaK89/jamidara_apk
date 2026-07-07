import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/storage_service.dart';
import '../../layout/main_layout.dart';
import '../../layout/app_router.dart';


class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latitude: double.tryParse(json['latitude'].toString()) ?? 0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0,
      recordedAt: DateTime.parse(json['recorded_at']).toLocal(),
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);

}

class LevelUserTrack {
  final int id;
  final String name;
  final String jobRole;

  LevelUserTrack({required this.id, required this.name, required this.jobRole});

  factory LevelUserTrack.fromJson(Map<String, dynamic> json) {
    return LevelUserTrack(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      jobRole: json['job_role'] ?? json['role_name'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) => other is LevelUserTrack && other.id == id;

  @override
  int get hashCode => id.hashCode;
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

Future<List<LevelUserTrack>> fetchUsersByLevel(int level) async {
  final base = await _baseUrl();
  final headers = await _authHeaders();
  final uri = Uri.parse('$base/users-by-level')
      .replace(queryParameters: {'level': level.toString()});
  debugPrint('fetchUsersByLevel → $uri');
  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    final List<dynamic> data = body['data'] ?? [];
    return data.map((e) => LevelUserTrack.fromJson(e)).toList();
  }
  throw Exception('Failed to load users (${response.statusCode})');
}

Future<List<RoutePoint>> fetchRoute(int employeeId, String date) async {
  final base = await _baseUrl();
  final headers = await _authHeaders();
  final uri = Uri.parse('$base/get-route').replace(
    queryParameters: {'employeeId': employeeId.toString(), 'date': date},
  );
  debugPrint('fetchRoute → $uri');
  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    final List<dynamic> data = decoded['data'] ?? [];
    return data.map((e) => RoutePoint.fromJson(e)).toList();
  }
  throw Exception('Failed to load route (${response.statusCode}): ${response.body}');
}

// ─────────────────────────────────────────────
// Distance & time helpers
// ─────────────────────────────────────────────

/// Haversine formula — returns distance in km
double _haversineDistance(LatLng a, LatLng b) {
  const R = 6371.0;
  final dLat = _deg2rad(b.latitude - a.latitude);
  final dLon = _deg2rad(b.longitude - a.longitude);
  final x = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(a.latitude)) *
          cos(_deg2rad(b.latitude)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(x), sqrt(1 - x));
  return R * c;
}

double _deg2rad(double deg) => deg * (pi / 180);

double _totalDistance(List<RoutePoint> points) {
  double total = 0;
  for (int i = 0; i < points.length - 1; i++) {
    total += _haversineDistance(points[i].latLng, points[i + 1].latLng);
  }
  return total;
}

String _travelTime(List<RoutePoint> points) {
  if (points.length < 2) return '—';
  final diff = points.last.recordedAt.difference(points.first.recordedAt);
  final h = diff.inHours;
  final m = diff.inMinutes % 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

// ─────────────────────────────────────────────
// Level config (same as team visit page)
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────

class TrackTeamPage extends StatefulWidget {
  final int myLevel;

  const TrackTeamPage({super.key, required this.myLevel});

  @override
  State<TrackTeamPage> createState() => _TrackTeamPageState();
}

class _TrackTeamPageState extends State<TrackTeamPage> {
  // ── filter state ──
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedLevelOption;
  LevelUserTrack? _selectedUser;

  // ── data ──
  late final List<Map<String, dynamic>> _subordinateOptions;
  List<LevelUserTrack> _levelUsers = [];
  List<RoutePoint> _routePoints = [];

  // ── loading / error ──
  bool _loadingUsers = false;
  bool _loadingRoute = false;
  String? _routeError;

  // ── map controller ──
  // final MapController _mapController = MapController();
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _subordinateOptions = getSubordinateLevelOptions(widget.myLevel);
  }

  // ── API calls ──
  Future<void> _onLevelChanged(Map<String, dynamic>? option) async {
    setState(() {
      _selectedLevelOption = option;
      _selectedUser = null;
      _levelUsers = [];
      _routePoints = [];
      _routeError = null;
    });

    if (option == null) return;

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

  Future<void> _onUserChanged(LevelUserTrack? user) async {
    setState(() {
      _selectedUser = user;
      _routePoints = [];
      _routeError = null;
    });
    if (user != null) await _loadRoute();
  }

  Future<void> _loadRoute() async {
    if (_selectedUser == null) return;
    setState(() {
      _loadingRoute = true;
      _routeError = null;
    });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final points = await fetchRoute(_selectedUser!.id, dateStr);
      setState(() => _routePoints = points);

      // Fit map to route bounds after load
      if (points.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitMap());
      }
    } catch (e) {
      setState(() => _routeError = e.toString());
    } finally {
      setState(() => _loadingRoute = false);
    }
  }

  void _fitMap() {
  if (_routePoints.isEmpty || _mapController == null) return;
  final lats = _routePoints.map((p) => p.latitude).toList();
  final lngs = _routePoints.map((p) => p.longitude).toList();

  final bounds = LatLngBounds(
    southwest: LatLng(lats.reduce(min) - 0.002, lngs.reduce(min) - 0.002),
    northeast: LatLng(lats.reduce(max) + 0.002, lngs.reduce(max) + 0.002),
  );

  _mapController!.animateCamera(
    CameraUpdate.newLatLngBounds(bounds, 40),
  );
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
      setState(() {
        _selectedDate = picked;
        _routePoints = [];
        _routeError = null;
      });
      if (_selectedUser != null) await _loadRoute();
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
void dispose() {
  _mapController?.dispose();
  super.dispose();
}
  // ── build ──
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 4,
      currentRoute: "track_team",
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
      child: Column(
        children: [
          _buildFilterPanel(),
          if (_routePoints.isNotEmpty) _buildStatsBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── filter panel ──
// ── filter panel ──
Widget _buildFilterPanel() {
  return Container(
    color: const Color(0xFFF5F7FA), // page background, breaks away from the green header
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small title row with icon instead of a big bold heading
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.route_rounded,
                    color: Color(0xFF1B5E20), size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Track Team Members',
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Date row
          _buildDateRow(),
          const SizedBox(height: 10),

          // Level + User dropdowns
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
  );
}

Widget _buildDateRow() {
  return GestureDetector(
    onTap: _pickDate,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7E8D8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              color: Color(0xFF1B5E20), size: 17),
          const SizedBox(width: 10),
          Text(
            DateFormat('dd MMM yyyy').format(_selectedDate),
            style: const TextStyle(
              color: Color(0xFF1B5E20),
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_drop_down, color: Color(0xFF1B5E20)),
        ],
      ),
    ),
  );
}

Widget _buildLevelDropdown() {
  return _styledDropdown<Map<String, dynamic>?>(
    hint: 'Select Level',
    value: _selectedLevelOption,
    items: [
      const DropdownMenuItem(value: null, child: Text('Select Level')),
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
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7E8D8)),
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF1B5E20)),
        ),
      ),
    );
  }

  return _styledDropdown<LevelUserTrack?>(
    hint: 'Select Member',
    value: _selectedUser,
    items: [
      const DropdownMenuItem(value: null, child: Text('Select Member')),
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
      color: const Color(0xFFF1F6F1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFD7E8D8)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        hint: Text(hint,
            style: const TextStyle(color: Colors.black45, fontSize: 13)),
        dropdownColor: Colors.white,
        style: const TextStyle(
            color: Color(0xFF1B5E20),
            fontSize: 13,
            fontWeight: FontWeight.w600),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1B5E20)),
        isExpanded: true,
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}

// ── stats bar ──
Widget _buildStatsBar() {
  final dist = _totalDistance(_routePoints);
  final time = _travelTime(_routePoints);
  final start = DateFormat('hh:mm a').format(_routePoints.first.recordedAt);
  final end = DateFormat('hh:mm a').format(_routePoints.last.recordedAt);

  return Container(
    color: const Color(0xFFF5F7FA),
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statChip(Icons.straighten, '${dist.toStringAsFixed(2)} km', 'Distance'),
          _vDivider(),
          _statChip(Icons.access_time, time, 'Travel Time'),
          _vDivider(),
          _statChip(Icons.play_arrow_rounded, start, 'Start'),
          _vDivider(),
          _statChip(Icons.stop_rounded, end, 'End'),
        ],
      ),
    ),
  );
}

Widget _vDivider() =>
    Container(width: 1, height: 28, color: const Color(0xFFE0E0E0));

Widget _statChip(IconData icon, String value, String label) {
  return Column(
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF1B5E20), size: 14),
          const SizedBox(width: 4),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: Colors.black45, fontSize: 10)),
    ],
  );
}
  // ── body ──
  Widget _buildBody() {
    // Initial state — no level selected yet
    if (_selectedLevelOption == null) {
      return _buildPlaceholder(
        icon: Icons.people_outline,
        message: 'Select a level to get started',
      );
    }

    // Level selected, no user yet
    if (_selectedUser == null) {
      return _buildPlaceholder(
        icon: Icons.person_search_outlined,
        message: 'Select a team member to view their route',
      );
    }

    // Loading route
    if (_loadingRoute) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1B5E20)),
            SizedBox(height: 12),
            Text('Loading route...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Route error
    if (_routeError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load route',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey[800])),
              const SizedBox(height: 6),
              Text(_routeError!,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRoute,
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

    // No data for this date
    if (_routePoints.isEmpty) {
      return _buildPlaceholder(
        icon: Icons.route_outlined,
        message:
            'No route data for ${_selectedUser!.name}\non ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
      );
    }

    // Show map
    return _buildMap();
  }

  Widget _buildPlaceholder({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
  final points = _routePoints.map((p) => p.latLng).toList();
  final start = points.first;
  final end = points.last;
  final center = LatLng(
    _routePoints.map((p) => p.latitude).reduce((a, b) => a + b) /
        _routePoints.length,
    _routePoints.map((p) => p.longitude).reduce((a, b) => a + b) /
        _routePoints.length,
  );

  return Stack(
    children: [
      GoogleMap(
        initialCameraPosition: CameraPosition(target: center, zoom: 14),
        onMapCreated: (controller) {
          _mapController = controller;
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitMap());
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: const Color(0xFF1B5E20),
            width: 4,
          ),
        },
        markers: {
          Marker(
            markerId: const MarkerId('start'),
            position: start,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: 'Start',
              snippet: DateFormat('hh:mm a')
                  .format(_routePoints.first.recordedAt),
            ),
          ),
          Marker(
            markerId: const MarkerId('end'),
            position: end,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'End',
              snippet: DateFormat('hh:mm a')
                  .format(_routePoints.last.recordedAt),
            ),
          ),
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),

      // Fit-to-route button
      Positioned(
        right: 12,
        bottom: 20,
        child: FloatingActionButton.small(
          onPressed: _fitMap,
          backgroundColor: const Color(0xFF1B5E20),
          child: const Icon(Icons.fit_screen, color: Colors.white),
        ),
      ),

      // Legend (unchanged)
      Positioned(
        left: 12,
        bottom: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _legendItem(const Color(0xFF1B5E20), Icons.play_arrow_rounded, 'Start'),
              const SizedBox(height: 4),
              _legendItem(const Color(0xFFB71C1C), Icons.stop_rounded, 'End'),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _mapMarker({
    required Color color,
    required IconData icon,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _legendItem(Color color, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}