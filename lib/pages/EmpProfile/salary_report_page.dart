import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../profile_menu_page.dart';

class SalaryReportPage extends StatefulWidget {
  const SalaryReportPage({super.key});

  @override
  State<SalaryReportPage> createState() => _SalaryReportPageState();
}

class _SalaryReportPageState extends State<SalaryReportPage> {
  List salary = [];
  bool isLoading = true;

  int page = 1;
  int totalPages = 1;
  int limit = 10;

  String? startDate;
  String? endDate;

  @override
  void initState() {
    super.initState();
    fetchSalary();
  }

  Future<void> fetchSalary() async {
    setState(() => isLoading = true);

    final res = await ApiService.getSalaryReport(
      page: page,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );

    try {
      setState(() {
        salary = res["data"] ?? [];
        totalPages = res["totalPages"] ?? 1;
      });
    } catch (e) {
      print("Error parsing salary: $e");
    }

    setState(() => isLoading = false);
  }

  /// 🔹 Header
  Widget buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileMenuPage(),
              ),
            );
          },
          child: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
        ),
        const SizedBox(width: 8),
        const Text(
          "Salary Report",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  String formatDate(String? date) {
  if (date == null) return "-";

  final utcDate = DateTime.parse(date);
  final localDate = utcDate.toLocal();

  return "${localDate.day.toString().padLeft(2, '0')}-"
         "${localDate.month.toString().padLeft(2, '0')}-"
         "${localDate.year}";
}

Color getStatusColor(String type) {
  switch (type) {
    case "full":
      return Colors.green;
    case "half":
      return Colors.orange;
    default:
      return Colors.grey;
  }
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

      fetchSalary();
    }
  }

  String formatCurrency(String? value) {
  if (value == null) return "₹ 0";

  final numVal = double.tryParse(value) ?? 0;
  return "₹ ${numVal.toStringAsFixed(2)}";
}

  ///  Filters
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

  ///  Table
Widget buildTable() {
  return Scrollbar(
    thumbVisibility: true,
    child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          headingRowColor:
              MaterialStateProperty.all(const Color(0xFFE8F5E9)),
          columns: const [
            DataColumn(label: Text("No.")),
            DataColumn(label: Text("Date")),
            DataColumn(label: Text("Type")),
            DataColumn(label: Text("Hours")),
            DataColumn(label: Text("Per Day")),
            DataColumn(label: Text("TA")),
            DataColumn(label: Text("DA")),
            DataColumn(label: Text("Net Salary")),
          ],
          rows: List.generate(salary.length, (index) {
            final item = salary[index];
            final serialNumber = ((page - 1) * limit) + index + 1;

            return DataRow(
              cells: [
                DataCell(Text(serialNumber.toString())),

                // Date
                DataCell(Text(formatDate(item["salary_date"]))),

                // Attendance Type
                DataCell(Text(item["attendance_type"] ?? "-")),

                // Working Hours
                DataCell(Text(item["working_hours"] ?? "-")),

                // Per Day Salary
                DataCell(Text("₹ ${item["per_day_salary"] ?? "0"}")),

                // TA
                DataCell(Text("₹ ${item["travelling_allowance"] ?? "0"}")),

                // DA
                DataCell(Text("₹ ${item["daily_allowance"] ?? "0"}")),

                // Net Salary
                DataCell(Text(
                  "₹ ${item["net_salary"] ?? "0"}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )),
              ],
            );
          }),
        ),
      ),
    ),
  );
}
  /// 🔹 Pagination
  Widget buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: page > 1
              ? () {
                  setState(() => page--);
                  fetchSalary();
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
                  fetchSalary();
                }
              : null,
          child: const Text("Next"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  : salary.isEmpty
                      ? const Center(child: Text("No salary found"))
                      : buildTable(),
            ),

            const SizedBox(height: 10),

            buildPagination(),
          ],
        ),
      ),
    );
  }
}