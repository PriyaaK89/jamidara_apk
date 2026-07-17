import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../utils/credit_note_item.dart';
import '../../widgets/searchable_field.dart';

enum CreditNoteMode { fromSales, manual }

class CreditNotePage extends StatefulWidget {
  const CreditNotePage({super.key});

  @override
  State<CreditNotePage> createState() => _CreditNotePageState();
}

class _CreditNotePageState extends State<CreditNotePage> {
  final narrationController = TextEditingController();
  final dealerController = TextEditingController();
  final proprietorController = TextEditingController();
  final consigneeContactController = TextEditingController();
  final consigneeAddressController = TextEditingController();
  final consigneeGstController = TextEditingController();

  bool isLoadingInitial = true;
  bool isSubmitting = false;

  List<dynamic> ledgers = [];
  List<dynamic> stockItems = [];

  Map<String, dynamic>? selectedLedger;

  CreditNoteMode? mode;

  // ── Mode A: From Sales
  List<dynamic> invoiceList = [];
  Map<String, dynamic>? selectedInvoice;

  // ── Shared
  List<CreditNoteItem> creditNoteItems = [];

  // ── Consignee (manual mode)
  bool isConsignee = false;

  // ── Images (both modes)
  File? billTImage;
  File? dispatchDocImage;
  final ImagePicker picker = ImagePicker();

  final DateTime today = DateTime.now();
  late String creditNoteDate;

  @override
  void initState() {
    super.initState();
    creditNoteDate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    loadInitialData();
  }

  @override
  void dispose() {
    narrationController.dispose();
    dealerController.dispose();
    proprietorController.dispose();
    consigneeContactController.dispose();
    consigneeAddressController.dispose();
    consigneeGstController.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    try {
      final results = await Future.wait([
        ApiService.getMyAssignedLedgers(),
        ApiService.getStockItems(),
      ]);
      if (!mounted) return;
      setState(() {
        ledgers = results[0];
        stockItems = results[1];
        isLoadingInitial = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingInitial = false);
      _showSnack("Failed to load data: $e");
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> onLedgerSelected(Map<String, dynamic> ledger) async {
    setState(() {
      selectedLedger = ledger;
      mode = null;
      invoiceList = [];
      selectedInvoice = null;
      creditNoteItems = [];
    });

    try {
      final data = await ApiService.getSalesByCustomer(ledger["id"]);
      if (!mounted) return;
      setState(() => invoiceList = data);
    } catch (e) {
      _showSnack("Failed to load sales history: $e");
    }
  }

  void selectMode(CreditNoteMode m) {
    setState(() {
      mode = m;
      selectedInvoice = null;
      creditNoteItems = m == CreditNoteMode.manual ? [CreditNoteItem()] : [];
      isConsignee = false;
      billTImage = null;
      dispatchDocImage = null;
    });
  }

  Future<void> onInvoiceSelected(Map<String, dynamic> invoice) async {
    setState(() => selectedInvoice = invoice);

    try {
      final saleId = invoice["id"] as int;
      final saleItems = await ApiService.getSaleItemsById(saleId);

      final populated = saleItems.map<CreditNoteItem>((si) {
        final item = CreditNoteItem()
          ..stockItemId = si["stock_item_id"]
          ..itemName = si["stock_item_name"] ?? ""
          ..godownId = si["godown_id"]
          ..batchNo = si["batch_no"]?.toString() ?? ""
          ..rate = _toDouble(si["rate"])
          ..unitId = si["unit_id"]
          ..unitName = si["base_unit_name"] ?? ""
          ..altUnitId = si["alt_unit_id"]
          ..altUnitQty = _toDouble(si["alternative_unit_value"])
          ..altUnitName = si["alternative_unit_name"] ?? ""
          ..igstPercent = _toDouble(si["igst_percent"])
          ..cgstPercent = _toDouble(si["cgst_percent"])
          ..sgstPercent = _toDouble(si["sgst_percent"])
          ..soldQty = _toDouble(si["billed_qty"])
          ..availableToReturn = _toDouble(si["available_to_return"]);
        return item;
      }).toList();

      setState(() {
        creditNoteItems = populated.isNotEmpty ? populated : [CreditNoteItem()];
      });
    } catch (e) {
      _showSnack("Failed to load invoice details: $e");
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  void _recalcItem(CreditNoteItem item) {
    item.amount = item.returnQty * item.rate;
    final taxPct = item.cgstPercent + item.sgstPercent + item.igstPercent;
    item.totalAmount = item.amount + (item.amount * taxPct / 100);
  }

  Future<void> onStockItemSelected(int stockItemId, CreditNoteItem row) async {
    try {
      final response = await ApiService.getStockItemById(stockItemId);
      if (response["success"] != true || response["data"] == null) {
        _showSnack(response["message"]?.toString() ?? "Failed to load item");
        return;
      }
      final data = response["data"] as Map<String, dynamic>;
      final openingStock = data["opening_stock"] as Map<String, dynamic>?;
      final gstDetails = data["gst_details"] as Map<String, dynamic>?;

      row.stockItemId = data["id"];
      row.itemName = data["item_name"] ?? "";
      row.unitId = data["unit_id"];
      row.unitName = data["base_unit_name"] ?? "";
      row.rate = _toDouble(openingStock?["rate"]);
      row.availableQty = _toDouble(openingStock?["quantity"]);
      row.batchNo = openingStock?["batch_no"]?.toString() ?? "";
      row.godownId = openingStock?["godown_id"];
      row.godownName = openingStock?["godown_name"]?.toString();
      row.cgstPercent = _toDouble(gstDetails?["central_tax"]);
      row.sgstPercent = _toDouble(gstDetails?["state_tax"]);
      row.igstPercent = _toDouble(gstDetails?["integrated_tax"]);
      if (row.igstPercent > 0) {
        row.cgstPercent = 0;
        row.sgstPercent = 0;
      }
      _recalcItem(row);
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack("Error loading item details: $e");
    }
  }

  void addItemRow() => setState(() => creditNoteItems.add(CreditNoteItem()));

  void removeItemRow(int index) {
    if (creditNoteItems.length == 1) return;
    setState(() => creditNoteItems.removeAt(index));
  }

  void onReturnQtyChanged(CreditNoteItem item, String value) {
    final qty = double.tryParse(value) ?? 0;
    if (mode == CreditNoteMode.fromSales &&
        item.availableToReturn > 0 &&
        qty > item.availableToReturn) {
      _showSnack("Max returnable qty: ${item.availableToReturn}");
      return;
    }
    setState(() {
      item.returnQty = qty;
      _recalcItem(item);
    });
  }

  Future<void> pickImage(bool isBillT) async {
    final XFile? image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image != null) {
      setState(() {
        if (isBillT) {
          billTImage = File(image.path);
        } else {
          dispatchDocImage = File(image.path);
        }
      });
    }
  }

  double get subtotal => creditNoteItems.fold(0.0, (s, i) => s + i.amount);
  double get igstTotal =>
      creditNoteItems.fold(0.0, (s, i) => s + (i.amount * i.igstPercent / 100));
  double get cgstTotal =>
      creditNoteItems.fold(0.0, (s, i) => s + (i.amount * i.cgstPercent / 100));
  double get sgstTotal =>
      creditNoteItems.fold(0.0, (s, i) => s + (i.amount * i.sgstPercent / 100));
  double get taxTotal => igstTotal + cgstTotal + sgstTotal;
  double get grandTotal => subtotal + taxTotal;

  Future<void> submit() async {
    if (selectedLedger == null) {
      _showSnack("Please select a party");
      return;
    }
    if (mode == null) {
      _showSnack("Please choose Select from Sales or Manual entry");
      return;
    }
    if (mode == CreditNoteMode.fromSales && selectedInvoice == null) {
      _showSnack("Please select an original invoice");
      return;
    }
    final validItems = creditNoteItems
        .where((i) => i.stockItemId != null && i.returnQty > 0)
        .toList();
    if (validItems.isEmpty) {
      _showSnack("Add at least one item with return quantity");
      return;
    }
    if (billTImage == null || dispatchDocImage == null) {
      _showSnack("Bill-T image and Dispatch Document image are required");
      return;
    }

    setState(() => isSubmitting = true);

    final response = await ApiService.createCreditNoteApprovalRequest(
      customerLedgerId: selectedLedger!["id"],
      creditNoteDate: creditNoteDate,
      originalSaleId:
          mode == CreditNoteMode.fromSales ? selectedInvoice!["id"] : null,
      salesReturnLedgerId: 0, // no longer collected from the user; see note above about backend nullability
      // isConsignee: mode == CreditNoteMode.manual ? isConsignee : false,
      isConsignee: isConsignee,
      dealerName: isConsignee ? dealerController.text.trim() : null,
      proprietorName: isConsignee ? proprietorController.text.trim() : null,
      consigneeContactNo:
          isConsignee ? consigneeContactController.text.trim() : null,
      consigneeAddress:
          isConsignee ? consigneeAddressController.text.trim() : null,
      consigneeGstnNo: isConsignee ? consigneeGstController.text.trim() : null,
      subtotal: subtotal,
      igstTotal: igstTotal,
      cgstTotal: cgstTotal,
      sgstTotal: sgstTotal,
      taxTotal: taxTotal,
      totalAmount: grandTotal,
      narration: narrationController.text.trim(),
      items: validItems,
      billReferences: const [],
      billTImage: billTImage,
      dispatchDocImage: dispatchDocImage,
    );

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (response["success"] == true) {
      _showSnack(response["message"]?.toString() ?? "Credit note submitted");
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } else {
      _showSnack(response["message"]?.toString() ?? "Submission failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Credit Note",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLedgerSection(),
                  if (selectedLedger != null) ...[
                    const SizedBox(height: 14),
                    _buildModeSelector(),
                  ],
                  if (mode == CreditNoteMode.fromSales) ...[
                    const SizedBox(height: 14),
                    _buildInvoiceSection(),
                  ],
                  // if (mode == CreditNoteMode.manual) ...[
                  //   const SizedBox(height: 14),
                  //   _buildConsigneeToggle(),
                  // ],
                  if (mode != null) ...[
  const SizedBox(height: 14),
  _buildConsigneeToggle(),
],
                  if (mode != null &&
                      (mode == CreditNoteMode.manual ||
                          selectedInvoice != null)) ...[
                    const SizedBox(height: 14),
                    _buildItemsSection(),
                    const SizedBox(height: 14),
                    _buildImageSection(),
                    const SizedBox(height: 14),
                    _buildNarrationSection(),
                    const SizedBox(height: 14),
                    _buildSummarySection(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.4),
                              )
                            : const Text("SUBMIT CREDIT NOTE",
                                style:
                                    TextStyle(fontSize: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  Widget _buildLedgerSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Party / Ledger",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            SearchableField<Map<String, dynamic>>(
              label: "Select Party",
              hint: "Type to search party name",
              icon: Icons.person_search,
              options: ledgers.cast<Map<String, dynamic>>(),
              displayString: (o) => o["ledger_name"]?.toString() ?? "",
              filter: (o, query) => (o["ledger_name"] ?? "")
                  .toString()
                  .toLowerCase()
                  .contains(query),
              showClear: selectedLedger != null,
              onClear: () => setState(() {
                selectedLedger = null;
                mode = null;
              }),
              onSelected: (selection) {
                FocusScope.of(context).unfocus();
                onLedgerSelected(selection);
              },
              optionBuilder: (o) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text(o["ledger_name"]?.toString() ?? ""),
              ),
            ),
            if (selectedLedger != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _infoCard("Balance",
                          "₹${selectedLedger!["opening_balance"] ?? 0}")),
                  const SizedBox(width: 6),
                  Expanded(
                      child: _infoCard("Security",
                          "₹${selectedLedger!["security_amount"] ?? 0}")),
                  const SizedBox(width: 6),
                  Expanded(
                      child: _infoCard("Credit Limit",
                          "₹${selectedLedger!["credit_limit"] ?? 'N/A'}")),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("How do you want to raise this credit note?",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _modeButton(
                    "Select from Sales",
                    Icons.receipt_long,
                    mode == CreditNoteMode.fromSales,
                    () => selectMode(CreditNoteMode.fromSales),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _modeButton(
                    "Without Invoice",
                    Icons.edit_note,
                    mode == CreditNoteMode.manual,
                    () => selectMode(CreditNoteMode.manual),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(
      String label, IconData icon, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.teal.shade50 : Colors.grey.shade50,
          border:
              Border.all(color: selected ? Colors.teal : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? Colors.teal : Colors.grey.shade600, size: 22),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? Colors.teal.shade800 : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Original Invoice",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            if (invoiceList.isEmpty)
              Text("No sales found for this party",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
            else
              SearchableField<Map<String, dynamic>>(
                label: "Select Invoice",
                hint: "Search voucher no.",
                icon: Icons.receipt_long,
                options: invoiceList.cast<Map<String, dynamic>>(),
                displayString: (o) => o["voucher_no"]?.toString() ?? "",
                filter: (o, query) => (o["voucher_no"] ?? "")
                    .toString()
                    .toLowerCase()
                    .contains(query),
                showClear: selectedInvoice != null,
                onClear: () => setState(() {
                  selectedInvoice = null;
                  creditNoteItems = [];
                }),
                onSelected: (selection) {
                  FocusScope.of(context).unfocus();
                  onInvoiceSelected(selection);
                },
                optionBuilder: (o) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o["voucher_no"]?.toString() ?? "",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text("${o["sales_date"]} · ₹${o["total_amount"]}",
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsigneeToggle() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: const Icon(Icons.local_shipping_outlined, size: 18),
            title: const Text("Is Consignee", style: TextStyle(fontSize: 14)),
            trailing: Transform.scale(
              scale: 0.8,
              child: Switch(
                activeColor: Colors.teal,
                value: isConsignee,
                onChanged: (v) => setState(() => isConsignee = v),
              ),
            ),
          ),
          if (isConsignee)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  TextField(
                    controller: dealerController,
                    decoration:
                        const InputDecoration(labelText: "Dealer Name"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: proprietorController,
                    decoration:
                        const InputDecoration(labelText: "Proprietor Name"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: consigneeContactController,
                    decoration: const InputDecoration(labelText: "Contact"),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: consigneeAddressController,
                    decoration: const InputDecoration(labelText: "Address"),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: consigneeGstController,
                    decoration:
                        const InputDecoration(labelText: "GST Number"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Return Items",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (mode == CreditNoteMode.manual)
              TextButton.icon(
                onPressed: addItemRow,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Add Item"),
              ),
          ],
        ),
        ...List.generate(creditNoteItems.length, (index) {
          final item = creditNoteItems[index];
          return Card(
            key: ValueKey(item.uid),
            elevation: 1.5,
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: mode == CreditNoteMode.manual
                            ? SearchableField<Map<String, dynamic>>(
                                label: "Stock Item",
                                hint: "Search item",
                                icon: Icons.inventory_2_outlined,
                                options: stockItems.cast<Map<String, dynamic>>(),
                                displayString: (o) =>
                                    o["item_name"]?.toString() ?? "",
                                filter: (o, query) => (o["item_name"] ?? "")
                                    .toString()
                                    .toLowerCase()
                                    .contains(query),
                                initialValue:
                                    TextEditingValue(text: item.itemName),
                                onSelected: (selection) {
                                  FocusScope.of(context).unfocus();
                                  final id = selection["id"];
                                  if (id is int) onStockItemSelected(id, item);
                                },
                                optionBuilder: (o) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Text(o["item_name"]?.toString() ?? ""),
                                ),
                              )
                            : Text(item.itemName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      if (mode == CreditNoteMode.manual &&
                          creditNoteItems.length > 1)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => removeItemRow(index),
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _smallChip("Rate", "₹${item.rate.toStringAsFixed(2)}"),
                      _smallChip("Unit", item.unitName),
                      if (mode == CreditNoteMode.fromSales)
                        _smallChip("Available to return",
                            item.availableToReturn.toStringAsFixed(2)),
                      if (item.igstPercent > 0)
                        _smallChip("IGST", "${item.igstPercent}%")
                      else ...[
                        _smallChip("CGST", "${item.cgstPercent}%"),
                        _smallChip("SGST", "${item.sgstPercent}%"),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: ValueKey("qty_${item.uid}"),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Return Qty",
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (v) => onReturnQtyChanged(item, v),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Amount",
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Text("₹${item.totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _smallChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text("$label: $value", style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildImageSection() {
    return Row(
      children: [
        Expanded(
            child: _imageUploadCard(
                "Bill-T Image", billTImage, () => pickImage(true))),
        const SizedBox(width: 10),
        Expanded(
            child: _imageUploadCard("Dispatch Doc Image", dispatchDocImage,
                () => pickImage(false))),
      ],
    );
  }

  Widget _imageUploadCard(String label, File? file, VoidCallback onTap) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(file,
                    height: 90, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_outlined, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onTap,
              child: Text(file == null ? "Upload" : "Change",
                  style: const TextStyle(fontSize: 11)),
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

  Widget _buildSummarySection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Grand Total",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text("₹${grandTotal.toStringAsFixed(2)}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
    );
  }
}