import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../pages/profile_menu_page.dart';

class VisitReportPage extends StatefulWidget {
  const VisitReportPage({super.key});

  @override
  State<VisitReportPage> createState() => _VisitPageState();
}

class _VisitPageState extends State<VisitReportPage> {
  List visits = [];
  bool isLoading = true;

  int page = 1;
  int totalPages = 1;
  int limit = 10;

  String visitType = "";
  String search = "";
  String? fromDate;
  String? toDate;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchVisits();
  }

  Future<void> fetchVisits() async {
    setState(() => isLoading = true);

    final res = await ApiService.getMyVisits(
      page: page,
      limit: limit,
      visitType: visitType,
      fromDate: fromDate,
      toDate: toDate,
      search: search,
    );

    if (res["success"]) {
      setState(() {
        visits = res["data"];
        totalPages = res["totalPages"];
      });
    }

    setState(() => isLoading = false);
  }

  ///  Back → Profile Menu
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
          "My Visits",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  ///  Date Picker
  Future<void> pickDate(bool isFrom) async {
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
        if (isFrom) {
          fromDate = formatted;
        } else {
          toDate = formatted;
        }
        page = 1;
      });

      fetchVisits();
    }
  }

  ///  Filters
  Widget buildFilters() {
  return Column(
    children: [
      /// 🔹 Row 1 → Search + Visit Type
      Row(
  children: [
    Expanded(
      child: TextField(
        controller: searchController,
        decoration: const InputDecoration(
          hintText: "Search customer / contact no.",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          search = value;
          page = 1;
          fetchVisits();
        },
      ),
    ),
    const SizedBox(width: 10),

    ///  FIXED WIDTH (IMPORTANT)
    SizedBox(
      width: 130,
      child: DropdownButtonFormField(
        isExpanded: true, //  IMPORTANT
        value: visitType.isEmpty ? null : visitType,
        hint: const Text("Type"),
        items: ["retailer", "distributor", "farmer"]
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.toUpperCase()),
                ))
            .toList(),
        onChanged: (value) {
          visitType = value ?? "";
          page = 1;
          fetchVisits();
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
      ),
    ),
  ],
),

      const SizedBox(height: 10),

      ///  Row 2 → Dates
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => pickDate(true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "From Date",
                  border: OutlineInputBorder(),
                ),
                child: Text(fromDate ?? "Select"),
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
                child: Text(toDate ?? "Select"),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
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
                DataColumn(label: Text("Customer")),
                // DataColumn(label: Text("Employee")),
                DataColumn(label: Text("Type")),
                DataColumn(label: Text("Firm")),
                DataColumn(label: Text("Contact")),
                DataColumn(label: Text("Purpose")),
                DataColumn(label: Text("Visit Date")),
                DataColumn(label: Text("Reminder Date")),
              ],
              rows: List.generate(visits.length, (index) {
                final item = visits[index];
                final serialNumber = ((page - 1) * limit) + index + 1;

                return DataRow(
                  cells: [
                    DataCell(Text(serialNumber.toString())),
                    DataCell(Text(item["customer_name"] ?? "")),
                    // DataCell(Text(item["emp_name"] ?? "-")),
                    DataCell(Text(item["visit_type"] ?? "-")),
                    DataCell(Text(item["firm_name"] ?? "-")),
                    DataCell(Text(item["contact_number"] ?? "-")),
                    DataCell(Text(item["visit_purpose"] ?? "-")),
                    DataCell(Text(
                      item["created_at"] != null
                          ? item["created_at"]
                              .toString()
                              .substring(0, 10)
                          : "-",
                    )),
                    DataCell(Text(
                      item["reminder_date"] != null
                          ? item["reminder_date"]
                              .toString()
                              .substring(0, 10)
                          : "-",
                    )),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
  ///  Pagination UI
  Widget buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: page > 1
              ? () {
                  setState(() => page--);
                  fetchVisits();
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
                  fetchVisits();
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
      return false; //  stop default back (IMPORTANT)
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
                  : visits.isEmpty
                      ? const Center(child: Text("No visits found"))
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