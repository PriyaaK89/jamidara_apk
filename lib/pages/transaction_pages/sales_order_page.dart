import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../utils/sales_item.dart';
import '../../widgets/searchable_field.dart'; // adjust path to your project structure

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key});
  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final TextEditingController narrationController = TextEditingController();

  List<dynamic> ledgers = [];
  List<dynamic> stockItems = [];

  Map<String, dynamic>? selectedLedger;

  bool isConsignee = false;
  bool isSupercash = false;

  bool isLoadingInitial = true;
  bool isSubmitting = false;

  File? orderBillImage;
  final ImagePicker picker = ImagePicker();

  List<SalesItem> salesItems = [SalesItem()];
  final dealerController = TextEditingController();
  final proprietorController = TextEditingController();
  final consigneeContactController = TextEditingController();
  final consigneeAddressController = TextEditingController();
  final consigneeGstController = TextEditingController();

  double _effectiveRate(SalesItem item) {
    return isSupercash ? item.supercashRate : item.rate;
  }

  @override
  void initState() {
    super.initState();
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

  // ---------------- Data loading ----------------

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

  

  // ---------------- Image ----------------

  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 80, // optional: compresses the image a bit before upload
    );

    if (image != null) {
      setState(() => orderBillImage = File(image.path));
    }
  }

  // ---------------- Item rows ----------------

  void addItemRow() {
    setState(() => salesItems.add(SalesItem()));
  }

  void removeItemRow(int index) {
    if (salesItems.length == 1) return;
    setState(() => salesItems.removeAt(index));
  }

  void _recalculateItem(SalesItem item) {
  final effectiveRate = isSupercash ? item.supercashRate : item.rate;
  item.amount = item.billedQty * effectiveRate;

  final taxPercent = item.cgstPercent + item.sgstPercent + item.igstPercent;
  item.totalAmount = item.amount + (item.amount * taxPercent / 100);
}

  void onQtyChanged(SalesItem item, String value) {
    setState(() {
      item.billedQty = double.tryParse(value) ?? 0;
      _recalculateItem(item);
    });
  }

  void onSupercashToggle(bool value) {
    setState(() {
      isSupercash = value;
      for (final item in salesItems) {
        _recalculateItem(item);
      }
    });
  }

  void _applyGstSelection(SalesItem item) {
  if (item.igstPercent > 0) {
    item.cgstPercent = 0;
    item.sgstPercent = 0;
  } else {
    item.igstPercent = 0;
  }
}

  void showImageSourceSheet() {
    FocusScope.of(context).requestFocus(FocusNode());
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  "Add Bill Image",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.green,
                ),
                title: const Text("Take a photo"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.green,
                ),
                title: const Text("Choose from gallery"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void clearItemSelection(SalesItem item) {
    setState(() {
      item.stockItemId = null;
      item.itemName = "";
      item.unitId = null;
      item.unitName = "";
      item.rate = 0;
      item.supercashRate = 0;
      item.availableQty = 0;
      item.batchNo = "";
      item.godownId = null;
      item.godownName = null;
      item.cgstPercent = 0;
      item.sgstPercent = 0;
      item.igstPercent = 0;
      item.amount = 0;
      item.totalAmount = 0;
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }

  Future<void> onItemSelected(int itemId, SalesItem row) async {
    try {
      final response = await ApiService.getStockItemById(itemId);

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
      row.supercashRate = _toDouble(openingStock?["supercash_price"]);
      row.availableQty = _toDouble(openingStock?["quantity"]);
      row.batchNo = openingStock?["batch_no"]?.toString() ?? "";
      row.godownId = openingStock?["godown_id"];
      row.godownName = openingStock?["godown_name"]?.toString();

      // gst_details can be null (as in your sample response) - default to 0
      row.cgstPercent = _toDouble(gstDetails?["central_tax"]);
      row.sgstPercent = _toDouble(gstDetails?["state_tax"]);
      row.igstPercent = _toDouble(gstDetails?["integrated_tax"]);
      _applyGstSelection(row);   // <-- add this line
_recalculateItem(row);


      if (mounted) setState(() {});
    } catch (e) {
      _showSnack("Error loading item details: $e");
    }
  }

  // ---------------- Totals ----------------

  double getSubTotal() {
    return salesItems.fold(0, (sum, item) => sum + item.amount);
  }

  double getTaxTotal() {
  double total = 0;
  for (var item in salesItems) {
    final taxPercent = item.cgstPercent + item.sgstPercent + item.igstPercent;
    total += item.amount * taxPercent / 100;
  }
  return total;
}

  double getGrandTotal() => getSubTotal() + getTaxTotal();

  // ---------------- Consignee dialog ----------------

  void showConsigneeDialog() {
    FocusScope.of(context).requestFocus(FocusNode());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text("Consignee Details"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dealerController,
                  decoration: const InputDecoration(labelText: "Dealer Name"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: proprietorController,
                  decoration: const InputDecoration(
                    labelText: "Proprietor Name",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: consigneeContactController,
                  decoration: const InputDecoration(labelText: "Contact"),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: consigneeAddressController,
                  decoration: const InputDecoration(labelText: "Address"),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: consigneeGstController,
                  decoration: const InputDecoration(labelText: "GST Number"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ---------------- Submit ----------------

  void _resetForm() {
    setState(() {
      selectedLedger = null;
      isConsignee = false;
      isSupercash = false;
      orderBillImage = null;
      salesItems = [SalesItem()];
      narrationController.clear();
      dealerController.clear();
      proprietorController.clear();
      consigneeContactController.clear();
      consigneeAddressController.clear();
      consigneeGstController.clear();
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatAmount(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '') ?? 0;
    if (number == number.roundToDouble()) {
      return number.toStringAsFixed(0); // 10000.00 -> "10000"
    }
    return number.toStringAsFixed(2); // 10000.50 -> "10000.50"
  }

  Future<void> submitSalesOrder() async {
    if (selectedLedger == null) {
      _showSnack("Please select a ledger");
      return;
    }

    if (orderBillImage == null) {
      _showSnack("Please upload the bill image");
      return;
    }

    final validItems = salesItems
        .where((item) => item.stockItemId != null && item.billedQty > 0)
        .toList();

    if (validItems.isEmpty) {
      _showSnack("Add at least one item with a quantity");
      return;
    }

    setState(() => isSubmitting = true);

    final response = await ApiService.createSalesApprovalRequest(
      ledgerId: selectedLedger!["id"],
      isConsignee: isConsignee,
      isSupercash: isSupercash,
      narration: narrationController.text.trim(),
      dealerName: isConsignee ? dealerController.text.trim() : null,
      proprietorName: isConsignee ? proprietorController.text.trim() : null,
      consigneeContactNo: isConsignee
          ? consigneeContactController.text.trim()
          : null,
      consigneeAddress: isConsignee
          ? consigneeAddressController.text.trim()
          : null,
      consigneeGstnNo: isConsignee ? consigneeGstController.text.trim() : null,
      subtotal: getSubTotal(),
      taxTotal: getTaxTotal(),
      totalAmount: getGrandTotal(),
      items: validItems,
      orderBillImage: orderBillImage!,
    );

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (response["success"] == true) {
      _showSnack(
        response["message"]?.toString() ?? "Sales order generated successfully",
      );

      // Let the SnackBar actually be seen before we navigate away -
      // popping immediately tears down this Scaffold along with it.
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        // Nothing to go back to (e.g. this page is a tab, not a pushed route).
        // Reset the form instead of leaving a black screen.
        _resetForm();
      }
    } else {
      _showSnack(response["message"]?.toString() ?? "Submission failed");
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Sale Order",
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
            onPressed: addItemRow,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              "Add Item",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLedgerSection(),
                  const SizedBox(height: 14),
                  _buildToggleSection(),
                  const SizedBox(height: 14),
                  const Text(
                    "Items",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildItemsSection(),
                  const SizedBox(height: 14),
                  _buildNarrationSection(),
                  const SizedBox(height: 14),
                  _buildImageSection(),
                  const SizedBox(height: 14),
                  _buildSummarySection(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : submitSalesOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text(
                              "SUBMIT SALES ORDER",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
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

  Widget _buildLedgerSection() {
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
                Icon(Icons.person_search, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  "Party / Ledger",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SearchableField<Map<String, dynamic>>(
              label: "Select Ledger",
              hint: "Type to search party name",
              icon: Icons.storefront_outlined,
              options: ledgers.cast<Map<String, dynamic>>(),
              displayString: (o) => o["ledger_name"]?.toString() ?? "",
              filter: (o, query) => (o["ledger_name"] ?? "")
                  .toString()
                  .toLowerCase()
                  .contains(query),
              showClear: selectedLedger != null,
              onClear: () => setState(() => selectedLedger = null),
              // onSelected: (selection) => setState(() => selectedLedger = selection),
              onSelected: (selection) {
                FocusScope.of(context).unfocus();
                setState(() => selectedLedger = selection);
              },
              optionBuilder: (o) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o["ledger_name"]?.toString() ?? "",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (o["opening_balance"] != null)
                      Text(
                        "Opening: ₹${o["opening_balance"]}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (selectedLedger != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      "Opening",
                      "₹${_formatAmount(selectedLedger!["opening_balance"])}",
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _infoCard(
                      "Security Amt.",
                      "₹${_formatAmount(selectedLedger!["security_amount"])}",
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _infoCard(
                      "Credit Limit",
                      "₹${_formatAmount(selectedLedger!["credit_limit"])}",
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: const Icon(Icons.local_shipping_outlined, size: 18),
            title: Text("Is Consignee", style: TextStyle(fontSize: 14)),
            trailing: Transform.scale(
              scale: 0.8,
              child: Switch(
                activeColor: Colors.green,
                value: isConsignee,
                onChanged: (value) {
                  setState(() => isConsignee = value);
                  if (value) {
                    showConsigneeDialog();
                  }
                },
              ),
            ),
          ),

          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Icons.savings_outlined, size: 18),
            title: Text("Supercash Sale", style: TextStyle(fontSize: 14)),
            trailing: Transform.scale(
              scale: 0.8,
              child: Switch(
                activeColor: Colors.green,
                value: isSupercash,
                onChanged: onSupercashToggle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      children: List.generate(salesItems.length, (index) {
        final item = salesItems[index];

        return Card(
          key: ValueKey(item.uid), // keeps each row's state tied to its data
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Item ${index + 1}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (salesItems.length > 1)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => removeItemRow(index),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                SearchableField<Map<String, dynamic>>(
                  label: "Stock Item",
                  hint: "Type to search item name",
                  icon: Icons.inventory_2_outlined,
                  options: stockItems.cast<Map<String, dynamic>>(),
                  displayString: (o) => o["item_name"]?.toString() ?? "",
                  filter: (o, query) => (o["item_name"] ?? "")
                      .toString()
                      .toLowerCase()
                      .contains(query),
                  initialValue: TextEditingValue(text: item.itemName),
                  showClear: item.stockItemId != null,
                  onClear: () => clearItemSelection(item),

                  onSelected: (selection) async {
                    FocusScope.of(context).unfocus();
                    final id = selection["id"];
                    if (id is int) {
                      await onItemSelected(id, item);
                    }
                  },
                  optionBuilder: (o) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(o["item_name"]?.toString() ?? ""),
                  ),
                ),

                const SizedBox(height: 12),

                if (item.stockItemId != null) ...[
                  if (isSupercash)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.savings_outlined,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "SuperCash pricing applied",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Rate chip - shows active rate, with original struck through if supercash
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSupercash
                              ? Colors.orange.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSupercash
                                ? Colors.orange.shade200
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Rate: ",
                              style: TextStyle(
                                fontSize: 12,
                                color: isSupercash
                                    ? Colors.orange.shade800
                                    : Colors.black87,
                              ),
                            ),
                            if (isSupercash) ...[
                              Text(
                                "₹${item.rate.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              "₹${_effectiveRate(item).toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSupercash
                                    ? Colors.orange.shade800
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _smallChip("Unit", item.unitName),
                      if (item.igstPercent > 0)
  _smallChip("IGST", "${item.igstPercent.toStringAsFixed(1)}%")
else ...[
  _smallChip("CGST", "${item.cgstPercent.toStringAsFixed(1)}%"),
  _smallChip("SGST", "${item.sgstPercent.toStringAsFixed(1)}%"),
],
                      // _smallChip("Available", item.availableQty.toStringAsFixed(2)),
                      // if (item.batchNo.isNotEmpty) _smallChip("Batch", item.batchNo),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                TextFormField(
                  key: ValueKey("qty_${item.uid}"),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: "Billed Qty",
                    labelStyle: const TextStyle(fontSize: 13),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    // helperText: item.availableQty > 0
                    //     ? "Available: ${item.availableQty.toStringAsFixed(2)} ${item.unitName}"
                    //     : null,
                  ),
                  onChanged: (value) => onQtyChanged(item, value),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Amount",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      //  _summaryRow("Grand Total", getGrandTotal(), isBold: true),
                     Text("₹${item.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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

  Widget _buildImageSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bill Image",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 10),
            if (orderBillImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      orderBillImage!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => orderBillImage = null),
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
                onPressed: showImageSourceSheet,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(
                  orderBillImage == null ? "Upload Bill Image" : "Change Image",
                ),
              ),
            ),
          ],
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
        child: Column(
          children: [_summaryRow("Grand Total", getGrandTotal(), isBold: true)],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: isBold ? 17 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text("₹${value.toStringAsFixed(2)}", style: style),
      ],
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
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
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
}
