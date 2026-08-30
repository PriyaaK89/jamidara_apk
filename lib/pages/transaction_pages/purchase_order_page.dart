import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../utils/purchase_item.dart';
import '../../widgets/searchable_field.dart';

class PurchaseOrderPage extends StatefulWidget {
  const PurchaseOrderPage({super.key});
  @override
  State<PurchaseOrderPage> createState() => _PurchaseOrderPageState();
}

class _PurchaseOrderPageState extends State<PurchaseOrderPage> {
  final TextEditingController narrationController = TextEditingController();
  final TextEditingController supplierInvoiceController = TextEditingController();

  // ---- Consignee controllers (same pattern as Sales Order page) ----
  bool isConsignee = false;
  final dealerController = TextEditingController();
  final proprietorController = TextEditingController();
  final consigneeContactController = TextEditingController();
  final consigneeAddressController = TextEditingController();
  final consigneeGstController = TextEditingController();

  List<dynamic> supplierLedgers = [];
  List<dynamic> purchaseLedgers = [];
  List<dynamic> stockItems = [];

  Map<String, dynamic>? selectedSupplierLedger;
  // Map<String, dynamic>? selectedPurchaseLedger;

  bool isLoadingInitial = true;
  bool isSubmitting = false;

  File? orderBillImage;
  final ImagePicker picker = ImagePicker();

  List<PurchaseItem> purchaseItems = [PurchaseItem()];

  // Rate field controllers, one per row, keyed by PurchaseItem.uid so we can
  // programmatically set the text when an item is selected (auto-fill) while
  // still letting the user edit it manually afterwards.
  final Map<String, TextEditingController> rateControllers = {};

  TextEditingController _rateControllerFor(PurchaseItem item) {
    return rateControllers.putIfAbsent(
      item.uid,
      () => TextEditingController(text: item.rate == 0 ? "" : _trimZeros(item.rate)),
    );
  }

  void _setRateControllerText(PurchaseItem item, double rate) {
    final controller = _rateControllerFor(item);
    controller.text = rate == 0 ? "" : _trimZeros(rate);
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
  }

  String _trimZeros(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  // ---------------- Per-item tax amounts ----------------

  double _itemCgstAmount(PurchaseItem item) => item.amount * item.cgstPercent / 100;
  double _itemSgstAmount(PurchaseItem item) => item.amount * item.sgstPercent / 100;
  double _itemIgstAmount(PurchaseItem item) => item.amount * item.igstPercent / 100;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    narrationController.dispose();
    supplierInvoiceController.dispose();
    dealerController.dispose();
    proprietorController.dispose();
    consigneeContactController.dispose();
    consigneeAddressController.dispose();
    consigneeGstController.dispose();
    for (final c in rateControllers.values) {
      c.dispose();
    }
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
        supplierLedgers = results[0];
        purchaseLedgers = results[0];
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
    final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() => orderBillImage = File(image.path));
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
                child: Text("Add Bill Image", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.green),
                title: const Text("Take a photo"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.green),
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

  // ---------------- Consignee dialog (mirrors Sales Order page) ----------------

  void showConsigneeDialog() {
    FocusScope.of(context).requestFocus(FocusNode());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  decoration: const InputDecoration(labelText: "Proprietor Name"),
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

  // ---------------- Item rows ----------------

  void addItemRow() {
    setState(() => purchaseItems.add(PurchaseItem()));
  }

  void removeItemRow(int index) {
    if (purchaseItems.length == 1) return;
    final removed = purchaseItems[index];
    rateControllers.remove(removed.uid)?.dispose();
    setState(() => purchaseItems.removeAt(index));
  }

  void _recalculateItem(PurchaseItem item) {
    item.amount = item.billedQty * item.rate;
    final taxPercent = item.cgstPercent + item.sgstPercent + item.igstPercent;
    item.totalAmount = item.amount + (item.amount * taxPercent / 100);
  }

  void onQtyChanged(PurchaseItem item, String value) {
    setState(() {
      item.billedQty = double.tryParse(value) ?? 0;
      _recalculateItem(item);
    });
  }

  void onRateChanged(PurchaseItem item, String value) {
    setState(() {
      item.rate = double.tryParse(value) ?? 0;
      _recalculateItem(item);
    });
  }

  void _applyGstSelection(PurchaseItem item) {
    if (item.igstPercent > 0) {
      item.cgstPercent = 0;
      item.sgstPercent = 0;
    } else {
      item.igstPercent = 0;
    }
  }

  void clearItemSelection(PurchaseItem item) {
    setState(() {
      item.stockItemId = null;
      item.itemName = "";
      item.unitId = null;
      item.unitName = "";
      item.availableQty = 0;
      item.batchNo = "";
      item.godownId = null;
      item.godownName = null;
      item.cgstPercent = 0;
      item.sgstPercent = 0;
      item.igstPercent = 0;
      item.rate = 0;
      item.amount = 0;
      item.totalAmount = 0;
      _setRateControllerText(item, 0);
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }

  // Purchase rate/GST comes from the same getStockItemById response as Sales,
  // read off opening_stock.rate — matches the sample response you shared.
  Future<void> onItemSelected(int itemId, PurchaseItem row) async {
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

      // Auto-fill rate from opening stock, still editable by the user below.
      row.rate = _toDouble(openingStock?["rate"]);

      row.cgstPercent = _toDouble(gstDetails?["central_tax"]);
      row.sgstPercent = _toDouble(gstDetails?["state_tax"]);
      row.igstPercent = _toDouble(gstDetails?["integrated_tax"]);
      _applyGstSelection(row);
      _recalculateItem(row);
      debugPrint(
  "item=${row.itemName} rate=${row.rate} cgst=${row.cgstPercent} "
  "sgst=${row.sgstPercent} igst=${row.igstPercent} amount=${row.amount}",
);

      if (mounted) {
        setState(() => _setRateControllerText(row, row.rate));
      }
    }  catch (e) {
  debugPrint("onItemSelected EXCEPTION: $e");
  _showSnack("Error loading item details: $e");
}
  }

  // ---------------- Totals ----------------

  double getSubTotal() => purchaseItems.fold(0, (sum, item) => sum + item.amount);

  double getIgstTotal() => purchaseItems.fold(
        0,
        (sum, item) => sum + (item.igstPercent > 0 ? item.amount * item.igstPercent / 100 : 0),
      );

  double getCgstTotal() => purchaseItems.fold(
        0,
        (sum, item) => sum + (item.cgstPercent > 0 ? item.amount * item.cgstPercent / 100 : 0),
      );

  double getSgstTotal() => purchaseItems.fold(
        0,
        (sum, item) => sum + (item.sgstPercent > 0 ? item.amount * item.sgstPercent / 100 : 0),
      );

  double getGrandTotal() => getSubTotal() + getIgstTotal() + getCgstTotal() + getSgstTotal();

  bool get hasIgst => purchaseItems.any((item) => item.igstPercent > 0);

  // ---------------- Submit ----------------

  void _resetForm() {
    for (final c in rateControllers.values) {
      c.dispose();
    }
    rateControllers.clear();
    setState(() {
      selectedSupplierLedger = null;
      // selectedPurchaseLedger = null;
      orderBillImage = null;
      purchaseItems = [PurchaseItem()];
      narrationController.clear();
      supplierInvoiceController.clear();
      isConsignee = false;
      dealerController.clear();
      proprietorController.clear();
      consigneeContactController.clear();
      consigneeAddressController.clear();
      consigneeGstController.clear();
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> submitPurchaseOrder() async {
  if (selectedSupplierLedger == null) {
    _showSnack("Please select a supplier");
    return;
  }

  if (orderBillImage == null) {
    _showSnack("Please upload the bill image");
    return;
  }

  final validItems = purchaseItems
      .where((item) => item.stockItemId != null && item.billedQty > 0)
      .toList();

  if (validItems.isEmpty) {
    _showSnack("Add at least one item with a quantity");
    return;
  }

  setState(() => isSubmitting = true);

  try {
    debugPrint("SUBMIT: about to call API");

    final response = await ApiService.createPurchaseApprovalRequest(
      supplierLedgerId: selectedSupplierLedger!["id"],
      // purchaseLedgerId: selectedPurchaseLedger!["id"],
      supplierInvoiceNo: supplierInvoiceController.text.trim(),
      narration: narrationController.text.trim(),
      isConsignee: isConsignee,
      dealerName: isConsignee ? dealerController.text.trim() : null,
      proprietorName: isConsignee ? proprietorController.text.trim() : null,
      consigneeContactNo: isConsignee ? consigneeContactController.text.trim() : null,
      consigneeAddress: isConsignee ? consigneeAddressController.text.trim() : null,
      consigneeGstnNo: isConsignee ? consigneeGstController.text.trim() : null,
      subtotal: getSubTotal(),
      igstTotal: getIgstTotal(),
      cgstTotal: getCgstTotal(),
      sgstTotal: getSgstTotal(),
      totalAmount: getGrandTotal(),
      taxMode: hasIgst ? "IGST" : "CGST_SGST",
      items: validItems,
      orderBillImage: orderBillImage!,
    );

    debugPrint("SUBMIT: got response = $response");

    if (!mounted) return;

    if (response["success"] == true) {
      _showSnack(response["message"]?.toString() ?? "Purchase order generated successfully");
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        _resetForm();
      }
    } else {
      _showSnack(response["message"]?.toString() ?? "Submission failed");
    }
  } catch (e, stack) {
    debugPrint("SUBMIT EXCEPTION: $e");
    debugPrint("SUBMIT STACK: $stack");
    if (mounted) _showSnack("Error: $e");
  } finally {
    if (mounted) setState(() => isSubmitting = false);
  }
}
  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Purchase Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              colors: [Color.fromARGB(255, 97, 180, 104), Color.fromARGB(255, 40, 119, 20)],
            ),
          ),
          child: FloatingActionButton.extended(
            onPressed: addItemRow,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text("Add Item", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                  _buildSupplierSection(),
                  const SizedBox(height: 14),
                  // _buildPurchaseLedgerSection(),
                  const SizedBox(height: 14),
                  _buildToggleSection(),
                  const SizedBox(height: 14),
                  const Text("Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildItemsSection(),
                  const SizedBox(height: 14),
                  _buildInvoiceAndNarrationSection(),
                  const SizedBox(height: 14),
                  _buildImageSection(),
                  const SizedBox(height: 14),
                  _buildSummarySection(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : submitPurchaseOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                            )
                          : const Text("SUBMIT PURCHASE ORDER", style: TextStyle(fontSize: 14, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildSupplierSection() {
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
                Text("Party/Ledger", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            SearchableField<Map<String, dynamic>>(
              label: "Select Ledger",
              hint: "Type to search party name",
              icon: Icons.storefront_outlined,
              options: supplierLedgers.cast<Map<String, dynamic>>(),
              displayString: (o) => o["ledger_name"]?.toString() ?? "",
              filter: (o, query) => (o["ledger_name"] ?? "").toString().toLowerCase().contains(query),
              showClear: selectedSupplierLedger != null,
              onClear: () => setState(() => selectedSupplierLedger = null),
              onSelected: (selection) {
                FocusScope.of(context).unfocus();
                setState(() => selectedSupplierLedger = selection);
              },
              optionBuilder: (o) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text(o["ledger_name"]?.toString() ?? "", style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseLedgerSection() {
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
                Text("Purchase Account", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            // SearchableField<Map<String, dynamic>>(
            //   label: "Select Purchase Ledger",
            //   hint: "Type to search ledger name",
            //   icon: Icons.receipt_long_outlined,
            //   options: purchaseLedgers.cast<Map<String, dynamic>>(),
            //   displayString: (o) => o["ledger_name"]?.toString() ?? "",
            //   filter: (o, query) => (o["ledger_name"] ?? "").toString().toLowerCase().contains(query),
            //   showClear: selectedPurchaseLedger != null,
            //   onClear: () => setState(() => selectedPurchaseLedger = null),
            //   onSelected: (selection) {
            //     FocusScope.of(context).unfocus();
            //     setState(() => selectedPurchaseLedger = selection);
            //   },
            //   optionBuilder: (o) => Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            //     child: Text(o["ledger_name"]?.toString() ?? "", style: const TextStyle(fontWeight: FontWeight.w500)),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: const Icon(Icons.local_shipping_outlined, size: 18),
        title: const Text("Is Consignee", style: TextStyle(fontSize: 14)),
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
    );
  }

  Widget _buildItemsSection() {
    return Column(
      children: List.generate(purchaseItems.length, (index) {
        final item = purchaseItems[index];

        return Card(
          key: ValueKey(item.uid),
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
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        "Item ${index + 1}",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                      ),
                    ),
                    const Spacer(),
                    if (purchaseItems.length > 1)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => removeItemRow(index),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                  filter: (o, query) => (o["item_name"] ?? "").toString().toLowerCase().contains(query),
                  initialValue: TextEditingValue(text: item.itemName),
                  showClear: item.stockItemId != null,
                  onClear: () => clearItemSelection(item),
                  onSelected: (selection) async {
  FocusScope.of(context).unfocus();
  debugPrint("SearchableField onSelected fired: $selection");
  final id = selection["id"];
  debugPrint("id=$id runtimeType=${id.runtimeType}");
  if (id is int) {
    await onItemSelected(id, item);
  } else {
    debugPrint("id was NOT an int, skipping onItemSelected");
  }
},
                  optionBuilder: (o) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(o["item_name"]?.toString() ?? ""),
                  ),
                ),
                const SizedBox(height: 12),
                if (item.stockItemId != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _smallChip("Unit", item.unitName),
                      if (item.igstPercent > 0)
                        _smallChip(
                          "IGST",
                          "${item.igstPercent.toStringAsFixed(1)}% (₹${_itemIgstAmount(item).toStringAsFixed(2)})",
                        )
                      else ...[
                        _smallChip(
                          "CGST",
                          "${item.cgstPercent.toStringAsFixed(1)}% (₹${_itemCgstAmount(item).toStringAsFixed(2)})",
                        ),
                        _smallChip(
                          "SGST",
                          "${item.sgstPercent.toStringAsFixed(1)}% (₹${_itemSgstAmount(item).toStringAsFixed(2)})",
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey("qty_${item.uid}"),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Billed Qty",
                          labelStyle: const TextStyle(fontSize: 13),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (value) => onQtyChanged(item, value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey("rate_${item.uid}"),
                        controller: _rateControllerFor(item),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Rate",
                          labelStyle: const TextStyle(fontSize: 13),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (value) => onRateChanged(item, value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Amount", style: TextStyle(fontWeight: FontWeight.w500)),
                      Text("₹${item.totalAmount.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildInvoiceAndNarrationSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // TextFormField(
            //   controller: supplierInvoiceController,
            //   decoration: InputDecoration(
            //     labelText: "Supplier Invoice No.",
            //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            //   ),
            // ),
            // const SizedBox(height: 10),
            TextFormField(
              controller: narrationController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Narration",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
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
            const Text("Bill Image", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 10),
            if (orderBillImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(orderBillImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
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
                child: const Center(child: Icon(Icons.image_outlined, size: 36, color: Colors.grey)),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: showImageSourceSheet,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(orderBillImage == null ? "Upload Bill Image" : "Change Image"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    // Subtotal, then the applicable tax line(s) (IGST alone, or CGST + SGST),
    // then a divider and the bold Grand Total.
    final taxRows = <Widget>[
      if (hasIgst)
        _summaryRow("IGST", getIgstTotal())
      else ...[
        _summaryRow("CGST", getCgstTotal()),
        const SizedBox(height: 8),
        _summaryRow("SGST", getSgstTotal()),
      ],
    ];

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _summaryRow("Subtotal", getSubTotal()),
            const SizedBox(height: 8),
            ...taxRows,
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _summaryRow("Grand Total", getGrandTotal(), isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    final style = TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 17 : 14);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text("₹${value.toStringAsFixed(2)}", style: style)],
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