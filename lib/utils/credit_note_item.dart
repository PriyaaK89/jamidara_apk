class CreditNoteItem {
  static int _counter = 0;
  final String uid = (_counter++).toString();

  int? stockItemId;
  String itemName = "";
  int? unitId;
  String unitName = "";
  int? altUnitId;
  double altUnitQty = 0;
  String altUnitName = "";

  int? godownId;
  String? godownName;
  String batchNo = "";

  double availableQty = 0;   // stock available in that godown/batch
  double returnQty = 0;
  double rate = 0;

  double cgstPercent = 0;
  double sgstPercent = 0;
  double igstPercent = 0;

  double amount = 0;
  double totalAmount = 0;

  // populated only in "From Sales" mode, for return-qty capping
  double soldQty = 0;
  double alreadyReturnedQty = 0;
  double availableToReturn = 0;

  // ── Serialize for the "items" multipart field ──────────────────────
  Map<String, dynamic> toJson() => {
        "stock_item_id": stockItemId,
        "godown_id": godownId,
        "batch_no": batchNo.isEmpty ? null : batchNo,
        "available_qty": availableQty,
        "return_qty": returnQty,
        "rate": rate,
        "unit_id": unitId,
        "alt_unit_id": altUnitId,
        "alt_unit_qty": altUnitQty,
        "amount": amount,
        "igst_percent": igstPercent,
        "igst_amount": (amount * igstPercent / 100),
        "cgst_percent": cgstPercent,
        "cgst_amount": (amount * cgstPercent / 100),
        "sgst_percent": sgstPercent,
        "sgst_amount": (amount * sgstPercent / 100),
        "total_amount": totalAmount,
      };
}