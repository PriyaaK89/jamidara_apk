import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class MyTargetHistoryPage extends StatefulWidget {
  final int employeeId;
  const MyTargetHistoryPage({super.key, required this.employeeId});

  @override
  State<MyTargetHistoryPage> createState() => _MyTargetHistoryPageState();
}

class _MyTargetHistoryPageState extends State<MyTargetHistoryPage> {
  List<dynamic> historyList = [];
  bool isLoading = true;
  String? error;

  int currentPage = 1;
  final int perPage = 10;
  int totalPages = 1;
  int totalRecords = 0;

  String? statusFilter; // null = all, 'COMPLETED', 'EXPIRED'

  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color pageBg = Color(0xFFF4F6F5);

  static const Map<String, IconData> typeIcons = {
    "farmer": Icons.grass,
    "retailer": Icons.storefront_outlined,
    "distributor": Icons.local_shipping_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final res = await ApiService.getEmployeeVisitTargetHistory(
        token,
        widget.employeeId,
        status: statusFilter,
        page: currentPage,
        limit: perPage,
      );

      if (res["success"] == true) {
        final total = res["pagination"]?["total"] ?? 0;
        setState(() {
          historyList = res["data"] ?? [];
          totalRecords = total;
          totalPages = (total / perPage).ceil().clamp(1, 999999);
          isLoading = false;
        });
      } else {
        setState(() {
          error = res["message"] ?? "Failed to load history";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Something went wrong: $e";
        isLoading = false;
      });
    }
  }

  // Parses a plain "YYYY-MM-DD" string manually — avoids DateTime.parse's
  // UTC interpretation shifting the day depending on device timezone.
  String _formatDate(String? date) {
    if (date == null) return "-";
    final parts = date.split("-");
    if (parts.length == 3) {
      return "${parts[2]}/${parts[1]}/${parts[0]}";
    }
    return date;
  }

  int _overallPercent(List breakdown) {
    int totalTarget = 0;
    int totalAchieved = 0;
    for (final b in breakdown) {
      totalTarget += (b["target_value"] as num?)?.toInt() ?? 0;
      totalAchieved += (b["achieved"] as num?)?.toInt() ?? 0;
    }
    if (totalTarget == 0) return 0;
    return ((totalAchieved / totalTarget) * 100).clamp(0, 100).round();
  }

  Color _statusColor(String? status) {
    return status == "COMPLETED" ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
  }

  IconData _statusIcon(String? status) {
    return status == "COMPLETED" ? Icons.check_circle_outline : Icons.timer_off_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text("My Target History"),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildBody()),
          if (!isLoading && error == null && historyList.isNotEmpty) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: primaryGreen,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String?>(
                  value: statusFilter,
                  isDense: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text("All statuses")),
                    DropdownMenuItem(value: "COMPLETED", child: Text("Completed")),
                    DropdownMenuItem(value: "EXPIRED", child: Text("Expired")),
                  ],
                  onChanged: (val) {
                    setState(() {
                      statusFilter = val;
                      currentPage = 1;
                    });
                    _loadHistory();
                  },
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$totalRecords total",
                style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryGreen));
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: _loadHistory,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (historyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, size: 36, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            const Text(
              "No past target periods yet.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        itemCount: historyList.length,
        itemBuilder: (context, index) {
          final item = historyList[index];
          final assignment = item["assignment"];
          final breakdown = (item["breakdown"] as List?) ?? [];
          final byType = {for (var b in breakdown) b["visit_type"]: b};
          final overallPct = _overallPercent(breakdown);
          final status = assignment["status"];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_statusIcon(status), size: 18, color: _statusColor(status)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment["template_name"] ?? "-",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${_formatDate(assignment["period_start"])} - ${_formatDate(assignment["period_end"])}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status ?? "-",
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: ["farmer", "retailer", "distributor"].map((type) {
                    final data = byType[type];
                    final achieved = data?["achieved"] ?? 0;
                    final target = data?["target_value"] ?? 0;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAF8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(typeIcons[type], size: 16, color: primaryGreen),
                            const SizedBox(height: 5),
                            Text(
                              "$achieved/$target",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              type[0].toUpperCase() + type.substring(1),
                              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overallPct / 100,
                    minHeight: 7,
                    backgroundColor: Colors.grey.shade200,
                    color: overallPct >= 100 ? Colors.green : primaryGreen,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$overallPct% achieved",
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    if (assignment["completed_at"] != null)
                      Text(
                        "Completed ${_formatDate(assignment["completed_at"])}",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: currentPage > 1
                ? () {
                    setState(() => currentPage--);
                    _loadHistory();
                  }
                : null,
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
            label: const Text("Previous"),
            style: TextButton.styleFrom(foregroundColor: primaryGreen),
          ),
          Text(
            "Page $currentPage of $totalPages",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
          TextButton.icon(
            onPressed: currentPage < totalPages
                ? () {
                    setState(() => currentPage++);
                    _loadHistory();
                  }
                : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            label: const Text("Next"),
            style: TextButton.styleFrom(foregroundColor: primaryGreen),
          ),
        ],
      ),
    );
  }
}