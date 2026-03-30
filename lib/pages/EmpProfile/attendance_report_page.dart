import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../pages/profile_menu_page.dart';

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  List attendance = [];
  bool isLoading = true;

  int page = 1;
  int totalPages = 1;
  int limit = 10;

  String? startDate;
  String? endDate;

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

Future<void> fetchAttendance() async {
  setState(() => isLoading = true);

  final res = await ApiService.getAttendanceReport(
    page: page,
    limit: limit,
    startDate: startDate,
    endDate: endDate,
  );

  try {
    setState(() {
      attendance = res["attendance"] ?? [];

      totalPages = res["pagination"]?["total_pages"] ?? 1;
    });
  } catch (e) {
    print("Error parsing attendance: $e");
  }

  setState(() => isLoading = false);
}

  /// 🔹 Header (Same as Visit Page)
  Widget buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileMenuPage(
                  clearSavedCredentialsOnLogout: false,
                ),
              ),
            );
          },
          child: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
        ),
        const SizedBox(width: 8),
        const Text(
          "Attendance Report",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  /// 🔹 Date Picker
  Future<void> pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      String formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

      setState(() {
        if (isStart) {
          startDate = formatted;
        } else {
          endDate = formatted;
        }
        page = 1;
      });

      fetchAttendance();
    }
  }

  String formatDate(String? date) {
  if (date == null) return "-";

  final utcDate = DateTime.parse(date);
  final localDate = utcDate.toLocal(); // converts to IST

  return "${localDate.day.toString().padLeft(2, '0')}-"
         "${localDate.month.toString().padLeft(2, '0')}-"
         "${localDate.year}";
}

String formatTime(String? time) {
  if (time == null) return "-";

  try {
    final parts = time.split(":");
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    final dt = DateTime(0, 0, 0, hour, minute);

    return TimeOfDay.fromDateTime(dt).format(context);
  } catch (e) {
    return time;
  }
}

  /// 🔹 Filters (Same UI as Visit Page)
  Widget buildFilters() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => pickDate(true),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: "From Date",
                border: OutlineInputBorder(),
              ),
              child: Text(startDate ?? "Select"),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () => pickDate(false),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: "To Date",
                border: OutlineInputBorder(),
              ),
              child: Text(endDate ?? "Select"),
            ),
          ),
        ),
      ],
    );
  }

  /// 🔹 Table (Same Design as Visit Page)
  Widget buildTable() {
    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notif) => notif.depth == 1,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              headingRowColor:
                  MaterialStateProperty.all(const Color(0xFFE8F5E9)),
              columns: const [
                DataColumn(label: Text("No.")),
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Check In")),
                DataColumn(label: Text("Check Out")),
                DataColumn(label: Text("Status")),
              ],
              rows: List.generate(attendance.length, (index) {
                final item = attendance[index];
                final serialNumber = ((page - 1) * limit) + index + 1;

                return DataRow(
                  cells: [
                    DataCell(Text(serialNumber.toString())),
                    DataCell(Text(
                      item["attendance_date"]?.toString().substring(0, 10) ??
                          "-",
                    )),
                    DataCell(Text(formatTime(item["check_in_time"]))),
DataCell(Text(formatTime(item["check_out_time"]))),
                    DataCell(Text(item["status"] ?? "-")),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Pagination (Same as Visit Page)
  Widget buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: page > 1
              ? () {
                  setState(() => page--);
                  fetchAttendance();
                }
              : null,
          child: const Text("Prev"),
        ),
        const SizedBox(width: 10),
        Text("Page $page of $totalPages"),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: page < totalPages
              ? () {
                  setState(() => page++);
                  fetchAttendance();
                }
              : null,
          child: const Text("Next"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileMenuPage(
              clearSavedCredentialsOnLogout: false,
            ),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              buildHeader(),
              const SizedBox(height: 12),

              buildFilters(),
              const SizedBox(height: 10),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : attendance.isEmpty
                        ? const Center(child: Text("No attendance found"))
                        : buildTable(),
              ),

              const SizedBox(height: 10),

              buildPagination(),
            ],
          ),
        ),
      ),
    );
  }
}