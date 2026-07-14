import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class ReceiptEntryData {
  String ledgerId = "";
  String ledgerName = "";
  String? employeeUnder;
  double currentBalance = 0;
  final TextEditingController amountController = TextEditingController();
  String transactionType = "";
  String bankName = "";

  void dispose() {
    amountController.dispose();
  }
}

class ReceiptApprovalRequestPage extends StatefulWidget {
  const ReceiptApprovalRequestPage({super.key});

  @override
  State<ReceiptApprovalRequestPage> createState() =>
      _ReceiptApprovalRequestPageState();
}

class _ReceiptApprovalRequestPageState
    extends State<ReceiptApprovalRequestPage> {
  List<dynamic> bankLedgers = [];
  List<dynamic> partyLedgers = [];

  String? selectedBankLedgerId;
  final TextEditingController narrationController = TextEditingController();

  // Date is no longer shown in the UI — captured silently at submit time.
  String get _todayDate => DateTime.now().toIso8601String().split("T").first;

  final List<ReceiptEntryData> entries = [];

  File? attachment;
  bool loadingDropdowns = true;
  bool submitting = false;

  double get totalAmount => entries.fold(
        0,
        (sum, e) => sum + (double.tryParse(e.amountController.text) ?? 0),
      );

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    narrationController.dispose();
    for (final e in entries) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    setState(() => loadingDropdowns = true);

    final bankRes = await ApiService.getBankAccountLedgerDropdown();
    final ledgers = await ApiService.getMyAssignedLedgers();

    setState(() {
      bankLedgers = bankRes['success'] == true ? (bankRes['data'] ?? []) : [];
      partyLedgers = ledgers; // already a plain List<dynamic>
      loadingDropdowns = false;
    });
  }

  void _addPartyRow() {
    setState(() {
      entries.add(ReceiptEntryData());
    });
  }

  void _removePartyRow(int index) {
    setState(() {
      entries[index].dispose();
      entries.removeAt(index);
    });
  }

  Future<void> _onPartySelected(int index, String ledgerId) async {
    final match = partyLedgers.firstWhere(
      (l) => l['id'].toString() == ledgerId,
      orElse: () => null,
    );

    setState(() {
      entries[index].ledgerId = ledgerId;
      entries[index].ledgerName = match != null ? match['ledger_name'] : "";
      entries[index].employeeUnder =
          match != null ? match['employee_under']?.toString() : null;
      entries[index].currentBalance = 0;
    });

    if (ledgerId.isEmpty) return;

    final res = await ApiService.getLedgerDetailsById(ledgerId);
    if (res['success'] == true) {
      final data = res['data'];
      final rawBalance = double.tryParse(
            data['current_balance']?.toString() ?? "0",
          ) ??
          0;
      final balance = data['balance_type'] == 'Cr'
          ? -rawBalance.abs()
          : rawBalance.abs();

      setState(() {
        entries[index].currentBalance = balance;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                "Add Document Image",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Colors.green),
              title: const Text("Camera"),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.green),
              title: const Text("Gallery"),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() => attachment = File(picked.path));
    }
  }
  void _resetForm() {
  setState(() {
    selectedBankLedgerId = null;
    narrationController.clear();
    attachment = null;
    for (final e in entries) {
      e.dispose();
    }
    entries.clear();
  });
}

  Future<void> _submit() async {
    if (selectedBankLedgerId == null || selectedBankLedgerId!.isEmpty) {
      _showError("Please select a bank account");
      return;
    }
    if (entries.isEmpty) {
      _showError("Please add at least one party");
      return;
    }
    for (final e in entries) {
      if (e.ledgerId.isEmpty ||
          e.amountController.text.isEmpty ||
          e.transactionType.isEmpty) {
        _showError("Each party must have a name, amount, and transaction type");
        return;
      }
    }
    if (attachment == null) {
      _showError("Please upload a document image before submitting");
      return;
    }

    setState(() => submitting = true);

    // employee_under is now sent at the TOP LEVEL of the payload, derived
    // from the first entry's selected ledger (all entries currently share
    // the same submitting employee's ledger assignment).
    final topLevelEmployeeUnder =
        entries.isNotEmpty ? entries.first.employeeUnder : null;

    final entriesPayload = entries
        .map((e) => {
              "ledger_id": e.ledgerId,
              "amount": double.tryParse(e.amountController.text) ?? 0,
              "transaction_type": e.transactionType,
              "transaction_no": null, // field removed from UI
              "bank_name": e.bankName.isEmpty ? null : e.bankName,
              "bill_references": [],
            })
        .toList();

    final res = await ApiService.createReceiptApprovalRequest(
      accountLedgerId: selectedBankLedgerId!,
      receiptDate: _todayDate,
      employeeUnderId: topLevelEmployeeUnder,
      narration: narrationController.text,
      totalAmount: totalAmount,
      entries: entriesPayload,
      attachment: attachment!,
    );

    setState(() => submitting = false);

    if (res['success'] == true) {
       if (!mounted) return;

  _resetForm();
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Receipt request submitted for approval")),
  );

  // Let the SnackBar actually be seen before resetting the form.
  await Future.delayed(const Duration(seconds: 2));

 
} else {
  _showError(res['message'] ?? "Something went wrong");
}
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Receipt Request",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 253, 254, 255),
        elevation: 0,
      ),
      floatingActionButton: SizedBox(
        height: 42,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 97, 180, 104),
                Color.fromARGB(255, 40, 119, 20),
              ],
            ),
          ),
          child: FloatingActionButton.extended(
            onPressed: _addPartyRow,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              "Add Party",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: loadingDropdowns
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBankSection(),
                  const SizedBox(height: 14),

                  const Text(
                    "Parties",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ...entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final e = entry.value;
                    return _partyCard(index, e);
                  }),

                  if (entries.isEmpty) _emptyPartiesHint(),

                  const SizedBox(height: 14),
                  _buildSummarySection(),

                  const SizedBox(height: 14),
                  _buildNarrationSection(),

                  const SizedBox(height: 14),
                  _buildAttachmentSection(),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text(
                              "SUBMIT",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  // ---------------- Sections ----------------

  Widget _buildBankSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.account_balance_outlined, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  "Bank Account",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedBankLedgerId,
              decoration: _fieldDecoration(label: "Select Bank Account"),
              items: bankLedgers
                  .map<DropdownMenuItem<String>>(
                    (l) => DropdownMenuItem(
                      value: l['id'].toString(),
                      child: Text(l['ledger_name']),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedBankLedgerId = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyPartiesHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.group_outlined, color: Colors.green.shade300, size: 32),
          const SizedBox(height: 6),
          Text(
            "No parties added yet",
            style: TextStyle(color: Colors.green.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Total Amount",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              "₹${totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrationSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TextFormField(
          controller: narrationController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: "Narration",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Document Image",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 10),
            if (attachment != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      attachment!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => attachment = null),
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 36,
                    color: Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade800,
                  side: BorderSide(color: Colors.green.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(
                  attachment == null ? "Upload Document Image" : "Change Image",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partyCard(int index, ReceiptEntryData e) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Party ${index + 1}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removePartyRow(index),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: e.ledgerId.isEmpty ? null : e.ledgerId,
                    decoration: _fieldDecoration(label: "Party Name"),
                    isExpanded: true,
                    items: partyLedgers
                        .map<DropdownMenuItem<String>>(
                          (l) => DropdownMenuItem(
                            value: l['id'].toString(),
                            child: Text(
                              l['ledger_name'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => _onPartySelected(index, v ?? ""),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    readOnly: true,
                    decoration: _fieldDecoration(label: "Balance"),
                    controller: TextEditingController(
                      text: e.currentBalance.toStringAsFixed(2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: e.amountController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration(label: "Amount"),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: e.transactionType.isEmpty ? null : e.transactionType,
                    decoration: _fieldDecoration(label: "Transaction Type"),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: "Cash",
                        child: Text("Cash", overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: "Cheque/DD",
                        child: Text("Cheque/DD", overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: "E-Fund Transfer",
                        child: Text("E-Fund Transfer", overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: "Others",
                        child: Text("Others", overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => e.transactionType = v ?? ""),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: e.bankName.isEmpty ? null : e.bankName,
              decoration: _fieldDecoration(label: "Bank Name"),
              isExpanded: true,
              items: bankLedgers
                  .map<DropdownMenuItem<String>>(
                    (l) => DropdownMenuItem(
                      value: l['ledger_name'],
                      child: Text(
                        l['ledger_name'],
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => e.bankName = v ?? ""),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.green, width: 1.4),
      ),
    );
  }
}